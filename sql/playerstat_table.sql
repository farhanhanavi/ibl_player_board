/* Create Table */
CREATE TABLE IF NOT EXISTS playerstat_table(

    id 									SERIAL PRIMARY KEY,
    player_name							TEXT,
    player_position 					TEXT,
    match_id							INTEGER,
    match_date							DATE,
    venue								TEXT,
    team_name							TEXT,
    home_team							TEXT,
    away_team							TEXT,
    game_season                         TEXT, 
    game_type							TEXT,
    game_minutes						NUMERIC(4,2), /*Exact number stored*/
    player_is_starter					SMALLINT,
    game_field_goals_attempted			SMALLINT,
    game_field_goals_made				SMALLINT,
    game_three_pointers_attempted		SMALLINT,
    game_three_pointers_made			SMALLINT,
    game_two_pointers_attempted			SMALLINT,
    game_two_pointers_made				SMALLINT,
    game_free_throws_attempted			SMALLINT,
    game_free_throws_made				SMALLINT,
    game_rebounds_defensive				SMALLINT,
    game_rebounds_offensive				SMALLINT,
    game_assists						SMALLINT,
    game_turnovers						SMALLINT,
    game_steals							SMALLINT,
    game_blocks							SMALLINT,
    game_blocks_received				SMALLINT,
    game_fouls_personal					SMALLINT,
    game_fouls_on						SMALLINT,
    game_points							SMALLINT,
    game_points_second_chance			SMALLINT,

    field_goal_pct			DECIMAL,
    three_pointers_pct		DECIMAL,
    two_pointers_pct		DECIMAL,
    free_throws_pct			DECIMAL,
    total_rebound			SMALLINT
)


-- Composite indexes
CREATE INDEX playerstat_table_index1 ON playerstat_table(player_name, game_season, game_type);
CREATE INDEX playerstat_table_index2 ON playerstat_table(player_name, game_type);