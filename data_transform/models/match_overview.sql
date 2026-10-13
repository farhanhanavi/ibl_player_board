{{
    config(
        materialized='table'
    )
}}

WITH raw_table AS (

    SELECT 
        game_season,
        match_id,
        data ->> 'match_date'                           AS match_date,
        data ->> 'venue'                                AS venue,
        data -> 'tm' -> '1' ->> 'name'                  AS home_team,
        data -> 'tm' -> '1' ->> 'full_score'            AS home_point,
        data -> 'tm' -> '2' ->> 'name'                  AS away_team,
        data -> 'tm' -> '2' ->> 'full_score'            AS away_point
    FROM 
        {{ source('source_raw_matchdata','raw_matchdata') }}
)
SELECT
    rt.match_id,
    rt.match_date,
    rt.game_season,
    CASE
        WHEN LOWER(game_season) = 'ibl_gopay_2025' AND DATE_TRUNC('DAY', match_date::DATE) < '2025-06-26'  THEN 'regular_season'
        WHEN LOWER(game_season) = 'ibl_gopay_2025' AND DATE_TRUNC('DAY', match_date::DATE) >= '2025-06-26' THEN 'playoff'
        WHEN LOWER(game_season) = 'ibl_gopay_2026' AND DATE_TRUNC('DAY', match_date::DATE) < '2026-05-23'  THEN 'regular_season'
        WHEN LOWER(game_season) = 'ibl_gopay_2026' AND DATE_TRUNC('DAY', match_date::DATE) >= '2026-05-23' THEN 'playoff'
        ELSE 'undefined'
    END AS game_type,
    rt.venue,
    rt.home_team,
    rt.away_team,
    rt.home_point::INT  AS home_point,
    rt.away_point::INT  AS away_point,
    CASE
        WHEN home_point::INT > away_point::INT THEN 1
        ELSE 0
    END AS home_win,
    CASE
        WHEN home_point::INT < away_point::INT THEN 1
        ELSE 0
    END AS away_win
FROM
    raw_table rt
ORDER BY
    game_season
    
