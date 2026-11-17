{{
    config(
            materialized = 'table',
            alias        = 'epc_team_photos'
        )
}}

-- One row per team: the most recent non-empty logo seen in the season.
-- Logos live at data -> 'tm' -> '1' / '2' -> 'logoT' / 'logoS' -> 'url'
--   logoT = 75x75 thumbnail, logoS = 200x200 standard.

WITH base AS (

    SELECT
        r.match_id,
        (r.data ->> 'match_date')::DATE     AS match_date,
        r.data                              AS j
    FROM
        {{ ref('epc_team_level_data') }} r
		-- public.raw_matchdata r
    WHERE
        r.game_season = 'elite_pro_championship_2026'

),

team_logos AS (

    SELECT
        base.match_id,
        base.match_date,
        t.value ->> 'code'                              AS team_abr,
        t.value ->> 'name'                              AS team_name,
        NULLIF(t.value -> 'logoT' ->> 'url', '')        AS logo_thumb_url,
        NULLIF(t.value -> 'logoS' ->> 'url', '')        AS logo_url
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)

),

ranked AS (

    SELECT
        team_logos.*,
		-- rows with a logo first
        ROW_NUMBER() OVER (PARTITION BY team_abr ORDER BY (logo_url IS NULL), match_date DESC, match_id DESC) AS rn
    FROM
        team_logos
    WHERE
        team_abr IS NOT NULL

)

SELECT
    team_abr,
    team_name,
    logo_url,
    logo_thumb_url
FROM
    ranked
WHERE
    rn = 1
ORDER BY
    team_abr