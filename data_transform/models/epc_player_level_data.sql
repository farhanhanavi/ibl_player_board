{{
    config(
            materialized = 'table',
            alias        = 'epc_player_level_data'
        )
}}


/*
  epc_player_level_data
  ---------------------
  Spec   : specs/player_metrics_v1.yml -> planned_models.epc_player_level_data
  Source : raw_matchdata -> data -> 'tm' -> '<n>' -> 'pl' -> '<pno>'
  Grain  : one row per player per match (DNP rows kept, did_play = false)
  Key    : player_key = same MD5 as epc_player_photos (team + first + family name),
           because pno is only unique inside one match.
*/

WITH base AS (

    SELECT
        r.match_id,
        r.game_season,
        (r.data ->> 'match_date')::DATE     AS match_date,
		(r.data ->> 'venue')	    	 	AS venue,
		(r.data -> 'tm' -> '1' ->> 'name')  AS home_team,
        (r.data -> 'tm' -> '2' ->> 'name')  AS away_team,
        r.data                              AS j
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
		t.value ->> 'name'                  AS team_name,
        t.value ->> 'code'                  AS team_abr,
        t.key                               AS team_no,
        t.value -> 'pl'                     AS pl
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)

),

players AS (

    SELECT
        s.match_id,
        s.game_season,
        s.match_date,
		s.venue,
		s.home_team,
		s.away_team,
		s.team_abr,
        s.team_name,
        s.team_no,        
        p.value ->> 'name'                                                  AS player_name,
        (COALESCE(NULLIF(p.value ->> 'starter', ''), '0')::INT = 1)         AS is_starter,

        p.value ->> 'sMinutes'                                              AS minutes,
        -- 'mm:ss' -> decimal minutes
        ROUND(
              COALESCE(NULLIF(SPLIT_PART(p.value ->> 'sMinutes', ':', 1), '')::NUMERIC, 0)
            + COALESCE(NULLIF(SPLIT_PART(p.value ->> 'sMinutes', ':', 2), '')::NUMERIC, 0) / 60.0
        , 2)                                                                AS minutes_played,

        COALESCE(NULLIF(p.value ->> 'sPoints', '')::INT, 0)                 AS points,
        COALESCE(NULLIF(p.value ->> 'sPointsInThePaint', '')::INT, 0)       AS points_paint,
        COALESCE(NULLIF(p.value ->> 'sPointsFastBreak', '')::INT, 0)        AS points_fastbreak,
        COALESCE(NULLIF(p.value ->> 'sPointsSecondChance', '')::INT, 0)     AS points_second_chance,

        COALESCE(NULLIF(p.value ->> 'sTwoPointersAttempted', '')::INT, 0)   AS two_pa,
        COALESCE(NULLIF(p.value ->> 'sTwoPointersMade', '')::INT, 0)        AS two_pm,
        COALESCE(NULLIF(p.value ->> 'sThreePointersAttempted', '')::INT, 0) AS three_pa,
        COALESCE(NULLIF(p.value ->> 'sThreePointersMade', '')::INT, 0)      AS three_pm,
        COALESCE(NULLIF(p.value ->> 'sFieldGoalsAttempted', '')::INT, 0)    AS fga,
        COALESCE(NULLIF(p.value ->> 'sFieldGoalsMade', '')::INT, 0)         AS fgm,
        COALESCE(NULLIF(p.value ->> 'sFreeThrowsAttempted', '')::INT, 0)    AS fta,
        COALESCE(NULLIF(p.value ->> 'sFreeThrowsMade', '')::INT, 0)         AS ftm,

        COALESCE(NULLIF(p.value ->> 'sReboundsOffensive', '')::INT, 0)      AS oreb,
        COALESCE(NULLIF(p.value ->> 'sReboundsDefensive', '')::INT, 0)      AS drb,
        COALESCE(NULLIF(p.value ->> 'sReboundsTotal', '')::INT, 0)          AS total_rebound,
        COALESCE(NULLIF(p.value ->> 'sAssists', '')::INT, 0)                AS assists,
        COALESCE(NULLIF(p.value ->> 'sTurnovers', '')::INT, 0)              AS turnovers,
        COALESCE(NULLIF(p.value ->> 'sSteals', '')::INT, 0)                 AS steals,
        COALESCE(NULLIF(p.value ->> 'sBlocks', '')::INT, 0)                 AS blocks,
        COALESCE(NULLIF(p.value ->> 'sBlocksReceived', '')::INT, 0)         AS blocks_received,
        COALESCE(NULLIF(p.value ->> 'sFoulsPersonal', '')::INT, 0)          AS fouls_personal,
        COALESCE(NULLIF(p.value ->> 'sFoulsOn', '')::INT, 0)                AS fouls_on,
        COALESCE(NULLIF(p.value ->> 'sPlusMinusPoints', '')::INT, 0)        AS plus_minus,

        -- Feed efficiency fields, kept for reconciliation only (season values are recomputed from sums)
        NULLIF(p.value ->> 'eff_1', '')::NUMERIC                            AS feed_eff,        -- = EFF
        NULLIF(p.value ->> 'eff_3', '')::NUMERIC                            AS feed_game_score, -- = Hollinger Game Score
        NULLIF(p.value ->> 'eff_5', '')::NUMERIC                            AS feed_pir         -- = FIBA PIR
    FROM
        sides s
    CROSS JOIN
        LATERAL jsonb_each(s.pl) AS p (key, value)

)

SELECT
    p.match_id,
	p.game_season,
    p.match_date,
	p.venue,
	p.home_team,
	p.away_team,
    p.team_name,
    p.player_name,
    p.is_starter,
    (p.minutes_played > 0)                          AS did_play,
    p.minutes,
    p.minutes_played,
    p.points, p.points_paint, p.points_fastbreak, p.points_second_chance,
    p.two_pa, p.two_pm, p.three_pa, p.three_pm, p.fga, p.fgm, p.fta, p.ftm,
    p.oreb, p.drb, p.total_rebound, p.assists, p.turnovers, p.steals, p.blocks,
    p.blocks_received, p.fouls_personal, p.fouls_on, p.plus_minus,
    p.feed_eff, p.feed_game_score, p.feed_pir
FROM
    players p
INNER JOIN
    sides o
    ON  o.match_id = p.match_id
    AND o.team_no <> p.team_no
ORDER BY
    p.match_id,
	p.team_name,
	player_name