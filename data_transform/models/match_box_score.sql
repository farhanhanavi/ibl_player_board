{{
    config(
        materialized='table'
    )
}}

/*
  Source expects a table with a single `jsonb` column named `raw_data`,
  each row holding one full match JSON (the structure from test.json).

  Example source definition in sources.yml:
    - name: raw
      tables:
        - name: match_data
          columns:
            - name: raw_data
              data_type: jsonb
*/

WITH raw_table AS (
    SELECT 
        data,
        game_season,
        match_id,
	data ->> 'match_date' AS match_date,
	data ->> 'venue' AS venue,
	data -> 'tm' -> '1' ->> 'name' AS home_team,
	data -> 'tm' -> '2' ->> 'name' AS away_team
    FROM 
        {{ source('source_raw_matchdata','raw_matchdata') }}
),

teams AS (
    SELECT
        rt.match_id,
        rt.game_season,
	rt.match_date,
	rt.venue,
	rt.home_team,
	rt.away_team,
        team.value ->> 'nameInternational'           AS team_name,
        team.value -> 'pl'                           AS players_json
    FROM 
        raw_table rt,
        jsonb_each(data -> 'tm') AS team
)
SELECT
    t.match_id,
    t.game_season,
    t.match_date,
    t.venue,
    t.home_team,
    t.away_team,
    t.team_name,

    -- Player identity
    p.value ->> 'name'                                    AS player_name,
    p.value ->> 'shirtNumber'                             AS shirt_number,
    p.value ->> 'playingPosition'                         AS position,
    COALESCE((p.value ->> 'starter')::INT, 0)             AS is_starter,
    COALESCE((p.value ->> 'captain')::INT, 0)             AS is_captain,

    -- Time ex = 8:11
    p.value ->> 'sMinutes'                                AS minutes,
    ROUND((split_part(p.value ->> 'sMinutes', ':', 1)::numeric * 60 + split_part(p.value ->> 'sMinutes', ':', 2)::numeric) / 60, 2) AS game_minutes,

    -- Scoring
    (p.value ->> 'sPoints')::INT                          AS total_points,
    (p.value ->> 'sPointsInThePaint')::INT                AS total_points_paint,
    (p.value ->> 'sPointsFastBreak')::INT                 AS total_points_fastbreak,
    (p.value ->> 'sPointsSecondChance')::INT              AS total_points_second_chance,

    -- Field goals
    (p.value ->> 'sFieldGoalsMade')::INT                          AS fgm,
    (p.value ->> 'sFieldGoalsAttempted')::INT                     AS fga,
    ROUND((p.value ->> 'sFieldGoalsPercentage')::NUMERIC,2)       AS fg_pct,

    -- 2-pointers
    (p.value ->> 'sTwoPointersMade')::INT                          AS two_pm,
    (p.value ->> 'sTwoPointersAttempted')::INT                     AS two_pa,
    ROUND((p.value ->> 'sTwoPointersPercentage')::NUMERIC,2)       AS two_p_pct,

    -- 3-pointers
    (p.value ->> 'sThreePointersMade')::INT                        AS three_pm,
    (p.value ->> 'sThreePointersAttempted')::INT                   AS three_pa,
    ROUND((p.value ->> 'sThreePointersPercentage')::NUMERIC,2)     AS three_p_pct,

    -- Free throws
    (p.value ->> 'sFreeThrowsMade')::INT                        AS ftm,
    (p.value ->> 'sFreeThrowsAttempted')::INT                   AS fta,
    ROUND((p.value ->> 'sFreeThrowsPercentage')::NUMERIC,2)     AS ft_pct,

    -- Rebounds
    (p.value ->> 'sReboundsTotal')::INT                   AS reb,
    (p.value ->> 'sReboundsOffensive')::INT               AS oreb,
    (p.value ->> 'sReboundsDefensive')::INT               AS dreb,

    -- Other stats
    (p.value ->> 'sAssists')::INT                         AS ast,
    (p.value ->> 'sSteals')::INT                          AS stl,
    (p.value ->> 'sBlocks')::INT                          AS blk,
    (p.value ->> 'sBlocksReceived')::INT                  AS blocks_received,
    (p.value ->> 'sTurnovers')::INT                       AS tov,
    (p.value ->> 'sFoulsPersonal')::INT                   AS pf,
    (p.value ->> 'sFoulsOn')::INT                         AS fouls_drawn,
    (p.value ->> 'sPlusMinusPoints')::INT                 AS plus_minus,
    (p.value ->> 'eff_1')::NUMERIC                        AS efficiency

FROM
    teams t,
    jsonb_each(t.players_json) AS p
ORDER BY
    team_name
