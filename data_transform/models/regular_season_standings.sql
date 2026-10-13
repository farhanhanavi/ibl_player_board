{{
    config(
        materialized='table'
    )
}}


WITH game_data AS (

	SELECT
		home_team					AS team_name,
		SUM(home_point) 			AS point_scored,
		SUM(away_point)				AS point_conceeded,
		COUNT(DISTINCT match_id)	AS total_match,
		SUM(home_win)				AS total_win,
		SUM(away_win)				AS total_loose
	FROM
		{{ ref ('match_overview') }}
	WHERE
		game_type = 'regular_season'
	GROUP BY
		1

	UNION ALL

	SELECT
		away_team					AS team_name,
		SUM(away_point) 			AS point_scored,
		SUM(home_point)				AS point_conceeded,
		COUNT(DISTINCT match_id)	AS total_match,
		SUM(away_win)				AS total_win,
		SUM(home_win)				AS total_loose
	FROM
		{{ ref ('match_overview') }}
	WHERE
		game_type = 'regular_season'
	GROUP BY
		1
)
SELECT
	gd.team_name,
	SUM(total_match)  AS total_match,
	SUM(total_win)	  AS total_win,
	SUM(total_loose)  AS total_loose,
	(SUM(total_win) * 2) + SUM(total_loose)  	AS total_pts,
	SUM(point_scored) 							AS point_scored,
	SUM(point_conceeded)						AS point_conceeded,
	SUM(point_scored) - SUM(point_conceeded)	AS point_diff
FROM	
	game_data gd
GROUP BY
	1
ORDER BY
	total_pts DESC,
	point_diff DESC