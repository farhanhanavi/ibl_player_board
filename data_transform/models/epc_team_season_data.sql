{{
    config(
            materialized = 'view',
            alias        = 'epc_team_season_level_data'
        )
}}

/*
  v_team_season_totals
  --------------------
  Spec   : specs/team_metrics_v3.yml -> queries.v_team_season_totals (v3.0)
  Source : epc_team_level_data (one row per team per match)
  Grain  : one row per team per season + one 'LEAGUE' row per season.
  Rule   : sum raw counts first, then derive. Never average per-match rates,
           so the per-match pct columns and biggest_lead are not carried here.
  Output : raw season totals + derived totals + possessions + all v2 metrics
           (v_team_season_metrics is merged into this view).
  Feeds  : v_team_season_metrics_ranked -> dashboard_team_card, v_team_season_shot_zones
*/

WITH params AS (

    SELECT 0.54::NUMERIC AS ft_poss_factor          -- parameters.ft_poss_factor

),

agg AS (

    SELECT
        game_season,
        COALESCE(team_abr, 'LEAGUE')                                        AS team_abr,
        CASE WHEN GROUPING(team_abr) = 1 THEN 'League Average'
             ELSE MAX(team_name) END                                        AS team_name,
        COUNT(*)                                                            AS games,
        SUM(CASE WHEN is_win THEN 1 ELSE 0 END)                             AS wins,
        SUM(CASE WHEN ot_score > 0 OR opp_ot_score > 0 THEN 1 ELSE 0 END)   AS ot_games,
        SUM(minutes_played)                                                 AS minutes_played,
        SUM(time_leading)                                                   AS time_leading,

        -- Team side
        SUM(total_points)                   AS total_points,
        SUM(total_score)                    AS total_score,
        SUM(q1_score)                       AS q1_score,
        SUM(q2_score)                       AS q2_score,
        SUM(q3_score)                       AS q3_score,
        SUM(q4_score)                       AS q4_score,
        SUM(ot_score)                       AS ot_score,
        SUM(total_points_bench)             AS total_points_bench,
        SUM(total_points_fastbreak)         AS total_points_fastbreak,
        SUM(total_points_second_chance)     AS total_points_second_chance,
        SUM(total_points_paint)             AS total_points_paint,
        SUM(total_points_from_tov)          AS total_points_from_tov,
        SUM(two_pa)                         AS two_pa,
        SUM(two_pm)                         AS two_pm,
        SUM(three_pa)                       AS three_pa,
        SUM(three_pm)                       AS three_pm,
        SUM(fga)                            AS fga,
        SUM(fgm)                            AS fgm,
        SUM(fta)                            AS fta,
        SUM(ftm)                            AS ftm,
        SUM(assists)                        AS assists,
        SUM(total_rebound)                  AS total_rebound,
        SUM(drb)                            AS drb,
        SUM(oreb)                           AS oreb,
        SUM(drb_team)                       AS drb_team,
        SUM(oreb_team)                      AS oreb_team,
        SUM(turnovers)                      AS turnovers,
        SUM(turnovers_team)                 AS turnovers_team,
        SUM(fouls_personal)                 AS fouls_personal,
        SUM(fouls_team)                     AS fouls_team,
        SUM(fouls_on)                       AS fouls_on,
        SUM(steals)                         AS steals,
        SUM(blocks)                         AS blocks,

        -- Opponent side
        SUM(opp_total_points)               AS opp_total_points,
        SUM(opp_total_score)                AS opp_total_score,
        SUM(opp_q1_score)                   AS opp_q1_score,
        SUM(opp_q2_score)                   AS opp_q2_score,
        SUM(opp_q3_score)                   AS opp_q3_score,
        SUM(opp_q4_score)                   AS opp_q4_score,
        SUM(opp_ot_score)                   AS opp_ot_score,
        SUM(opp_total_points_bench)         AS opp_total_points_bench,
        SUM(opp_total_points_fastbreak)     AS opp_total_points_fastbreak,
        SUM(opp_total_points_second_chance) AS opp_total_points_second_chance,
        SUM(opp_total_points_paint)         AS opp_total_points_paint,
        SUM(opp_total_points_from_tov)      AS opp_total_points_from_tov,
        SUM(opp_two_pa)                     AS opp_two_pa,
        SUM(opp_two_pm)                     AS opp_two_pm,
        SUM(opp_three_pa)                   AS opp_three_pa,
        SUM(opp_three_pm)                   AS opp_three_pm,
        SUM(opp_fga)                        AS opp_fga,
        SUM(opp_fgm)                        AS opp_fgm,
        SUM(opp_fta)                        AS opp_fta,
        SUM(opp_ftm)                        AS opp_ftm,
        SUM(opp_assist)                     AS opp_assist,
        SUM(opp_total_rebound)              AS opp_total_rebound,
        SUM(opp_drb)                        AS opp_drb,
        SUM(opp_oreb)                       AS opp_oreb,
        SUM(opp_drb_team)                   AS opp_drb_team,
        SUM(opp_oreb_team)                  AS opp_oreb_team,
        SUM(opp_turnovers)                  AS opp_turnovers,
        SUM(opp_turnovers_team)             AS opp_turnovers_team,
        SUM(opp_fouls_personal)             AS opp_fouls_personal,
        SUM(opp_fouls_team)                 AS opp_fouls_team,
        SUM(opp_fouls_on)                   AS opp_fouls_on,
        SUM(opp_steals)                     AS opp_steals,
        SUM(opp_blocks)                     AS opp_blocks

    FROM
        {{ ref('epc_team_level_data') }}
    GROUP BY
        GROUPING SETS ((game_season, team_abr), (game_season))

),

