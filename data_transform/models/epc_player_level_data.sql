{{
    config(
            materialized = 'table',
            alias        = 'epc_player_level_data'
        )
}}

/*
  epc_player_level_data   (player fact table)
  ---------------------
  Layer  : staging (fact)
  Spec   : specs/epc_metrics_spec.yml -> staging_columns.epc_player_level_data, identity.player
  Source : raw_matchdata -> data -> 'tm' -> '<n>' -> 'pl' -> '<pno>'
  Grain  : one row per player entry per match.
           DNP rows are kept (did_play = FALSE). Duplicate entries of the same player in one match
           are kept too (is_primary = FALSE), so a shot recorded on their pno still finds the player.
  Keys   : team_id     <- epc_team_profile (join on LOWER(TRIM(team_name)))
           player_id   =  MD5(team_id | shirt_number), the same key as epc_player_mapping.
                          No name matching: the feed spells names differently between matches.
  Names  : player_name      = canonical name from epc_player_profile (same in every match)
           feed_player_name = the spelling used in this match
  Dedup  : is_primary = one entry per player per match: most minutes, then most fields filled,
           then lowest pno. Season models use only did_play AND is_primary rows.
  pno    : player number inside one match only; links pl, shot[] and pbp within that match.
  Feeds  : epc_player_season_level_data, epc_player_shot_data
*/

WITH base AS (

    SELECT
        r.match_id,
        r.game_season,
        (r.data ->> 'match_date')::DATE         AS match_date,
        (r.data ->> 'venue')                    AS venue,
        (r.data -> 'tm' -> '1' ->> 'name')      AS home_team,
        (r.data -> 'tm' -> '2' ->> 'name')      AS away_team,
        r.data                                  AS j
    FROM
        {{ source('source_raw_matchdata', 'raw_matchdata') }} r
		-- public.raw_matchdata r
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
        t.value ->> 'name'                      AS team_name,       -- raw feed name, same as epc_team_level_data / epc_player_shot_data (join key)
        t.key                                   AS team_no,         -- '1' = home, '2' = away
        t.value -> 'pl'                         AS pl
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
        s.team_name,
        CASE WHEN s.team_no = '1' THEN s.away_team ELSE s.home_team END     AS opp_team_name,
        p.key::INT                                                          AS pno,
        TRIM(p.value ->> 'name')                                            AS player_name,
        NULLIF(TRIM(p.value ->> 'shirtNumber'), '')                         AS shirt_number,
        (SELECT COUNT(*) FROM jsonb_object_keys(p.value))                   AS n_fields,      -- complete entry ~51
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
    MD5(tp.team_id || '|' || p.shirt_number)        AS player_id,
    tp.team_id,
    p.match_id,
    p.game_season,
    p.match_date,
    p.venue,
    p.home_team,
    p.away_team,
    p.team_name,
    p.opp_team_name,
    p.pno,
    p.shirt_number,
    COALESCE(pp.player_name, p.player_name)         AS player_name,        -- one display name per player
    p.player_name                                   AS feed_player_name,   -- spelling in this match
    ROW_NUMBER() OVER (
        PARTITION BY p.match_id, tp.team_id, p.shirt_number
        ORDER BY p.minutes_played DESC, p.n_fields DESC, p.pno
    ) = 1                                           AS is_primary,
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
LEFT JOIN
    {{ ref('epc_team_profile') }} tp
	-- dbt_schema.epc_team_profile tp
    ON LOWER(tp.team_name) = LOWER(TRIM(p.team_name))
LEFT JOIN
    {{ ref('epc_player_profile') }} pp
	-- dbt_schema.epc_player_profile pp
    ON pp.player_id = MD5(tp.team_id || '|' || p.shirt_number)
ORDER BY
    p.match_id,
    p.team_name,
    p.pno