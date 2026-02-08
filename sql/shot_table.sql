/*
##################################
#                               #
#          Shot Data            #
#                               #
##################################
*/

CREATE TABLE IF NOT EXISTS shot_table(

	id 				SERIAL PRIMARY KEY,
	player_name		TEXT,
	match_id		INTEGER,
	match_date		DATE,
	venue			TEXT,
	team_name		TEXT,
	home_team		TEXT,
	away_team		TEXT,
	game_season		TEXT,
	game_type		TEXT,
	quarter			SMALLINT,
	shot_result		SMALLINT,
	x_loc			DOUBLE PRECISION,
	y_loc			DOUBLE PRECISION,
	shot_point		SMALLINT,
	shot_type		TEXT,
	adjusted_x_loc	DOUBLE PRECISION,
	adjusted_y_loc	DOUBLE PRECISION,
	halfcourt_xloc	DOUBLE PRECISION,
	halfcourt_yloc	DOUBLE PRECISION,
	adjusted_x_halfcourt_left DOUBLE PRECISION,
	adjusted_y_halfcourt_left DOUBLE PRECISION,
	color     		TEXT,
	marker			TEXT
)

















/*
UPDATE shot_table
SET
    color = CASE
        WHEN shot_point = 2 THEN 'blue'
        ELSE 'orange'
    END,
    marker = CASE
        WHEN shot_result = 1 THEN 'o'
        ELSE 'x'
    END,
    adjusted_x_halfcourt_left = CASE
        WHEN adjusted_x_loc < 14 THEN adjusted_x_loc
        ELSE 28 - adjusted_x_loc
    END,
    adjusted_y_halfcourt_left = CASE
        WHEN adjusted_x_loc < 14 THEN adjusted_y_loc
        ELSE 15 - adjusted_y_loc
    END;
*/

/*Check Null
SELECT
	COUNT(*) FILTER (WHERE player_name IS NULL) 	AS player_name_nulls,
	COUNT(*) FILTER (WHERE match_id IS NULL) 		AS match_id_nulls,
	COUNT(*) FILTER (WHERE match_date IS NULL) 	AS match_date_nulls,
	COUNT(*) FILTER (WHERE venue IS NULL) 			AS venue_nulls,
	COUNT(*) FILTER (WHERE team_name IS NULL) 		AS team_name_nulls,
	COUNT(*) FILTER (WHERE home_team IS NULL) 		AS home_team_nulls,
	COUNT(*) FILTER (WHERE away_team IS NULL) 		AS away_team_nulls,
	COUNT(*) FILTER (WHERE quarter IS NULL) 		AS quarter_nulls,
	COUNT(*) FILTER (WHERE shot_point IS NULL) 	AS shot_point_nulls,
	COUNT(*) FILTER (WHERE shot_type IS NULL) 		AS shot_type_nulls,
	COUNT(*) FILTER (WHERE shot_result IS NULL) 	AS shot_result_nulls,
	COUNT(*) FILTER (WHERE x_loc IS NULL) 			AS x_loc_nulls,
	COUNT(*) FILTER (WHERE y_loc IS NULL) 			AS y_loc_nulls,
	COUNT(*) FILTER (WHERE game_type IS NULL) 		AS game_type_nulls,
	COUNT(*) FILTER (WHERE adjusted_x_loc IS NULL)AS adjustted_x_loc_nulls,
	COUNT(*) FILTER (WHERE adjusted_y_loc IS NULL)AS adjustted_y_loc_nulls,
	COUNT(*) FILTER (WHERE halfcourt_xloc IS NULL) AS halfcourt_xloc_nulls,
	COUNT(*) FILTER (WHERE halfcourt_yloc IS NULL) AS halfcourt_yloc_nulls
FROM shot_table
*/

-- INDEX
CREATE INDEX IF NOT EXISTS idx_shots_player_name_gametype
ON shot_table (player_name, game_type);
*/