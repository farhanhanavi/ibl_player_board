{{
    config(
            materialized = 'table',
            alias        = 'epc_player_season_level_data'
        )
}}

/*
  v_player_season_totals
  ----------------------
  Spec   : specs/player_metrics_v1.yml -> planned_models.v_player_season_totals
  Source : epc_player_level_data (player x match) + epc_team_level_data (team x match)
           + epc_player_photos (player profile: names, position)
  Join   : player x team per match on match_id + team_name (no team_abr); team_id from the fact.
  Grain  : one row per player (player_id = team-specific) per season
           + one 'LEAGUE' row per season (qualified players only)
  Qualify: one global, fixed standard for every metric (parameters.qualification):
           games_played >= min_games AND minutes per game >= min_mpg.
  Rule   : per match, the player's share of the game (minutes / game minutes) is applied to the
           team's possessions and team counts ("on-court estimates"). Raw counts and on-court
           estimates are summed over the season first, then every formula is applied once.
*/

WITH params AS (

    SELECT
        0.54::NUMERIC   AS ft_poss_factor,      -- parameters.ft_poss_factor (same as team spec)
        3               AS min_games,           -- parameters.qualification.min_games (global, fixed)
        10.0::NUMERIC   AS min_mpg              -- parameters.qualification.min_minutes_per_game (global, fixed)

),
team_match AS (

    -- Team context per match
    SELECT
        t.match_id,
        t.team_name,
        t.is_win,
        t.minutes_played                                                         												AS game_minutes,
        t.fga - (t.oreb + t.oreb_team) + (t.turnovers + t.turnovers_team) + (p.ft_poss_factor * t.fta)							AS tm_poss,
        t.opp_fga - (t.opp_oreb + t.opp_oreb_team) + (t.opp_turnovers + t.opp_turnovers_team) + (p.ft_poss_factor * t.opp_fta)	AS tm_opp_poss,
        t.fga                                                                    AS tm_fga,
        t.fgm                                                                    AS tm_fgm,
        t.fta                                                                    AS tm_fta,
        t.turnovers                                                              AS tm_tov,            -- player-attributed only
        (t.oreb + t.oreb_team) + (t.opp_drb + t.opp_drb_team)                    AS tm_oreb_avail,
        (t.drb + t.drb_team) + (t.opp_oreb + t.opp_oreb_team)                    AS tm_dreb_avail,
        t.opp_two_pa                                                             AS tm_opp_two_pa
    FROM
        {{ ref('epc_team_level_data') }} t
		-- dbt_schema.epc_team_level_data t
    CROSS JOIN
        params p

),
team_games AS (

    SELECT
		game_season,
		team_name,
		COUNT(*) AS team_games
    FROM 
		{{ ref('epc_team_level_data') }}
		-- dbt_schema.epc_team_level_data
    GROUP BY
		game_season, team_name

),
player_match AS (

    SELECT
        pl.*,	
        tm.is_win,
        tm.game_minutes,
        pl.minutes_played / NULLIF(tm.game_minutes, 0)                           AS court_share,   -- 0..1
        tm.tm_poss        * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_poss,
        tm.tm_opp_poss    * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_opp_poss,
        tm.tm_fga         * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_tm_fga,
        tm.tm_fgm         * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_tm_fgm,
        tm.tm_fta         * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_tm_fta,
        tm.tm_tov         * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_tm_tov,
        tm.tm_oreb_avail  * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_oreb_avail,
        tm.tm_dreb_avail  * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_dreb_avail,
        tm.tm_opp_two_pa  * pl.minutes_played / NULLIF(tm.game_minutes, 0)       AS on_opp_two_pa
    FROM
        {{ ref('epc_player_level_data') }} pl
		-- dbt_schema.epc_player_level_data pl
    INNER JOIN
        team_match tm
        ON  tm.match_id = pl.match_id
        AND tm.team_name = pl.team_name
    WHERE
        pl.did_play = TRUE

),
qualification AS (

    SELECT
        pm.game_season,
        pm.player_id,
        (
			COUNT(*) >= MAX(p.min_games)
         	AND 
			SUM(pm.minutes_played) / COUNT(*) >= MAX(p.min_mpg)
		 ) AS is_qualified
    FROM
        player_match pm
    CROSS JOIN
        params p
    GROUP BY
        1,2

),
stacked AS (

    -- scope 'player' = every player; scope 'league' = qualified players only (for the league average)
    SELECT 
		'player' AS scope, 
		pm.*, 
		q.is_qualified
    FROM 
		player_match pm
    JOIN 
		qualification q 
		USING (game_season, player_id)

    UNION ALL

    SELECT 
		'league' AS scope, 
		pm.*, 
		q.is_qualified
    FROM 
		player_match pm
    JOIN 
		qualification q 
		USING (game_season, player_id)
    WHERE 
		q.is_qualified

),
agg AS (

    SELECT
        game_season,
        CASE WHEN GROUPING(player_id) = 0 THEN player_id ELSE 'LEAGUE' END         AS player_id,
        CASE WHEN GROUPING(player_id) = 0 THEN 'player'   ELSE 'league' END         AS row_type,
        CASE WHEN GROUPING(player_id) = 0 THEN team_id END                          AS team_id,
        CASE WHEN GROUPING(player_id) = 0 THEN MAX(team_name) END                   AS team_name,
        CASE WHEN GROUPING(player_id) = 0 THEN MAX(player_name) ELSE 'League Average' END AS player_name,
        BOOL_AND(is_qualified)                                                       AS is_qualified,

        COUNT(*)                                            AS games_played,   -- league rows: player-games
        SUM(CASE WHEN is_starter THEN 1 ELSE 0 END)         AS games_started,
        SUM(CASE WHEN is_win     THEN 1 ELSE 0 END)         AS wins_played,
        SUM(minutes_played)                                 AS minutes_played,
        SUM(game_minutes)                                   AS game_minutes,

        SUM(points)                 AS points,
        SUM(points_paint)           AS points_paint,
        SUM(points_fastbreak)       AS points_fastbreak,
        SUM(points_second_chance)   AS points_second_chance,
        SUM(two_pa)                 AS two_pa,
        SUM(two_pm)                 AS two_pm,
        SUM(three_pa)               AS three_pa,
        SUM(three_pm)               AS three_pm,
        SUM(fga)                    AS fga,
        SUM(fgm)                    AS fgm,
        SUM(fta)                    AS fta,
        SUM(ftm)                    AS ftm,
        SUM(oreb)                   AS oreb,
        SUM(drb)                    AS drb,
        SUM(total_rebound)          AS total_rebound,
        SUM(assists)                AS assists,
        SUM(turnovers)              AS turnovers,
        SUM(steals)                 AS steals,
        SUM(blocks)                 AS blocks,
        SUM(blocks_received)        AS blocks_received,
        SUM(fouls_personal)         AS fouls_personal,
        SUM(fouls_on)               AS fouls_on,
        SUM(plus_minus)             AS plus_minus,

        -- On-court estimates (team values x court_share, summed per match)
        SUM(on_poss)                AS player_poss,         -- basis: own
        SUM(on_opp_poss)            AS player_opp_poss,     -- basis: opponent
        SUM(on_tm_fga)              AS on_tm_fga,
        SUM(on_tm_fgm)              AS on_tm_fgm,
        SUM(on_tm_fta)              AS on_tm_fta,
        SUM(on_tm_tov)              AS on_tm_tov,
        SUM(on_oreb_avail)          AS on_oreb_avail,
        SUM(on_dreb_avail)          AS on_dreb_avail,
        SUM(on_opp_two_pa)          AS on_opp_two_pa
    FROM
        stacked
    GROUP BY
        GROUPING SETS (
            (game_season, scope, player_id, team_id),
            (game_season, scope)
        )
    HAVING
           (scope = 'player' AND GROUPING(player_id) = 0)
        OR (scope = 'league' AND GROUPING(player_id) = 1)

),
totals AS (

    SELECT
        a.*,
        tg.team_games,
        p.ft_poss_factor,
        (a.player_poss + a.player_opp_poss) / 2.0                                    AS player_poss_avg,   -- basis: game_average
	    a.points + a.total_rebound + a.assists + a.steals + a.blocks + a.fouls_on - (a.fga - a.fgm) - (a.fta - a.ftm) - a.turnovers - a.blocks_received - a.fouls_personal AS pir,
        a.points + 0.4 * a.fgm - 0.7 * a.fga - 0.4 * (a.fta - a.ftm) + 0.7 * a.oreb + 0.3 * a.drb + a.steals + 0.7 * a.assists + 0.7 * a.blocks - 0.4 * a.fouls_personal - a.turnovers AS game_score
    FROM
        agg a
    CROSS JOIN
        params p
    LEFT JOIN
        team_games tg
        ON  tg.game_season = a.game_season
        AND tg.team_name   = a.team_name

)