derived AS (

    SELECT
        a.*,
        p.ft_poss_factor,

        -- Totals = player + team
        a.oreb           + a.oreb_team          AS oreb_total,
        a.drb            + a.drb_team           AS drb_total,
        a.turnovers      + a.turnovers_team     AS turnovers_total,
        a.fouls_personal + a.fouls_team         AS fouls_total,

        a.opp_oreb           + a.opp_oreb_team          AS opp_oreb_total,
        a.opp_drb            + a.opp_drb_team           AS opp_drb_total,
        a.opp_turnovers      + a.opp_turnovers_team     AS opp_turnovers_total,
        a.opp_fouls_personal + a.opp_fouls_team         AS opp_fouls_total
    FROM
        agg a
    CROSS JOIN
        params p

),

poss AS (

    -- future_upgrade: replace these two estimates with counted possessions
    SELECT
        d.*,
        d.fga     - d.oreb_total     + d.turnovers_total     + d.ft_poss_factor * d.fta       AS poss,      -- basis: own
        d.opp_fga - d.opp_oreb_total + d.opp_turnovers_total + d.ft_poss_factor * d.opp_fta   AS opp_poss   -- basis: opponent
    FROM
        derived d

),

totals AS (

    SELECT
        p.*,
        (p.poss + p.opp_poss) / 2.0     AS poss_avg                                           -- basis: game_average (Pace only)
    FROM
        poss p

)

