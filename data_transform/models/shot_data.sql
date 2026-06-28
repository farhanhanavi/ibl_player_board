-- models/stg_fiba_shots.sql

{{ config(materialized='table') }}

WITH cte AS (

    SELECT
        data ->> 'match_id'            AS match_id,
	data ->> 'game_season'         AS game_season,
	data ->> 'match_date'          AS match_date,
	data ->> 'venue'               AS match_venue,
	data -> 'tm' -> '1' ->> 'name' AS home_team,
	data -> 'tm' -> '2' ->> 'name' AS away_team,
        data::jsonb as raw_json
    FROM
	{{ source('source_raw_matchdata', 'raw_matchdata') }}

),

teams AS (

    SELECT
        cte.match_id,
	cte.game_season,
        cte.match_date,
	cte.match_venue,
	cte.home_team,
	cte.away_team,
        team.key as team_key,
        team.value as team_json
    FROM
	cte,
	jsonb_each(cte.raw_json -> 'tm') AS team(key, value)

),

shots AS (

    SELECT
        t.match_id,
	t.game_season,
        t.match_date,
	t.match_venue,
	t.home_team,
	t.away_team,
        t.team_json ->> 'name' as team_name,
        shot.value as shot_json
    FROM
	teams t,
	jsonb_array_elements(t.team_json -> 'shot') as shot(value)

),
raw_data AS (

    SELECT
        match_id,
        game_season,
        match_date,
        match_venue,
        home_team,
        away_team,

        shot_json ->> 'player' AS player_name,
        team_name,
        (shot_json ->> 'per')::INT AS quarter,
        shot_json ->> 'perType'    AS period_type,
        shot_json ->> 'actionType' AS shot_type,
        shot_json ->> 'subType'    AS shot_subtye,
        (shot_json ->> 'r')::INT   AS shot_result,

        (shot_json ->> 'x')::DOUBLE PRECISION        AS x_loc,
        (shot_json ->> 'y')::DOUBLE PRECISION        AS y_loc,
	(shot_json ->> 'x')::DOUBLE PRECISION * 0.28 AS adjusted_x_loc,
	(shot_json ->> 'y')::DOUBLE PRECISION * 0.15 AS adjusted_y_loc
FROM
    shots
)

SELECT
    *,
    CASE
	WHEN rd.adjusted_x_loc < 28/2 THEN 28-rd.adjusted_x_loc
	ELSE rd.adjusted_x_loc
    END AS halfcourt_xloc,
    CASE
	WHEN rd.adjusted_x_loc < 28/2 THEN 15-rd.adjusted_y_loc
	ELSE rd.adjusted_y_loc
    END AS halfcourt_yloc,
    CASE
	WHEN rd.adjusted_x_loc < 28/2 THEN rd.adjusted_x_loc
	ELSE 28-rd.adjusted_x_loc
    END AS adjusted_x_halfcourt_left,
    CASE
	WHEN rd.adjusted_x_loc < 28/2 THEN rd.adjusted_y_loc
	ELSE 15-rd.adjusted_y_loc
    END AS adjusted_y_halfcourt_left
FROM
    raw_data rd