-- Metrics (spec: metrics section). Comment after each = possession_basis.
SELECT
    t.*,

    -- A. Role & availability
    ROUND(100.0 * t.games_played / NULLIF(t.team_games, 0), 1)                                   AS games_played_pct,      -- none
    ROUND(t.minutes_played / NULLIF(t.games_played, 0), 1)                                       AS mpg,                   -- none
    ROUND(100.0 * t.games_started / NULLIF(t.games_played, 0), 1)                                AS start_pct,             -- none
    ROUND(100.0 * t.minutes_played / NULLIF(t.game_minutes, 0), 1)                               AS minutes_pct,           -- none

    -- B. Scoring
    ROUND(t.points::NUMERIC / NULLIF(t.games_played, 0), 1)                                      AS pts_per_game,          -- none
    ROUND(100.0 * t.points / NULLIF(t.player_poss, 0), 1)                                        AS pts_per100,            -- own
    ROUND(100.0 * (t.fga + t.ft_poss_factor * t.fta + t.turnovers)
          / NULLIF(t.on_tm_fga + t.ft_poss_factor * t.on_tm_fta + t.on_tm_tov, 0), 1)            AS usg_pct,               -- none
    ROUND(100.0 * t.points / NULLIF(2 * (t.fga + t.ft_poss_factor * t.fta), 0), 1)               AS ts_pct,                -- none
    ROUND(100.0 * (t.fgm + 0.5 * t.three_pm) / NULLIF(t.fga, 0), 1)                              AS efg_pct,               -- none
    ROUND(100.0 * t.two_pm / NULLIF(t.two_pa, 0), 1)                                             AS fg2_pct,               -- none
    ROUND(100.0 * t.three_pm / NULLIF(t.three_pa, 0), 1)                                         AS fg3_pct,               -- none
    ROUND(100.0 * t.ftm / NULLIF(t.fta, 0), 1)                                                   AS ft_pct,                -- none
    ROUND(100.0 * t.three_pa / NULLIF(t.fga, 0), 1)                                              AS fg3a_rate,             -- none
    ROUND(100.0 * t.fta / NULLIF(t.fga, 0), 1)                                                   AS fta_rate,              -- none
    ROUND(100.0 * t.points_paint / NULLIF(t.player_poss, 0), 1)                                  AS paint_pts_per100,      -- own
    ROUND(100.0 * t.points_fastbreak / NULLIF(t.player_poss, 0), 1)                              AS fastbreak_pts_per100,  -- own
    ROUND(100.0 * t.points_second_chance / NULLIF(t.player_poss, 0), 1)                          AS second_chance_pts_per100, -- own

    -- C. Playmaking & ball security
    ROUND(100.0 * t.assists / NULLIF(t.player_poss, 0), 1)                                       AS ast_per100,            -- own
    ROUND(100.0 * t.assists / NULLIF(t.on_tm_fgm - t.fgm, 0), 1)                                 AS ast_pct,               -- none
    ROUND(100.0 * t.turnovers / NULLIF(t.fga + t.ft_poss_factor * t.fta + t.turnovers, 0), 1)    AS tov_pct,               -- none
    ROUND(t.assists::NUMERIC / NULLIF(t.turnovers, 0), 2)                                        AS ast_tov_ratio,         -- none

    -- D. Rebounding
    ROUND(100.0 * t.oreb / NULLIF(t.on_oreb_avail, 0), 1)                                        AS oreb_pct,              -- none
    ROUND(100.0 * t.drb  / NULLIF(t.on_dreb_avail, 0), 1)                                        AS dreb_pct,              -- none
    ROUND(100.0 * t.total_rebound / NULLIF(t.on_oreb_avail + t.on_dreb_avail, 0), 1)             AS treb_pct,              -- none

    -- E. Defense & activity
    ROUND(100.0 * t.steals / NULLIF(t.player_opp_poss, 0), 1)                                    AS stl_per100,            -- opponent
    ROUND(100.0 * t.blocks / NULLIF(t.player_opp_poss, 0), 1)                                    AS blk_per100,            -- opponent
    ROUND(100.0 * t.blocks / NULLIF(t.on_opp_two_pa, 0), 1)                                      AS blk_pct,               -- none
    ROUND(100.0 * t.fouls_personal / NULLIF(t.player_opp_poss, 0), 1)                            AS pf_per100,             -- opponent
    ROUND(100.0 * t.fouls_on / NULLIF(t.player_poss, 0), 1)                                      AS fouls_drawn_per100,    -- own

    -- F. Impact & overall
    ROUND(t.pir / NULLIF(t.games_played, 0), 1)                                                  AS pir_per_game,          -- none
    ROUND(100.0 * t.pir / NULLIF(t.player_poss_avg, 0), 1)                                       AS pir_per100,            -- game_average
    ROUND(t.game_score / NULLIF(t.games_played, 0), 1)                                           AS game_score_per_game,   -- none
    ROUND(40.0 * t.plus_minus / NULLIF(t.minutes_played, 0), 1)                                  AS plus_minus_per40,      -- none
    ROUND(100.0 * t.plus_minus / NULLIF(t.player_poss_avg, 0), 1)                                AS on_court_net_per100    -- game_average

FROM
    totals t