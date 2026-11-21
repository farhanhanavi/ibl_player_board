{{
    config(
            materialized = 'table',
            alias        = 'epc_player_mapping'
        )
}}

/*
  epc_player_mapping
  ------------------
  Layer  : staging (identity)
  Spec   : specs/epc_metrics_spec.yml -> identity.player
  Source : raw_matchdata -> data -> 'tm' -> '<n>' -> 'pl' -> '<pno>'
  Grain  : one row per player x name spelling seen in the feed
           (a player with 3 spellings has 3 rows, all with the same player_id)
  Key    : player_id = MD5(team_id | shirt_number)
           The feed spells names differently between matches ('Elang Satria R' / 'Elang Satria
           Rajendra', 'Toraya' / 'Torraya'), but team + shirt number stays the same, and a shirt
           number is unique inside a team in a match (FIBA rule).
           Empty shirt number -> player_id is NULL (caught by the not_null test).
  Name   : one canonical spelling per player (is_canonical = TRUE), ranked by
             0. has both first and family name (an incomplete entry never wins)
             1. fewest abbreviated words  ('Rajendra' beats 'R'; the first word is not counted,
                                           so 'I Gusti' / 'M Riandra' are not penalised)
             2. most matches              (fixes typos: the most used spelling wins)
             3. longest first name, then longest family name
             4. most recent match
  Note   : position is not part of the grain (an empty vs filled position is the same player).
  Feeds  : epc_player_profile
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
        tp.team_id,
        tp.team_name,
        tp.team_abr,
        NULLIF(TRIM(p.value ->> 'shirtNumber'), '')             AS shirt_number,
        NULLIF(TRIM(p.value ->> 'firstName'), '')               AS first_name,
        NULLIF(TRIM(p.value ->> 'familyName'), '')              AS family_name,
        TRIM(p.value ->> 'name')                                AS stored_player_name
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
spellings AS (

    -- one row per player x spelling, with how often and how recently it was used
    SELECT
        MD5(team_id || '|' || shirt_number)                     AS player_id,
        team_id,
        team_name,
        team_abr,
        shirt_number,
        first_name,
        family_name,
        stored_player_name,
        COUNT(DISTINCT match_id)                                AS n_matches,
        MAX(match_date)                                         AS last_seen
    FROM
        player_rows
    GROUP BY
        team_id, team_name, team_abr, shirt_number, first_name, family_name, stored_player_name

),
scored AS (

    SELECT
        s.*,
        -- single-letter words = abbreviations ('Elang Satria R' -> 1, 'I Gusti B H' -> 2)
          (SELECT COUNT(*) FROM UNNEST((STRING_TO_ARRAY(s.first_name, ' '))[2:]) AS w (word) WHERE LENGTH(REPLACE(w.word, '.', '')) = 1)
        + (SELECT COUNT(*) FROM UNNEST(STRING_TO_ARRAY(s.family_name, ' ')) AS w (word) WHERE LENGTH(REPLACE(w.word, '.', '')) = 1)          AS abbreviated_words
    FROM
        spellings s

),
ranked AS (

    SELECT
        sc.*,
        COUNT(*) OVER (PARTITION BY sc.player_id)               AS spelling_count,
        ROW_NUMBER() OVER (
            PARTITION BY sc.player_id
            ORDER BY
                (sc.first_name IS NULL OR sc.family_name IS NULL),
                sc.abbreviated_words,
                sc.n_matches                    DESC,
                LENGTH(sc.first_name)           DESC NULLS LAST,
                LENGTH(sc.family_name)          DESC NULLS LAST,
                sc.last_seen                    DESC,
                sc.stored_player_name
        )                                                       AS spelling_rank
    FROM
        scored sc

)
SELECT
    r.player_id,
    r.team_id,
    r.team_name,
    r.team_abr,
    r.shirt_number,

    -- this spelling (join keys back to the feed)
    r.first_name,
    r.family_name,
    r.stored_player_name,
    r.n_matches,
    r.last_seen,
    r.abbreviated_words,

    -- the player's canonical spelling (same on every row of the player)
    FIRST_VALUE(r.first_name)         OVER w                    AS canonical_first_name,
    FIRST_VALUE(r.family_name)        OVER w                    AS canonical_family_name,
    FIRST_VALUE(r.stored_player_name) OVER w                    AS canonical_player_name,
    (r.spelling_rank = 1)                                       AS is_canonical,
    r.spelling_count,
    (r.spelling_count > 1)                                      AS has_variants
FROM
    ranked r
WINDOW
    w AS (PARTITION BY r.player_id ORDER BY r.spelling_rank)
ORDER BY
    r.team_name,
    r.shirt_number,
    r.spelling_rank