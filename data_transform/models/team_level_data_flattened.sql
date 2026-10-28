{{

	config(
		materialized='table'
	)	

}}

WITH base AS (

SELECT
    home.match_id,
    home.match_date,
    home.game_season,
    home.game_type,
    home.team_name,
    away.team_name                          AS away_team,
    --home_team data
    home.total_score,
    home.fga,
    home.fgm,
    home.two_pa,
    home.two_pm,
    home.three_pa,
    home.three_pm,
    home.fta,
    home.ftm,
    home.oreb,
    home.oreb_team,
    home.oreb + home.oreb_team              AS total_oreb,
    home.drb,
    home.drb_team,
    home.drb + home.drb_team                AS total_drb,
    home.turnovers,
    home.turnovers_team,
    home.turnovers + home.turnovers_team    AS total_turnovers,
    home.fouls,
    home.total_points_bench,
    home.total_points_fastbreak,
    home.total_points_secondchance,
    home.total_points_fromturnovers,
    home.total_paint,
    -- Away Team
    away.total_score                       AS opp_total_score,
    away.fga                               AS opp_fga,
    away.fgm                               AS opp_fgm,
    away.two_pa                            AS opp_two_pa,
    away.two_pm                            AS opp_two_pm,
    away.three_pa                          AS opp_three_pa,
    away.three_pm                          AS opp_three_pm,
    away.fta                               AS opp_fta,
    away.ftm                               AS opp_ftm,
    away.oreb                              AS opp_oreb,
    away.oreb_team                         AS opp_oreb_team,
    away.oreb + away.oreb_team             AS opp_total_oreb,                              
    away.drb                               AS opp_drb,
    away.drb_team                          AS opp_drb_team,
    away.drb + away.drb_team               AS opp_total_drb,                               
    away.turnovers                         AS opp_turnovers,
    away.turnovers_team                    AS opp_turnovers_team,
    away.turnovers + away.turnovers_team   AS opp_total_turnovers,                             
    away.fouls                             AS opp_fouls,
    away.total_points_bench                AS opp_total_points_bench,
    away.total_points_fastbreak            AS opp_total_points_fastbreak,
    away.total_points_secondchance         AS opp_total_points_secondchance,
    away.total_points_fromturnovers        AS opp_total_points_fromturnovers,
    away.total_paint                       AS opp_total_point
FROM
    {{ source('source_team_level_data','team_level_data') }} home
LEFT JOIN
	{{ source('source_team_level_data','team_level_data') }} away
    ON home.match_id = away.match_id
    AND home.team_name <> away.team_name

)
SELECT
    *,

    --Team Poss
    base.fga - base.total_oreb + base.total_turnovers + (0.54 * base.fta)							AS est_poss,
    base.opp_fga - base.opp_total_oreb + base.opp_total_turnovers + (0.54 * base.opp_fta)           AS opp_est_poss,

    -- eFG%
    100 * ((base.fgm     + (0.5*(base.three_pm))) / base.fga)			    AS efg,
    100 * ((base.opp_fgm + (0.5*(base.opp_three_pm))) / base.opp_fga)	    AS opp_efg,

    -- DREB %
    base.total_drb     / (base.total_drb + base.opp_total_oreb)		AS drb_perc,
    base.opp_total_drb / (base.opp_total_drb + base.total_oreb)		AS opp_drb_perc,

    -- FTA %
    base.fta / base.fga                 AS ftr,
    base.opp_fta / base.opp_fga	        AS opp_ftr
FROM
    base
ORDER BY
    base.game_season,
    base.match_date