-- Metrics (spec: metrics section). Comment after each = possession_basis.
SELECT
    t.*,

    ROUND(t.poss     / NULLIF(t.games, 0), 1)                                            AS poss_per_game,                 -- own
    ROUND(t.opp_poss / NULLIF(t.games, 0), 1)                                            AS opp_poss_per_game,             -- opponent

    -- A. Overall strength
    ROUND(100.0 * t.wins                / NULLIF(t.games, 0), 1)                        AS win_pct,                       -- none
    ROUND(100.0 * t.total_points        / NULLIF(t.poss, 0), 1)                         AS ortg,                          -- own
    ROUND(100.0 * t.opp_total_points    / NULLIF(t.opp_poss, 0), 1)                     AS drtg,                          -- opponent
    ROUND(  100.0 * t.total_points      / NULLIF(t.poss, 0)
          - 100.0 * t.opp_total_points  / NULLIF(t.opp_poss, 0), 1)                     AS net_rtg,                       -- own_and_opponent
    ROUND(t.poss_avg * 40.0 / NULLIF(t.minutes_played, 0), 1)                           AS pace,                          -- game_average

    -- B. Offense: four factors
    ROUND(100.0 * (t.fgm + 0.5 * t.three_pm) / NULLIF(t.fga, 0), 1)                      AS efg_pct,                       -- none
    ROUND(100.0 * t.total_points / NULLIF(2 * (t.fga + t.ft_poss_factor * t.fta), 0), 1) AS ts_pct,                        -- none
    ROUND(100.0 * t.turnovers_total / NULLIF(t.poss, 0), 1)                              AS tov_per100,                    -- own
    ROUND(100.0 * t.oreb_total / NULLIF(t.oreb_total + t.opp_drb_total, 0), 1)           AS oreb_pct,                      -- none
    ROUND(100.0 * t.fta / NULLIF(t.poss, 0), 1)                                          AS fta_per100,                    -- own

    -- C. Defense: four factors
    ROUND(100.0 * (t.opp_fgm + 0.5 * t.opp_three_pm) / NULLIF(t.opp_fga, 0), 1)          AS opp_efg_pct,                   -- none
    ROUND(100.0 * t.opp_turnovers_total / NULLIF(t.opp_poss, 0), 1)                      AS opp_tov_per100,                -- opponent
    ROUND(100.0 * t.drb_total / NULLIF(t.drb_total + t.opp_oreb_total, 0), 1)            AS dreb_pct,                      -- none
    ROUND(100.0 * t.opp_fta / NULLIF(t.opp_poss, 0), 1)                                  AS opp_fta_per100,                -- opponent
    ROUND(100.0 * t.fouls_total / NULLIF(t.opp_poss, 0), 1)                              AS pf_per100,                     -- opponent

    -- D. Playing style
    ROUND(100.0 * t.three_pa / NULLIF(t.poss, 0), 1)                                     AS fg3a_per100,                   -- own
    ROUND(100.0 * t.three_pm / NULLIF(t.three_pa, 0), 1)                                 AS fg3_pct,                       -- none
    ROUND(100.0 * t.total_points_paint / NULLIF(t.poss, 0), 1)                           AS paint_pts_per100,              -- own
    ROUND(100.0 * t.total_points_fastbreak / NULLIF(t.poss, 0), 1)                       AS fastbreak_pts_per100,          -- own
    ROUND(100.0 * t.assists / NULLIF(t.poss, 0), 1)                                      AS ast_per100,                    -- own

    -- E. Effort & conversion
    ROUND(100.0 * t.total_points_second_chance / NULLIF(t.poss, 0), 1)                   AS second_chance_pts_per100,      -- own
    ROUND(100.0 * t.opp_total_points_second_chance / NULLIF(t.opp_poss, 0), 1)           AS opp_second_chance_pts_per100,  -- opponent
    ROUND(100.0 * t.total_points_from_tov / NULLIF(t.poss, 0), 1)                        AS pts_off_tov_per100,            -- own
    ROUND(100.0 * t.steals / NULLIF(t.opp_poss, 0), 1)                                   AS stl_per100,                    -- opponent
    ROUND(100.0 * t.blocks / NULLIF(t.opp_poss, 0), 1)                                   AS blk_per100,                    -- opponent

    -- F. Rotation & game control
    ROUND(100.0 * t.total_points_bench / NULLIF(t.poss, 0), 1)                           AS bench_pts_per100,              -- own
    ROUND((t.q1_score - t.opp_q1_score)::NUMERIC / NULLIF(t.games, 0), 1)                AS q1_margin,                     -- none
    ROUND((t.q2_score - t.opp_q2_score)::NUMERIC / NULLIF(t.games, 0), 1)                AS q2_margin,                     -- none
    ROUND((t.q3_score - t.opp_q3_score)::NUMERIC / NULLIF(t.games, 0), 1)                AS q3_margin,                     -- none
    ROUND((t.q4_score - t.opp_q4_score)::NUMERIC / NULLIF(t.games, 0), 1)                AS q4_margin,                     -- none
    ROUND((t.ot_score - t.opp_ot_score)::NUMERIC / NULLIF(t.ot_games, 0), 1)             AS ot_margin,                     -- none
    ROUND(100.0 * t.time_leading / NULLIF(t.minutes_played, 0), 1)                       AS time_leading_pct               -- none

FROM
    totals t