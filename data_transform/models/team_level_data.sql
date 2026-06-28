{{

	config(
		materialized='table'
	)	

}}

SELECT
    data ->> 'match_id'                     AS match_id,
    data ->> 'game_season'                  AS game_season,
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

    (team.value ->> 'tot_sReboundsTeam')::INT           AS total_rebound,
    (team.value ->> 'tot_sReboundsTeamDefensive')::INT  AS drb,
    (team.value ->> 'tot_sReboundsTeamOffensive')::INT  AS oreb,

    (team.value ->> 'tot_sTurnovers')::INT      AS turnovers,
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
ORDER BY
    match_date
