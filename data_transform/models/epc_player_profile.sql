{{
    config(
            materialized = 'table',
            alias        = 'epc_player_profile'
        )
}}

-- One row per player per team: the most recent non-empty photo seen in the season.
-- Players live at data -> 'tm' -> '1' / '2' -> 'pl' -> '<pno>'
--   photoT = thumbnail, photoS = standard.
-- The feed has no stable person ID (pno is per-match), so a player is keyed on
-- team_abr + first_name + family_name. A player who moves teams gets one row per team.

WITH base AS (

    SELECT
        r.match_id,
        (r.data ->> 'match_date')::DATE     AS match_date,
        r.data                              AS j
    FROM
        {{ source('source_raw_matchdata', 'raw_matchdata') }} r
		-- public.raw_matchdata r
    WHERE
        r.game_season = 'elite_pro_championship_2026'

),
teams AS (

    SELECT
        base.match_id,
        base.match_date,
		t.value ->> 'name' 		AS team_name,
        t.value ->> 'code'      AS team_abr,
        t.value -> 'pl'         AS pl
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)

),
player_rows AS (

    SELECT
        teams.match_id,
        teams.match_date,
        tp.team_id,
		tp.team_name,
		tp.team_abr,
        
        TRIM(p.value ->> 'firstName')                   AS first_name,
        TRIM(p.value ->> 'familyName')                  AS family_name,
        p.value ->> 'name'                              AS player_name,
        p.value ->> 'shirtNumber'                       AS shirt_number,
        p.value ->> 'playingPosition'                   AS position,
        NULLIF(p.value ->> 'photoS', '')                AS photo_url,
        NULLIF(p.value ->> 'photoT', '')                AS photo_thumb_url
    FROM
        teams
	INNER JOIN
		{{ ref('epc_team_profile') }} tp
		-- dbt_schema.epc_team_profile
		ON LOWER(tp.team_name) = LOWER(teams.team_name)
    CROSS JOIN
        LATERAL jsonb_each(teams.pl) AS p (key, value)

),
ranked AS (

    SELECT
        player_rows.*,
        ROW_NUMBER() OVER (PARTITION BY team_abr, LOWER(first_name), LOWER(family_name) ORDER BY (photo_url IS NULL), match_date DESC, match_id DESC) AS rn
    FROM
        player_rows
    WHERE
        team_abr IS NOT NULL

),
final AS (

    SELECT
        MD5(team_abr || '|' || LOWER(first_name) || '|' || LOWER(family_name)) AS player_key,
		team_id,
		team_name,
        team_abr,
        first_name,
        family_name,
        player_name,
        shirt_number,
        position,
        photo_url,
        photo_thumb_url,
        ROW_NUMBER() OVER (PARTITION BY player_name ORDER BY LENGTH(first_name) DESC) AS dedup_rn
    FROM
        ranked
    WHERE
        rn = 1
    ORDER BY
        team_abr,
        family_name
)
SELECT
    player_key,
	team_id,
	team_name,
    team_abr,
    first_name,
    family_name,
    player_name,
    shirt_number,
    position,
    photo_url,
    photo_thumb_url
FROM
    final
WHERE
    dedup_rn = 1