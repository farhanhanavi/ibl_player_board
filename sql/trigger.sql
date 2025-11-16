/* Adjusted Loc */

ALTER TABLE shot_table ADD COLUMN IF NOT EXISTS adjusted_x_halfcourt_left DOUBLE PRECISION;
ALTER TABLE shot_table ADD COLUMN IF NOT EXISTS adjusted_y_halfcourt_left DOUBLE PRECISION;
ALTER TABLE shot_table ADD COLUMN IF NOT EXISTS marker TEXT;
ALTER TABLE shot_table ADD COLUMN IF NOT EXISTS color TEXT;

UPDATE shot_table
SET
    color 						= CASE WHEN shot_point = 2 THEN 'blue' ELSE 'orange' END,
    marker 						= CASE WHEN shot_result = 1 THEN 'o' ELSE 'x'END,
	adjusted_x_halfcourt_left 	= CASE WHEN adjusted_x_loc < 14 THEN adjusted_x_loc ELSE 28 - adjusted_x_loc END,
    adjusted_y_halfcourt_left 	= CASE WHEN adjusted_x_loc < 14 THEN adjusted_y_loc ELSE 15 - adjusted_y_loc END;


CREATE OR REPLACE FUNCTION set_shot_derived_fields()
RETURNS trigger AS
$$
BEGIN
    -- color: based on shot_point
    NEW.color := CASE WHEN NEW.shot_point = 2 THEN 'blue' ELSE 'orange' END;

    -- marker: based on shot_result
    NEW.marker := CASE WHEN NEW.shot_result = 1 THEN 'o' ELSE 'x' END;

    -- adjusted_x_halfcourt_left: mirror X to left halfcourt
    NEW.adjusted_x_halfcourt_left := CASE WHEN NEW.adjusted_x_loc < 14 THEN NEW.adjusted_x_loc ELSE (28 - NEW.adjusted_x_loc) END;

    -- adjusted_y_halfcourt_left: mirror Y when we mirror X
    NEW.adjusted_y_halfcourt_left := CASE WHEN NEW.adjusted_x_loc < 14 THEN NEW.adjusted_y_loc ELSE (15 - NEW.adjusted_y_loc) END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_set_shot_derived_fields ON shots;

CREATE TRIGGER trg_set_shot_derived_fields
BEFORE INSERT OR UPDATE OF shot_point, shot_result, adjusted_x_loc, adjusted_y_loc
ON shot_table
FOR EACH ROW
EXECUTE FUNCTION set_shot_derived_fields();
















/* See trigger */
SELECT tgname, tgtype::int, tgrelid::regclass
FROM pg_trigger
WHERE tgrelid = 'shot_table'::regclass
  AND NOT tgisinternal;





