-- 2025 standings https://www.instagram.com/p/DLMjmqTp15I/?img_index=1

/*
    PJ vs DEWA
    match_id = 2607581
    https://www.flashscore.com/match/basketball/dewa-united-banten-zkBtwnA1/pelita-jaya-hjC2gcCJ/?mid=IXp6bkQ0
*/
UPDATE raw_matchdata
SET data = jsonb_set(
    jsonb_set(data, '{tm,1,full_score}', '96'::jsonb, false),
    '{tm,2,full_score}', '85'::jsonb, false
)
WHERE 
	match_id = '2607581'
  	AND data #>> '{tm,1,full_score}' = '85'
  	AND data #>> '{tm,2,full_score}' = '73'
RETURNING
    match_id,
    data #>> '{tm,1,name}'       AS home_name,
    data #>> '{tm,1,full_score}' AS home_score,
    data #>> '{tm,2,name}'       AS away_name,
    data #>> '{tm,2,full_score}' AS away_score


UPDATE raw_matchdata
SET data = jsonb_set(
    jsonb_set(
        data,
        '{tm,1}',
        (data #> '{tm,1}') || '{
            "full_score": 96,
            "tot_sPoints": 96,
            "p1_score": 28,
            "p2_score": 28,
            "p3_score": 17,
            "p4_score": 23,
            "tot_sFieldGoalsMade": 32,
            "tot_sFieldGoalsAttempted": 64,
            "tot_sFieldGoalsPercentage": 50,
            "tot_sTwoPointersMade": 17,
            "tot_sTwoPointersAttempted": 37,
            "tot_sTwoPointersPercentage": 45,
            "tot_sThreePointersMade": 15,
            "tot_sThreePointersAttempted": 27,
            "tot_sThreePointersPercentage": 55,
            "tot_sFreeThrowsMade": 17,
            "tot_sFreeThrowsAttempted": 25,
            "tot_sFreeThrowsPercentage": 68,
            "tot_sReboundsOffensive": 15,
            "tot_sReboundsDefensive": 23,
			"tot_sReboundsTeamOffensive" : 0,
			"tot_sReboundsTeamDefensive" : 0,
            "tot_sReboundsTotal": 38,
            "tot_sAssists": 25,
            "tot_sBlocks": 4,
            "tot_sTurnovers": 12,
			"tot_sTurnoversTeam": 0,
            "tot_sSteals": 7,
            "tot_sFoulsPersonal": 18
        }'::jsonb,
        false
    ),
    '{tm,2}',
    (data #> '{tm,2}') || '{
        "full_score": 85,
        "tot_sPoints": 85,
        "p1_score": 20,
        "p2_score": 24,
        "p3_score": 19,
        "p4_score": 22,
        "tot_sFieldGoalsMade": 31,
        "tot_sFieldGoalsAttempted": 66,
        "tot_sFieldGoalsPercentage": 47,
        "tot_sTwoPointersMade": 22,
        "tot_sTwoPointersAttempted": 41,
        "tot_sTwoPointersPercentage": 53,
        "tot_sThreePointersMade": 9,
        "tot_sThreePointersAttempted": 25,
        "tot_sThreePointersPercentage": 36,
        "tot_sFreeThrowsMade": 14,
        "tot_sFreeThrowsAttempted": 19,
        "tot_sFreeThrowsPercentage": 73,
        "tot_sReboundsOffensive": 14,
        "tot_sReboundsDefensive": 21,
		"tot_sReboundsTeamOffensive" : 0,
		"tot_sReboundsTeamDefensive" : 0,
        "tot_sReboundsTotal": 35,
        "tot_sAssists": 18,
        "tot_sBlocks": 0,
        "tot_sTurnovers": 9,
		"tot_sTurnoversTeam": 0,
        "tot_sSteals": 8,
        "tot_sFoulsPersonal": 16
    }'::jsonb,
    false
)
WHERE match_id = '2607581'
  AND data ->> 'match_date' = '2025-01-11'
  AND data #>> '{tm,1,name}' = 'Pelita Jaya Jakarta'
  AND data #>> '{tm,2,name}' = 'Dewa United Banten'
RETURNING
    match_id,
    data #>> '{tm,1,name}'       AS home_name,
    data #>> '{tm,1,tot_sPoints}' AS home_points,
    data #>> '{tm,2,name}'       AS away_name,
    data #>> '{tm,2,tot_sPoints}' AS away_points;



/*
    THB vs Prawira Bandung
    65 - 73 ->> 74 - 77
    https://www.flashscore.com/match/basketball/prawira-bandung-bX26kc2O/tangerang-hawks-KG99pUHR/?mid=QR7khxu1
*/

UPDATE raw_matchdata
SET data = jsonb_set(
    jsonb_set(data, '{tm,1,full_score}', '74'::jsonb, false),
    '{tm,2,full_score}', '77'::jsonb, false
)
WHERE 
	match_id = '2607762'
  	AND data #>> '{tm,1,full_score}' = '65'
  	AND data #>> '{tm,2,full_score}' = '73'
RETURNING
    match_id,
    data #>> '{tm,1,name}'       AS home_name,
    data #>> '{tm,1,full_score}' AS home_score,
    data #>> '{tm,2,name}'       AS away_name,
    data #>> '{tm,2,full_score}' AS away_score;

/*

RJM vs BHB
https://www.mainbasket.com/c/5/jadwal/ibl/1828/detail

*/

UPDATE raw_matchdata
SET data = jsonb_set(
    jsonb_set(data, '{tm,1,full_score}', '84'::jsonb, false),
    '{tm,2,full_score}', '94'::jsonb, false
)
WHERE 
	match_id = '2607814'
  	AND data #>> '{tm,1,full_score}' = '31'
  	AND data #>> '{tm,2,full_score}' = '26'
RETURNING
    match_id,
    data #>> '{tm,1,name}'       AS home_name,
    data #>> '{tm,1,full_score}' AS home_score,
    data #>> '{tm,2,name}'       AS away_name,
    data #>> '{tm,2,full_score}' AS away_score;