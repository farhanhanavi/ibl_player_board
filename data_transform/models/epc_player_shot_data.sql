{{
    config(
            materialized = 'table',
            alias        = 'epc_shot_level_data'
        )
}}

WITH base AS (

    SELECT
		r.match_id,
		r.game_season,
		(r.data ->> 'match_date')::DATE		AS match_date,
		r.data ->> 'venue'                    	AS venue,
		r.data -> 'tm' -> '1' ->> 'name'      AS home_team,
		r.data -> 'tm' -> '2' ->> 'name'      AS away_team,
		r.data              AS j
	FROM
		-- {{ source('source_raw_matchdata', 'raw_matchdata') }} r
		public.raw_matchdata r
	WHERE
		r.game_season = 'elite_pro_championship_2026'

),
sides AS (

    SELECT
        base.match_id,
        base.game_season,
		base.match_date,
		base.venue,
		base.home_team,
		base.away_team,
        t.key               AS team_no,
        t.value             AS tm
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)

),

shots AS (

    SELECT
        s.match_id,
        s.game_season,
		s.match_date,
		s.venue,
		s.home_team,
		s.away_team,
		s.tm ->> 'name'                         AS team_name,
        s.tm ->> 'code'                         AS team_abr,
		(sh ->> 'pno')::INT                     AS pno,
		pp.player_id,
		pp.player_name,
        --sh ->> 'player'                         AS player_name,
        (sh ->> 'actionNumber')::INT            AS action_number,
        (sh ->> 'per')::INT                     AS period,
        sh ->> 'perType'                        AS period_type,
        
        sh ->> 'actionType'                     AS shot_type,
        sh ->> 'subType'                        AS shot_subtype,
        (sh ->> 'x')::NUMERIC                   AS x,
        (sh ->> 'y')::NUMERIC                   AS y,
        ((sh ->> 'r')::INT = 1)                 AS is_made
    FROM
        sides s
    CROSS JOIN
        LATERAL jsonb_array_elements(COALESCE(s.tm -> 'shot', '[]'::JSONB)) AS sh
	LEFT JOIN
		dbt_schema.epc_player_profile pp
		ON LOWER(pp.player_name) = LOWER(sh ->> 'player')

),
halfcourt AS (

    SELECT
        s.*,
        ROUND(CASE WHEN s.x < 50 THEN s.x * 0.28 ELSE (100 - s.x) * 0.28 END, 3)       AS court_x_m,
        ROUND(CASE WHEN s.x < 50 THEN s.y * 0.15 ELSE (100 - s.y) * 0.15 END, 3)       AS court_y_m
    FROM
        shots s

),
geo AS (

    SELECT
        h.*,
        ROUND(SQRT(POWER(h.court_x_m - 1.575, 2) + POWER(h.court_y_m - 7.5, 2)), 3)    AS shot_distance_m,
        ROUND(ABS(h.court_y_m - 7.5), 3)                                               AS lateral_m
    FROM
        halfcourt h

)
SELECT
    g.*,
    CASE
        WHEN g.shot_type = '3pt' AND g.court_x_m <= 2.99               THEN 'Corner 3'
        WHEN g.shot_type = '3pt'                                       THEN 'ATB'
        WHEN g.shot_distance_m <= 1.25                                 THEN 'Restricted Area'
        WHEN g.court_x_m <= 5.8 AND g.lateral_m <= 2.45                THEN 'Paint Area'
        WHEN g.shot_distance_m <= 4.5                                  THEN 'Short Midrange'
        ELSE                                                                'Long Midrange'
    END	AS shot_zone
FROM
    geo g
ORDER BY
    g.match_id, g.action_number