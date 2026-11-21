{{
    config(
            materialized = 'table',
            alias        = 'epc_team_profile'
        )
}}

/*
  epc_team_profile
  ----------------
  Layer  : staging (profile)
  Spec   : specs/epc_metrics_spec.yml -> identity.team
  Source : raw_matchdata -> data -> 'tm' -> '1' / '2'
  Grain  : one row per team
  Key    : team_id = MD5(LOWER(team_name)). The feed has no team id and team codes (team_abr) can
           collide as the league expands, so the name is the natural key. The hash is stable:
           adding a team never changes existing ids. team_abr is a display label only.
  Join   : other models join here on LOWER(TRIM(team_name)) to get team_id.
  Pick   : the row with a non-empty logo (logoS = 200x200, logoT = 75x75 thumbnail).
  Feeds  : epc_player_mapping, epc_player_profile, epc_player_level_data
*/

WITH base AS (

    SELECT
        r.match_id,
        r.data			AS j
    FROM
        {{ source('source_raw_matchdata', 'raw_matchdata') }} r
		-- public.raw_matchdata r
    WHERE
        r.game_season = 'elite_pro_championship_2026'

),
team_rows AS (

    SELECT
        base.match_id,
        TRIM(t.value ->> 'name')                        	AS team_name,
        t.value ->> 'code'                              	AS team_abr,
        t.value ->> 'shortName'                         	AS team_short_name,
        NULLIF(t.value -> 'logoT' ->> 'url', '')        	AS logo_thumb_url,
        NULLIF(t.value -> 'logoS' ->> 'url', '')        	AS logo_url,
		NULLIF(INITCAP(t.value ->> 'coach'), '')			AS head_coach,
		NULLIF(INITCAP(t.value ->> 'assistcoach1'), '')		AS assistcoach1,
		NULLIF(INITCAP(t.value ->> 'assistcoach2'), '')		AS assistcoach2
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)

),
ranked AS (

    SELECT
        team_rows.*,
        ROW_NUMBER() OVER (PARTITION BY LOWER(team_name) ORDER BY (logo_url IS NULL)) AS rn
    FROM
        team_rows
    WHERE
        NULLIF(team_name, '') IS NOT NULL

),
final_data AS (

	SELECT
	    MD5(LOWER(team_name))   AS team_id,
	    team_name,
	    team_abr,               -- display label only, not a key
	    team_short_name,
	    logo_url,
	    logo_thumb_url,
		head_coach,
		assistcoach1,
		assistcoach2
	FROM
	    ranked
	WHERE
	    rn = 1
	ORDER BY
	    team_name
)
SELECT
	*
FROM
	final_data
