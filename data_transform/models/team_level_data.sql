{{

	config(
		materialized='table'
	)	

}}

WITH base AS (

SELECT
    match_id                                AS match_id,
    game_season                             AS game_season,
    data ->> 'match_date'                   AS match_date,
    data ->> 'venue'                        AS venue,
    data -> 'tm' -> '1' ->> 'name'          AS home_name,
    data -> 'tm' -> '2' ->> 'name'          AS away_name,
    
    (team.value ->> 'name')                     AS team_name,
    (team.value ->> 'tot_sMinutes')             AS minutes,
    ROUND((split_part(team.value ->> 'tot_sMinutes', ':', 1)::numeric * 60 + split_part(team.value ->> 'tot_sMinutes', ':', 2)::numeric) / 60, 2) AS total_minutes,
    (team.value ->> 'full_score')::INT          AS total_score,
    (team.value ->> 'p1_score')::INT            AS q1_score,
    (team.value ->> 'p2_score')::INT            AS q2_score,
    (team.value ->> 'p3_score')::INT            AS q3_score,
    (team.value ->> 'p4_score')::INT            AS q4_score,

    (team.value ->> 'tot_sPoints')::INT              AS total_points,
    (team.value ->> 'tot_sBenchPoints')::INT          AS total_points_bench,
    (team.value ->> 'tot_sPointsFastBreak')::INT     AS total_points_fastbreak,
    (team.value ->> 'tot_sPointsSecondChance')::INT  AS total_points_secondchance,
    (team.value ->> 'tot_sPointsFromTurnovers')::INT AS total_points_fromturnovers,
    (team.value ->> 'tot_sPointsInThePaint')::INT    AS total_paint,


    (team.value ->> 'tot_sTwoPointersAttempted')::INT   AS two_pa,
    (team.value ->> 'tot_sTwoPointersMade')::INT        AS two_pm,
    (team.value ->> 'tot_sTwoPointersPercentage')::INT  AS two_pct,

    (team.value ->> 'tot_sThreePointersAttempted')::INT  AS three_pa,
    (team.value ->> 'tot_sThreePointersMade')::INT       AS three_pm,
    (team.value ->> 'tot_sThreePointersPercentage')::INT AS three_pct,

    (team.value ->> 'tot_sFieldGoalsAttempted')::INT  AS fga,
    (team.value ->> 'tot_sFieldGoalsMade')::INT       AS fgm,
    (team.value ->> 'tot_sFieldGoalsPercentage')::INT AS fg_pct,

    (team.value ->> 'tot_sFreeThrowsAttempted')::INT  AS fta,
    (team.value ->> 'tot_sFreeThrowsMade')::INT       AS ftm,
    (team.value ->> 'tot_sFreeThrowsPercentage')::INT AS ft_pct,

    (team.value ->> 'tot_sAssists')::INT        AS assists,

    (team.value ->> 'tot_sReboundsTotal')::INT          AS total_rebound,
    (team.value ->> 'tot_sReboundsDefensive')::INT      AS drb,
    (team.value ->> 'tot_sReboundsOffensive')::INT      AS oreb,
    (team.value ->> 'tot_sReboundsTeamDefensive')::INT  AS drb_team,
    (team.value ->> 'tot_sReboundsTeamOffensive')::INT  AS oreb_team,

    (team.value ->> 'tot_sTurnovers')::INT      AS turnovers,
    (team.value ->> 'tot_sTurnoversTeam')::INT  AS turnovers_team,
    (team.value ->> 'tot_sFoulsTeam')::INT      AS fouls,
    (team.value ->> 'tot_sFoulsOn')::INT        AS fouls_on,
    (team.value ->> 'tot_sSteals')::INT         AS steals,
    (team.value ->> 'tot_sBlocks')::INT         AS blocks,

    (team.value ->> 'tot_sBenchPoints')::INT    AS bench_points,
    (team.value ->> 'tot_sBiggestLead')::INT    AS biggest_lead,
    (team.value ->> 'tot_sLeadChanges')::INT    AS lead_changes,
    (team.value ->> 'tot_sTimeLeading')         AS time_leading,

    team.value -> 'coachDetails' ->> 'scoreboardName' AS coach

FROM
    {{source('source_raw_matchdata','raw_matchdata')}}
    CROSS JOIN LATERAL jsonb_each(data -> 'tm') AS team

)
SELECT
    base.match_id,
    base.match_date,
    base.game_season,
    CASE
        WHEN LOWER(base.game_season) = 'ibl_gopay_2025' AND DATE_TRUNC('DAY', base.match_date::DATE) < '2025-06-26'  THEN 'regular_season'
        WHEN LOWER(base.game_season) = 'ibl_gopay_2025' AND DATE_TRUNC('DAY', base.match_date::DATE) >= '2025-06-26' THEN 'playoff'
        WHEN LOWER(base.game_season) = 'ibl_gopay_2026' AND DATE_TRUNC('DAY', base.match_date::DATE) < '2026-05-23'  THEN 'regular_season'
        WHEN LOWER(base.game_season) = 'ibl_gopay_2026' AND DATE_TRUNC('DAY', base.match_date::DATE) >= '2026-05-23' THEN 'playoff'
        ELSE 'undefined'
    END AS game_type,
    base.venue,
    CASE
        WHEN LOWER(base.game_season) = 'ibl_gopay_2025' AND base.home_name = 'Pelita Jaya Jakarta' THEN 'Pelita Jaya Basketball Jakarta'
        ELSE base.home_name
    END AS home_name
    CASE
        WHEN LOWER(base.game_season) = 'ibl_gopay_2025' AND base.away_name = 'Pelita Jaya Jakarta' THEN 'Pelita Jaya Basketball Jakarta'
        ELSE base.away_name
    END AS away_name
    CASE
        WHEN LOWER(base.game_season) = 'ibl_gopay_2025' AND base.team_name = 'Pelita Jaya Jakarta' THEN 'Pelita Jaya Basketball Jakarta'
        ELSE base.team_name
    END AS team_name,
    base.minutes,
    base.total_minutes,
    base.total_score,
    base.q1_score,
    base.q2_score,
    base.q3_score,
    base.q4_score,
    base.total_points,
    base.total_points_bench,
    base.total_points_fastbreak,
    base.total_points_secondchance,
    base.total_points_fromturnovers,
    base.total_paint,
    base.two_pa,
    base.two_pm,
    base.two_pct,
    base.three_pa,
    base.three_pm,
    base.three_pct,
    base.fga,
    base.fgm,
    base.fg_pct,
    base.fta,
    base.ftm,
    base.ft_pct,
    base.assists,
    base.total_rebound,
    base.drb,
    base.oreb,
    base.drb_team,
    base.oreb_team,
    base.turnovers,
    base.turnovers_team,
    base.fouls,
    base.fouls_on,
    base.steals,
    base.blocks,
    base.bench_points,
    base.biggest_lead,
    base.lead_changes,
    base.time_leading,
    base.coach
FROM
    base
ORDER BY
    game_season,
    match_date
