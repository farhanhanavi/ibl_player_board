{{
    config(
        materialized='table'
    )
}}

WITH raw_table AS (

    SELECT 
        game_season,
        match_id,
        data ->> 'match_date'                   AS match_date,
        data ->> 'venue'                        AS venue,
        data -> 'tm' -> '1' ->> 'name'          AS home_team,
        data -> 'tm' -> '1' ->> 'full_score'    AS home_point,
        data -> 'tm' -> '2' ->> 'name'          AS away_team,
        data -> 'tm' -> '1' ->> 'full_score'    AS away_point
    FROM 
        {{ source('source_raw_matchdata','raw_matchdata') }}
)
SELECT
    rt.*,
    CASE
        WHEN home_point > away_point THEN 1
        ELSE 0
    END AS home_win,
    CASE
        WHEN home_point < away_point THEN 1
        ELSE 0
    END AS away_win
FROM
    raw_table rt
ORDER BY
    game_season
    
