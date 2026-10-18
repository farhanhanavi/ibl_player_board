{{
    config(
        materialized='table'
    )
}}

WITH pbp_data AS (

	SELECT
	    raw.data->>'match_id' 				AS match_id,
		raw.data->>'match_date'				AS match_date,
		raw.data-> 'tm' -> '1' ->> 'name'	AS home_name,
		raw.data-> 'tm' -> '2' ->> 'name'	AS away_name,
		CASE
			WHEN pbp.event->>'tno' = '1' THEN raw.data-> 'tm' -> '1' ->> 'name'
			ELSE raw.data-> 'tm' -> '2' ->> 'name'
		END AS team_name,
		pbp.event->>'gt' 					AS game_time,
		pbp.event->>'periodType'			AS period_type,
		pbp.event->>'period'				AS period,
	    pbp.event->>'actionType' 			AS action_type,
	    pbp.event->>'subType' 				AS sub_type,
	    (pbp.event->>'success')::INT 		AS success,
		pbp.event->>'actionNumber'			AS action_number
	FROM
	    {{source('source_raw_matchdata','raw_matchdata')}} raw
	CROSS JOIN LATERAL
	    jsonb_array_elements(raw.data->'pbp') AS pbp(event)
	ORDER BY
		match_date,
		team_name,
		action_number
		
)
SELECT
	*
FROM
	pbp_data