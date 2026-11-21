{{
    config(
            materialized = 'table',
            alias        = 'epc_standing'
        )
}}

/*
  epc_standing   (file: epc_standings.sql, table alias: epc_standing)
  ------------
  Layer  : mart
  Spec   : specs/epc_metrics_spec.yml -> standings
  Source : epc_team_level_data
  Grain  : one row per team
  Points : FIBA table points = 2 per win + 1 per loss.
  Order  : wins, then total points scored (not FIBA head-to-head tie-breaks).
*/

WITH cte AS (

	SELECT
		team_name,
		COUNT(DISTINCT match_id)																AS games_played,
		COUNT(CASE WHEN is_win = TRUE THEN match_id ELSE NULL END) 								AS game_win,
		COUNT(DISTINCT match_id) - COUNT(CASE WHEN is_win = TRUE THEN match_id ELSE NULL END)	AS game_lost,
		SUM(total_points) AS total_score
	FROM
        {{ ref('epc_team_level_data') }}
		-- dbt_schema.epc_team_level_data
	GROUP BY
		1
)
SELECT
	cte.team_name,
	cte.games_played,
	cte.game_win,
	cte.game_lost,
	(cte.game_win * 2) + game_lost AS pts
FROM
	cte 
ORDER BY
	game_win DESC,
	total_score DESC