{{ 
    config(
            materialized = 'table',
            alias        = 'epc_team_level_data'
        ) 
}}


WITH base AS (

    SELECT
        r.match_id,
        r.game_season,
        r.data              AS j
    FROM
        {{ source('source_raw_matchdata', 'raw_matchdata') }} r
        -- public.raw_matchdata
    WHERE
        r.game_season = 'elite_pro_championship_2026'

),

-- One row per team side ('1' / '2')
sides AS (

    SELECT
        base.match_id,
        (base.j ->> 'match_date')::DATE     AS match_date,
        base.game_season,
        --base.game_type,
        (base.j ->> 'venue')::TEXT          AS venue,
        (base.j -> 'tm' -> '1' ->> 'name')  AS home_team,
        (base.j -> 'tm' -> '2' ->> 'name')  AS away_team,
        t.key                               AS team_no,
        t.value                             AS tm
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)

),
team_side AS (

    SELECT
        match_id,
        match_date,
        game_season,
        --game_type,
        venue,
        home_team,
        away_team,
        tm ->> 'name'                                   AS team_name,
        tm ->> 'code'                                   AS team_abr,
        team_no,


        tm ->> 'tot_sMinutes'                           AS minutes,
        -- 'mmm:ss' summed over all players (e.g. '224:60') / 5 players
        --  -> 40 regulation, 45 one OT, 50 two OT ...
        ROUND(
            (  SPLIT_PART(tm ->> 'tot_sMinutes', ':', 1)::NUMERIC
             + SPLIT_PART(tm ->> 'tot_sMinutes', ':', 2)::NUMERIC / 60.0
            ) / 5.0
        , 2)                                           AS minutes_played,

        COALESCE(NULLIF(tm ->> 'tot_sPoints', '')::INT, 0)                      AS total_points,
        COALESCE(NULLIF(tm ->> 'full_score', '')::INT, 0)                       AS total_score,
        COALESCE(NULLIF(tm ->> 'p1_score', '')::INT, 0)                         AS q1_score,
        COALESCE(NULLIF(tm ->> 'p2_score', '')::INT, 0)                         AS q2_score,
        COALESCE(NULLIF(tm ->> 'p3_score', '')::INT, 0)                         AS q3_score,
        COALESCE(NULLIF(tm ->> 'p4_score', '')::INT, 0)                         AS q4_score,
        COALESCE(NULLIF(tm ->> 'ot_score', '')::INT, 0)                         AS ot_score,
        COALESCE(NULLIF(tm ->> 'tot_sBenchPoints', '')::INT, 0)                 AS total_points_bench,
        COALESCE(NULLIF(tm ->> 'tot_sPointsFastBreak', '')::INT, 0)             AS total_points_fastbreak,
        COALESCE(NULLIF(tm ->> 'tot_sPointsSecondChance', '')::INT, 0)          AS total_points_second_chance,
        COALESCE(NULLIF(tm ->> 'tot_sPointsInThePaint', '')::INT, 0)            AS total_points_paint,
        COALESCE(NULLIF(tm ->> 'tot_sPointsFromTurnovers', '')::INT, 0)         AS total_points_from_tov,

        COALESCE(NULLIF(tm ->> 'tot_sTwoPointersAttempted', '')::INT, 0)        AS two_pa,
        COALESCE(NULLIF(tm ->> 'tot_sTwoPointersMade', '')::INT, 0)             AS two_pm,
        COALESCE(NULLIF(tm ->> 'tot_sTwoPointersPercentage', '')::NUMERIC, 0)   AS two_pct,

        COALESCE(NULLIF(tm ->> 'tot_sThreePointersAttempted', '')::INT, 0)      AS three_pa,
        COALESCE(NULLIF(tm ->> 'tot_sThreePointersMade', '')::INT, 0)           AS three_pm,
        COALESCE(NULLIF(tm ->> 'tot_sThreePointersPercentage', '')::NUMERIC, 0) AS three_pct,

        COALESCE(NULLIF(tm ->> 'tot_sFieldGoalsAttempted', '')::INT, 0)         AS fga,
        COALESCE(NULLIF(tm ->> 'tot_sFieldGoalsMade', '')::INT, 0)              AS fgm,
        COALESCE(NULLIF(tm ->> 'tot_sFieldGoalsPercentage', '')::NUMERIC, 0)    AS fg_pct,

        COALESCE(NULLIF(tm ->> 'tot_sFreeThrowsAttempted', '')::INT, 0)         AS fta,
        COALESCE(NULLIF(tm ->> 'tot_sFreeThrowsMade', '')::INT, 0)              AS ftm,
        COALESCE(NULLIF(tm ->> 'tot_sFreeThrowsPercentage', '')::NUMERIC, 0)    AS ft_pct,

        COALESCE(NULLIF(tm ->> 'tot_sAssists', '')::INT, 0)                     AS assists,

        COALESCE(NULLIF(tm ->> 'tot_sReboundsTotal', '')::INT, 0)               AS total_rebound,
        COALESCE(NULLIF(tm ->> 'tot_sReboundsDefensive', '')::INT, 0)           AS drb,
        COALESCE(NULLIF(tm ->> 'tot_sReboundsOffensive', '')::INT, 0)           AS oreb,
        COALESCE(NULLIF(tm ->> 'tot_sReboundsTeamDefensive', '')::INT, 0)       AS drb_team,
        COALESCE(NULLIF(tm ->> 'tot_sReboundsTeamOffensive', '')::INT, 0)       AS oreb_team,

        COALESCE(NULLIF(tm ->> 'tot_sTurnovers', '')::INT, 0)                   AS turnovers,
        COALESCE(NULLIF(tm ->> 'tot_sTurnoversTeam', '')::INT, 0)               AS turnovers_team,
        COALESCE(NULLIF(tm ->> 'tot_sFoulsPersonal', '')::INT, 0)               AS fouls_personal,
        COALESCE(NULLIF(tm ->> 'tot_sFoulsTeam', '')::INT, 0)                   AS fouls_team,
        COALESCE(NULLIF(tm ->> 'tot_sFoulsOn', '')::INT, 0)                     AS fouls_on,
        COALESCE(NULLIF(tm ->> 'tot_sSteals', '')::INT, 0)                      AS steals,
        COALESCE(NULLIF(tm ->> 'tot_sBlocks', '')::INT, 0)                      AS blocks,

        COALESCE(NULLIF(tm ->> 'tot_sBiggestLead', '')::INT, 0)                 AS biggest_lead,
        COALESCE(NULLIF(tm ->> 'tot_sTimeLeading', '')::NUMERIC, 0)             AS time_leading
    FROM
        sides

)

