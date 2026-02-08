CREATE TABLE raw_data (
    id          SERIAL PRIMARY KEY,
    match_id    TEXT NOT NULL,
    match_json  JSONB
);