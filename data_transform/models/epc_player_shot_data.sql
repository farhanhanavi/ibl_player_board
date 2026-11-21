{{
    config(
            materialized = 'table',
            alias        = 'epc_player_shot_data'
        )
}}

/*
  epc_player_shot_data
  --------------------
  Layer  : staging
  Spec   : specs/epc_metrics_spec.yml -> shot_zones, staging_columns.epc_player_shot_data
  Source : raw_matchdata -> data -> 'tm' -> '<n>' -> 'shot' (array)
           + epc_player_level_data (player_id via match_id + team_name + pno, all entries)
  Grain  : one row per field-goal attempt (free throws are not in shot[])

  Court  : feed x / y are a 0-100 grid. x runs along the 28 m length, y along the 15 m width.
           Every shot is mirrored onto the LEFT basket (nearest hoop), in metres:
             court_x_m = 0 at the baseline .. 14 at half court
             court_y_m = 0 .. 15 sideline to sideline (rotated 180 deg, so left / right is kept)
           Basket centre = (1.575, 7.5).

  Zones  : one shot_zone per attempt. 2pt / 3pt comes from the feed (shot_type), never from
           distance; geometry only splits shots inside each group. First match wins:
             Corner 3        : 3pt and court_x_m <= 2.99 (where the straight corner line meets the arc)
             ATB             : any other 3pt (above the break)
             Restricted Area : 2pt within 1.25 m of the basket centre
             Paint Area      : other 2pt inside the key (5.8 m from the baseline, 4.9 m wide)
             Midrange        : every other 2pt (outside the paint)
  Feeds  : epc_player_shot_season_data, shot chart
*/

WITH base AS (

    SELECT
        r.match_id,
        r.game_season,
        r.data              AS j
    FROM
        {{ source('source_raw_matchdata', 'raw_matchdata') }} r
        -- public.raw_matchdata r
    WHERE
        r.game_season = 'elite_pro_championship_2026'

),
sides AS (

    SELECT
        base.match_id,
        base.game_season,
        t.key               AS team_no,
        t.value             AS tm
    FROM
        base
    CROSS JOIN
        LATERAL jsonb_each(base.j -> 'tm') AS t (key, value)

),
shots AS (

    SELECT
        s.match_id,
        s.game_season,
        s.tm ->> 'code'                         AS team_abr,
        s.tm ->> 'name'                         AS team_name,
        (sh ->> 'pno')::INT                     AS pno,
        pl.player_id,
        pl.player_name,
        (sh ->> 'actionNumber')::INT            AS action_number,
        (sh ->> 'per')::INT                     AS period,
        sh ->> 'perType'                        AS period_type,
        sh ->> 'actionType'                     AS shot_type,
        sh ->> 'subType'                        AS shot_subtype,
        (sh ->> 'x')::NUMERIC                   AS x,
        (sh ->> 'y')::NUMERIC                   AS y,
        ((sh ->> 'r')::INT = 1)                 AS is_made
    FROM
        sides s
    CROSS JOIN
        LATERAL jsonb_array_elements(COALESCE(s.tm -> 'shot', '[]'::JSONB)) AS sh
    LEFT JOIN
        {{ ref('epc_player_level_data') }} pl
        -- dbt_schema.epc_player_level_data pl
        ON  pl.match_id  = s.match_id
        AND pl.team_name = s.tm ->> 'name'
        AND pl.pno       = (sh ->> 'pno')::INT

),
halfcourt AS (

    SELECT
        s.*,
        ROUND(CASE WHEN s.x < 50 THEN s.x * 0.28 ELSE (100 - s.x) * 0.28 END, 3)       AS court_x_m,
        ROUND(CASE WHEN s.x < 50 THEN s.y * 0.15 ELSE (100 - s.y) * 0.15 END, 3)       AS court_y_m
    FROM
        shots s

),
geo AS (

    SELECT
        h.*,
        ROUND(SQRT(POWER(h.court_x_m - 1.575, 2) + POWER(h.court_y_m - 7.5, 2)), 3)    AS shot_distance_m,
        ROUND(ABS(h.court_y_m - 7.5), 3)                                               AS lateral_m
    FROM
        halfcourt h

)

SELECT
    g.*,
    CASE
        WHEN g.shot_type = '3pt' AND g.court_x_m <= 2.99               THEN 'Corner 3'
        WHEN g.shot_type = '3pt'                                       THEN 'ATB'
        WHEN g.shot_distance_m <= 1.25                                 THEN 'Restricted Area'
        WHEN g.court_x_m <= 5.8 AND g.lateral_m <= 2.45                THEN 'Paint Area'
        ELSE                                                                'Midrange'
    END                                                                AS shot_zone
FROM
    geo g
ORDER BY
    g.match_id, g.action_number