SELECT
    a.match_id,
    a.match_date,
    a.game_season,
    --a.game_type,
    a.venue,
    a.home_team,
    a.away_team,
    a.team_name,
    a.team_abr,
    (a.total_score > b.total_score)            AS is_win,

    -- Team side
    a.minutes, a.minutes_played,
    a.total_points, a.total_score, a.q1_score, a.q2_score, a.q3_score, a.q4_score, a.ot_score,
    a.total_points_bench, a.total_points_fastbreak, a.total_points_second_chance, a.total_points_paint, a.total_points_from_tov,
    a.two_pa, a.two_pm, a.two_pct, a.three_pa, a.three_pm, a.three_pct,
    a.fga, a.fgm, a.fg_pct,
    a.fta, a.ftm, a.ft_pct,
    a.assists, a.total_rebound, a.drb, a.oreb, a.drb_team, a.oreb_team,
    a.turnovers, a.turnovers_team, a.fouls_personal, a.fouls_team, a.fouls_on, a.steals, a.blocks, a.biggest_lead, a.time_leading,
    
    -- Opponent side
    b.total_points                  AS opp_total_points,
    b.total_score                   AS opp_total_score,
    b.q1_score                      AS opp_q1_score,
    b.q2_score                      AS opp_q2_score,
    b.q3_score                      AS opp_q3_score,
    b.q4_score                      AS opp_q4_score,
    b.ot_score                      AS opp_ot_score,
    b.total_points_bench            AS opp_total_points_bench,
    b.total_points_fastbreak        AS opp_total_points_fastbreak,
    b.total_points_second_chance    AS opp_total_points_second_chance,
    b.total_points_paint            AS opp_total_points_paint,
    b.total_points_from_tov         AS opp_total_points_from_tov,

    b.two_pa                        AS opp_two_pa,
    b.two_pm                        AS opp_two_pm,
    b.two_pct                       AS opp_two_pct,
    b.three_pa                      AS opp_three_pa,
    b.three_pm                      AS opp_three_pm,
    b.three_pct                     AS opp_three_pct,

    b.fga                           AS opp_fga,
    b.fgm                           AS opp_fgm,
    b.fg_pct                        AS opp_fg_pct,

    b.fta                           AS opp_fta,
    b.ftm                           AS opp_ftm,
    b.ft_pct                        AS opp_ft_pct,
    b.assists                       AS opp_assist,
    b.total_rebound                 AS opp_total_rebound,
    b.drb                           AS opp_drb,
    b.oreb                          AS opp_oreb,
    b.drb_team                      AS opp_drb_team,
    b.oreb_team                     AS opp_oreb_team,
    b.turnovers                     AS opp_turnovers,
    b.turnovers_team                AS opp_turnovers_team,
    b.fouls_personal                AS opp_fouls_personal,
    b.fouls_team                    AS opp_fouls_team,
    b.fouls_on                      AS opp_fouls_on,
    b.steals                        AS opp_steals,
    b.blocks                        AS opp_blocks,
    b.biggest_lead                  AS opp_biggest_lead,
    b.time_leading                  AS opp_time_leading
FROM
    team_side a
INNER JOIN 
    team_side b
    ON  b.match_id = a.match_id
    AND a.team_no <> b.team_no
WHERE
    a.team_no IN ('1','2')
    AND
    b.team_no IN ('1','2')
ORDER BY
    match_id