-- PostgreSQL 13+. Source is your existing public.pbp_data table/view.
-- Output is an *event-segment approximation*, NOT verified possessions.
-- A shot-clock/period turnover, technical FT, free-throw rebound, jump-ball or
-- corrected play-by-play can make a segment differ from an actual possession.
-- In particular, do not report percentages as true possession rates until reviewed.


WITH base AS (
    
  SELECT
    match_id::TEXT                  AS match_id,
    match_date::DATE                AS match_date,
    home_name                       AS home_team,
    away_name                       AS away_team,
    team_name,
    period::INT                     AS period,
    action_number::BIGINT           AS action_number,
    game_time,
    LOWER(COALESCE(action_type,'')) AS action_type,
    LOWER(COALESCE(sub_type,''))    AS sub_type,
    COALESCE(success,0)::INT        AS success
  FROM
    public.pbp_data
  WHERE
    team_name IN (home_name,away_name)

),
ordered AS (

  SELECT
    b.*,
    ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY period, action_number, team_name, action_type) AS seq,
    CASE
      WHEN action_type = 'turnover' THEN 1
      WHEN action_type IN ('2pt','3pt') AND success = 1 THEN 1
      WHEN action_type = 'rebound' AND sub_type IN ('defensive','def') THEN 1
      ELSE 0
    END AS terminal_marker
  FROM 
    base b
    
),
segmented AS (

  SELECT
    o.*,
    1 + COALESCE(SUM(terminal_marker) OVER (PARTITION BY match_id,period ORDER BY seq ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) AS segment_no
  FROM ordered o
),
scoring AS (

  SELECT
    s.*,
    -- Technical FT cannot always be identified from the provided columns.
    -- Label ambiguous 1of1 attempts so they can be audited, not silently removed.
    (action_type='freethrow' AND sub_type='1of1') AS possible_technical_ft
  FROM
    segmented s
), 
grouped AS (

  SELECT
    match_id, 
    MIN(match_date)                                                                         AS match_date,
    MIN(home_team)                                                                          AS home_team,
    MIN(away_team)                                                                          AS away_team,
    team_name,
    period,
    segment_no,
    MIN(action_number)                                                                      AS first_action_number,
    MAX(action_number)                                                                      AS last_action_number,
    COUNT(*) FILTER(WHERE action_type='2pt')::INT                                           AS two_pa,
    COUNT(*) FILTER(WHERE action_type='2pt' AND success=1)::INT                             AS two_pm,
    COUNT(*) FILTER(WHERE action_type='3pt')::INT                                           AS three_pa,
    COUNT(*) FILTER(WHERE action_type='3pt' AND success=1)::INT                             AS three_pm,
    COUNT(*) FILTER(WHERE action_type='freethrow')::INT                                     AS fta,
    COUNT(*) FILTER(WHERE action_type='freethrow' AND success=1)::INT                       AS ftm,
    COUNT(*) FILTER(WHERE possible_technical_ft)::INT                                       AS ft_1of1_attempts_to_review,
    COUNT(*) FILTER(WHERE action_type='turnover')::INT                                      AS pbp_turnovers,
    COUNT(*) FILTER(WHERE action_type='rebound' AND sub_type IN ('offensive','off'))::INT   AS offensive_rebounds,
    bool_or(action_type='turnover')                                                         AS contains_turnover,
    bool_or(action_type IN ('2pt','3pt') AND success=1)                                     AS contains_made_fg
  FROM 
    scoring
  GROUP BY 
    match_id,team_name,period,segment_no

), 
rows AS (

  SELECT
    g.*,
    ROW_NUMBER() OVER (PARTITION BY match_id,team_nameORDER BY period,segment_no)   AS poss_no,
    (2*two_pm+3*three_pm+ftm)::INT                                                  AS points_in_segment,
    CASE
      WHEN contains_turnover THEN 'TURNOVER_RECORDED'
      WHEN contains_made_fg THEN 'MADE_FG_RECORDED'
      ELSE 'OTHER_OR_UNRESOLVED'
    END AS ending_type,
    concat_ws(' + ',
      CASE WHEN two_pm>0 THEN two_pm::TEXT||'x2FG' END,
      CASE WHEN three_pm>0 THEN three_pm::TEXT||'x3FG' END,
      CASE WHEN ftm>0 THEN ftm::TEXT||'xFT' END
    ) AS raw_points_combination
  FROM
    grouped g
  WHERE
    two_pa+three_pa+fta+pbp_turnovers+offensive_rebounds>0
)
SELECT
  match_id,match_date,home_team,away_team,team_name,poss_no,period,
  first_action_number,last_action_number,
  two_pa,two_pm,three_pa,three_pm,fta,ftm,
  offensive_rebounds,pbp_turnovers,
  contains_turnover AS have_to,
  (ending_type='TURNOVER_RECORDED') AS ended_in_turnover_candidate,
  ending_type,
  points_in_segment,
  CASE WHEN points_in_segment=0 THEN '0_PTS' ELSE raw_points_combination END AS source_combination,
  ft_1of1_attempts_to_review,
  NULL::INTeger AS technical_ft_points, -- cannot reliably infer from this view
  NULL::INTeger AS team_turnover,       -- only available in JSONB box score
  'PROVISIONAL_EVENT_SEGMENT'::TEXT AS boundary_status
FROM rows;



/*
CREATE INDEX IF NOT EXISTS idx_pbp_possession_match_team
  ON public.pbp_possession_combinations(match_id,team_name,poss_no);


-- Independently validate the PBP event totals before evaluating any segmentation.
-- These sums DO NOT depend on the possession parser.
DROP VIEW IF EXISTS public.pbp_raw_points_turnover_totals;
CREATE VIEW public.pbp_raw_points_turnover_totals AS
SELECT match_id::TEXT AS match_id,team_name,
  SUM(CASE WHEN action_type='2pt' AND success=1 THEN 2
           WHEN action_type='3pt' AND success=1 THEN 3
           WHEN action_type='freethrow' AND success=1 THEN 1
           ELSE 0 END)::INT AS pbp_points,
  COUNT(*) FILTER(WHERE action_type='turnover')::INT AS pbp_turnovers
FROM public.pbp_data
GROUP BY match_id,team_name;

-- Audit event-segment conservation; mismatches show that scoring events were lost
-- from the segments (or attached to the wrong team).
SELECT r.match_id,r.team_name,r.pbp_points,
       COALESCE(SUM(p.points_in_segment),0)::INT AS segmented_points,
       r.pbp_turnovers,
       COALESCE(SUM(p.pbp_turnovers),0)::INT AS segmented_turnovers,
       r.pbp_points=COALESCE(SUM(p.points_in_segment),0) AS points_preserved,
       r.pbp_turnovers=COALESCE(SUM(p.pbp_turnovers),0) AS turnovers_preserved
FROM public.pbp_raw_points_turnover_totals r
LEFT JOIN public.pbp_possession_combinations p
  ON r.match_id=p.match_id AND r.team_name=p.team_name
GROUP BY r.match_id,r.team_name,r.pbp_points,r.pbp_turnovers
ORDER BY r.match_id,r.team_name;

-- To validate against the official box score, JOIN the original raw_matchdata
-- on match_id and read data->'tm'->'1'/'2' for tot_sPoints,
-- tot_sTurnovers, and tot_sTurnoversTeam. Team-turnover records are NOT
-- independently present in pbp_data's columns.

-- Official score + total turnover reconciliation for BOTH teams in every match.
-- Data availability: if raw_matchdata contains multiple rows per match/season,
-- DISTINCT ON keeps one JSON document per match.
DROP VIEW IF EXISTS public.pbp_official_points_turnover_validation;
CREATE VIEW public.pbp_official_points_turnover_validation AS
WITH docs AS (
  SELECT DISTINCT ON (data->>'match_id') data
  FROM public.raw_matchdata
  WHERE game_season='ibl_gopay_2026'
    AND (data->>'match_date')::DATE < DATE '2026-05-23'
  ORDER BY data->>'match_id'
), official AS (
  SELECT d.data->>'match_id' AS match_id,
    t.value->>'name' AS team_name,
    (t.value->>'tot_sPoints')::INT AS official_points,
    (t.value->>'tot_sTurnovers')::INT AS official_player_turnovers,
    COALESCE((t.value->>'tot_sTurnoversTeam')::INT,0) AS official_team_turnovers
  FROM docs d
  CROSS JOIN LATERAL jsonb_each(d.data->'tm') AS t(key,value)
)
SELECT o.*,
  COALESCE(r.pbp_points,0) AS pbp_points,
  COALESCE(r.pbp_turnovers,0) AS pbp_player_turnovers,
  COALESCE(r.pbp_turnovers,0)+o.official_team_turnovers AS accounted_total_turnovers,
  o.official_player_turnovers+o.official_team_turnovers AS official_total_turnovers,
  o.official_points=COALESCE(r.pbp_points,0) AS points_match,
  o.official_player_turnovers=COALESCE(r.pbp_turnovers,0) AS player_turnovers_match,
  -- This identity uses box-score team turnovers; it is NOT independent validation.
  o.official_player_turnovers+o.official_team_turnovers
    = COALESCE(r.pbp_turnovers,0)+o.official_team_turnovers AS total_turnovers_match
FROM official o
LEFT JOIN public.pbp_raw_points_turnover_totals r
  ON r.match_id=o.match_id AND r.team_name=o.team_name;

-- Select only DUB games, while including the offensive totals for BOTH teams.
SELECT v.*
FROM public.pbp_official_points_turnover_validation v
WHERE EXISTS (
  SELECT 1 FROM public.pbp_official_points_turnover_validation d
  WHERE d.match_id=v.match_id AND d.team_name='Dewa United Banten'
)
ORDER BY v.match_id,v.team_name;
