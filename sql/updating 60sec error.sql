/*
==========================
CHECKING
==========================
*/

SELECT * FROM playerstat_table WHERE RIGHT(game_minutes, 2) = '60'
SELECT COUNT(*) FROM playerstat_table WHERE RIGHT(game_minutes, 2) = '60'

/*
==========================
TESTING QUERY
==========================
*/
SELECT
    game_minutes AS before,
    (total_seconds / 60)::TEXT
    || ':' ||
    LPAD((total_seconds % 60)::TEXT, 2, '0') AS after
FROM (
    SELECT
        game_minutes,
        split_part(game_minutes, ':', 1)::INT * 60 + split_part(game_minutes, ':', 2)::INT AS total_seconds
    FROM playerstat_table
) t
WHERE split_part(game_minutes, ':', 2)::INT >= 60;

/*
==========================
UPDATTING
==========================
*/

UPDATE playerstat_table
SET game_minutes =
    (total_seconds / 60)::TEXT
    || ':' ||
    LPAD((total_seconds % 60)::TEXT, 2, '0')
FROM (
    SELECT
        id,  -- replace with your PK
        (split_part(game_minutes, ':', 1)::INT * 60 + split_part(game_minutes, ':', 2)::INT) AS total_seconds
    FROM playerstat_table
) t
WHERE playerstat_table.id = t.id
  AND split_part(game_minutes, ':', 2)::INT >= 60;