INSERT INTO shot_table (
    player_name, match_id, match_date, venue,
    team_name, home_team, away_team,
    quarter, shot_point, shot_type, shot_result,
    x_loc, y_loc, game_type,
    adjusted_x_loc, adjusted_y_loc, halfcourt_xloc, halfcourt_yloc
)
VALUES (
    'Trigger Test',            -- player_name
    999001,                    -- match_id (some unique number)
    '2025-01-01',              -- match_date
    'Trigger Arena',           -- venue
    'Test Team',               -- team_name
    'Test Home',               -- home_team
    'Test Away',               -- away_team
    1,                         -- quarter
    3,                         -- shot_point (⇒ color = orange)
    'Jump Shot',               -- shot_type
    1,                         -- shot_result (⇒ marker = 'o')
    10.0,                      -- x_loc (raw, whatever)
    7.0,                       -- y_loc (raw, whatever)
    'regular',                 -- game_type
    20.0,                      -- adjusted_x_loc (right half ⇒ will mirror)
    5.0,                       -- adjusted_y_loc
    0.0,                       -- halfcourt_xloc (not relevant here)
    0.0                        -- halfcourt_yloc
);

SELECT
    player_name,
    shot_point,
    shot_result,
    color,
    marker,
    adjusted_x_loc,
    adjusted_y_loc,
    adjusted_x_halfcourt_left,
    adjusted_y_halfcourt_left
FROM shot_table
WHERE match_id = 999001;

DELETE FROM shot_table
WHERE match_id = 999001;


