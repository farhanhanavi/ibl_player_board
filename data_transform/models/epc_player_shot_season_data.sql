{{
    config(
            materialized = 'table',
            alias        = 'epc_player_shot_season_data'
        )
}}

WITH zones AS (

    SELECT *
    FROM (VALUES
        (0, 'All Shots'),
        (1, 'Restricted Area'),
        (2, 'Paint Area'),
        (3, 'Midrange'),
        (4, 'Corner 3'),
        (5, 'ATB')
    ) AS z (zone_order, shot_zone)

),

players AS (

    SELECT
        ps.game_season,
        ps.player_id,
        ps.player_name,
        ps.team_id,
        ps.team_name,
        ps.games_played,
        ps.is_qualified
    FROM
        {{ ref('epc_player_season_level_data') }} ps
		-- dbt_schema.epc_player_season_level_data ps
    WHERE
        ps.row_type = 'player'

),

player_zone AS (

    -- season totals per player x zone; GROUPING SETS adds the 'All Shots' row
    SELECT
        s.game_season,
        s.player_id,
        CASE WHEN GROUPING(s.shot_zone) = 1 THEN 'All Shots' ELSE s.shot_zone END    AS shot_zone,
        COUNT(*)                                                                     AS fga,
        SUM(CASE WHEN s.is_made THEN 1 ELSE 0 END)                                   AS fgm,
        SUM(CASE WHEN s.is_made AND s.shot_type = '3pt' THEN 3
                 WHEN s.is_made                         THEN 2
                 ELSE 0 END)                                                         AS pts
    FROM
        {{ ref('epc_player_shot_data') }} s
		-- dbt_schema.epc_player_shot_data s
    WHERE
        s.player_id IS NOT NULL
    GROUP BY
        GROUPING SETS ((s.game_season, s.player_id, s.shot_zone), (s.game_season, s.player_id))

),

player_grid AS (

    -- every player gets all 6 rows, 0 where he took no shot from that zone
    SELECT
        pl.game_season,
        pl.player_id,
        'player'                                AS row_type,
        pl.player_name,
        pl.team_id,
        pl.team_name,
        pl.games_played,
        pl.is_qualified,
        z.zone_order,
        z.shot_zone,
        COALESCE(pz.fga, 0)                     AS fga,
        COALESCE(pz.fgm, 0)                     AS fgm,
        COALESCE(pz.pts, 0)                     AS pts
    FROM
        players pl
    CROSS JOIN
        zones z
    LEFT JOIN
        player_zone pz
        ON  pz.game_season = pl.game_season
        AND pz.player_id   = pl.player_id
        AND pz.shot_zone   = z.shot_zone

),

league AS (

    SELECT
        game_season,
        'LEAGUE'                                AS player_id,
        'league'                                AS row_type,
        'League Average'                        AS player_name,
        NULL::TEXT                              AS team_id,
        NULL::TEXT                              AS team_name,
        SUM(games_played)                       AS games_played,     -- player-games of qualified players
        TRUE                                    AS is_qualified,
        zone_order,
        shot_zone,
        SUM(fga)                                AS fga,
        SUM(fgm)                                AS fgm,
        SUM(pts)                                AS pts
    FROM
        player_grid
    WHERE
        is_qualified
    GROUP BY
        game_season, zone_order, shot_zone

),

stacked AS (

    SELECT * FROM player_grid
    UNION ALL
    SELECT * FROM league

),
metrics AS (

    SELECT
        st.*,
        ROUND(st.fga::NUMERIC / NULLIF(st.games_played, 0), 1)                                    AS fga_per_game,   -- LEAGUE: per qualified player-game
        ROUND(100.0 * st.fga / NULLIF(MAX(CASE WHEN st.zone_order = 0 THEN st.fga END)
                                      OVER (PARTITION BY st.game_season, st.player_id), 0), 1)    AS fga_share_pct,  -- All Shots = 100
        ROUND(100.0 * st.fgm / NULLIF(st.fga, 0), 1)                                              AS fg_pct,         -- NULL when fga = 0
        ROUND(st.pts::NUMERIC / NULLIF(st.fga, 0), 3)                                             AS pts_per_shot
    FROM
        stacked st

),
final_data AS (

	SELECT
	    m.game_season,
	    m.player_id,
	    m.row_type,
	    m.player_name,
	    m.team_id,
	    m.team_name,
	    m.is_qualified,
	    m.games_played,
	    m.zone_order,
	    m.shot_zone,
	    m.fga,
	    m.fgm,
	    m.pts,
	    m.fga_per_game,
	    m.fga_share_pct,
	    m.fg_pct,
	    m.pts_per_shot,
	    lg.fga_share_pct                                        AS league_fga_share_pct,
	    lg.fg_pct                                               AS league_fg_pct,
	    lg.pts_per_shot                                         AS league_pts_per_shot,
	    ROUND(m.fga_share_pct - lg.fga_share_pct, 1)            AS fga_share_diff_vs_league,
	    ROUND(m.fg_pct - lg.fg_pct, 1)                          AS fg_pct_diff_vs_league,       -- NULL when fga = 0
	    ROUND(m.pts_per_shot - lg.pts_per_shot, 3)              AS pts_per_shot_diff_vs_league
	FROM
	    metrics m
	LEFT JOIN
	    metrics lg
	    ON  lg.game_season = m.game_season
	    AND lg.shot_zone   = m.shot_zone
	    AND lg.row_type    = 'league'
)
SELECT
	*
FROM
	final_data