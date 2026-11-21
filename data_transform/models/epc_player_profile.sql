{{
    config(
            materialized = 'table',
            alias        = 'epc_player_profile'
        )
}}

/*
  epc_player_profile
  ------------------
  Layer  : staging (profile)
  Spec   : specs/epc_metrics_spec.yml -> identity.player
  Source : epc_player_mapping (player_id + canonical name) + raw_matchdata (position, photo)
  Grain  : one row per player_id (= team + shirt number)
  Name   : the canonical spelling from epc_player_mapping
  Photo  : the most recent non-empty photo, from ANY spelling of the player
  Pos    : the position he is listed at most often (empty values ignored)
  Seen   : matches on the roster (played or not) and the last match date, over all spellings
  Feeds  : epc_player_level_data (display name)
*/

WITH base AS (

    SELECT
        r.match_id,
        (r.data ->> 'match_date')::DATE                         AS match_date,
        r.data                                                  AS j
    FROM
        {{ source('source_raw_matchdata', 'raw_matchdata') }} r
		-- public.raw_matchdata r
    WHERE
        r.game_season = 'elite_pro_championship_2026'

),
player_rows AS (

    SELECT
        base.match_id,
        base.match_date,
        MD5(tp.team_id || '|' || NULLIF(TRIM(p.value ->> 'shirtNumber'), ''))  AS player_id,
        NULLIF(TRIM(p.value ->> 'playingPosition'), '')         AS position,
        NULLIF(p.value ->> 'photoS', '')                        AS photo_url,
        NULLIF(p.value ->> 'photoT', '')                        AS photo_thumb_url
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)
    LEFT JOIN
        {{ ref('epc_team_profile') }} tp
		-- dbt_schema.epc_team_profile tp
        ON LOWER(tp.team_name) = LOWER(TRIM(t.value ->> 'name'))
    CROSS JOIN
        LATERAL jsonb_each(t.value -> 'pl') AS p (key, value)

),
photos AS (

    SELECT
        player_id,
        photo_url,
        photo_thumb_url,
        ROW_NUMBER() OVER (
            PARTITION BY player_id
            ORDER BY (photo_url IS NULL), match_date DESC, match_id DESC
        )                                                       AS rn
    FROM
        player_rows

),
seen AS (

    SELECT
        player_id,
        COUNT(DISTINCT match_id)                                AS matches_listed,
        MAX(match_date)                                         AS last_seen
    FROM
        player_rows
    GROUP BY
        player_id

),
positions AS (

    SELECT
        player_id,
        position,
        ROW_NUMBER() OVER (
            PARTITION BY player_id
            ORDER BY COUNT(*) DESC, MAX(match_date) DESC
        )                                                       AS rn
    FROM
        player_rows
    WHERE
        position IS NOT NULL
    GROUP BY
        player_id, position

)
SELECT
    m.player_id,
    m.team_id,
    m.team_name,
    m.team_abr,                                                 -- display label only, not a key
    m.shirt_number,
    m.canonical_first_name                                      AS first_name,
    m.canonical_family_name                                     AS family_name,
    m.canonical_player_name                                     AS player_name,
    pos.position,
    ph.photo_url,
    ph.photo_thumb_url,
    m.spelling_count,                                           -- > 1 = name was spelled differently in some matches
    se.matches_listed,                                          -- matches on the roster (played or not)
    se.last_seen
FROM
    {{ ref('epc_player_mapping') }} m
	-- dbt_schema.epc_player_mapping m
LEFT JOIN
    photos ph
    ON  ph.player_id = m.player_id
    AND ph.rn = 1
LEFT JOIN
    positions pos
    ON  pos.player_id = m.player_id
    AND pos.rn = 1
LEFT JOIN
    seen se
    ON  se.player_id = m.player_id
WHERE
    m.is_canonical
ORDER BY
    m.team_abr,
    m.family_name