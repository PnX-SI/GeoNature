-- Upcoming updates from devs to merge into migration files

BEGIN;

CREATE TYPE LOG_SYNTHESE_ACTIONS AS ENUM ('I', 'U', 'D');
-- DROP TABLE IF EXISTS gn_synthese.t_log_synthese
-- ;

CREATE TABLE gn_synthese.t_log_synthese
(
    id_synthese      INT PRIMARY KEY,
    unique_id_sinp   UUID,
    last_action      LOG_SYNTHESE_ACTIONS,
    meta_last_action_date TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_log_delete_on_synthese() RETURNS TRIGGER AS
$BODY$
DECLARE
BEGIN
    -- log id/uuid of deleted datas into specific log table
    INSERT INTO gn_synthese.t_log_synthese
    SELECT
        old.id_synthese    AS id_synthese
      , old.unique_id_sinp AS unique_id_sinp
      , 'D'                AS last_action
      , now()              AS meta_last_action_date
      ON CONFLICT (id_synthese)
      DO UPDATE SET last_action = 'D', meta_action_date = now();
    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql COST 100
;

CREATE TRIGGER tri_log_delete_synthese
    AFTER DELETE
    ON gn_synthese.synthese
    FOR EACH ROW
EXECUTE PROCEDURE gn_synthese.fct_trig_log_delete_on_synthese()
;

CREATE VIEW gn_synthese.v_log_synthese AS
(
WITH
    t1 AS (SELECT
               id_synthese
             , unique_id_sinp
             , last_action
             , meta_last_action_date
               FROM
                   gn_synthese.t_log_synthese
           UNION
           SELECT
               id_synthese
             , unique_id_sinp
             , last_action
             , coalesce(meta_update_date, meta_create_date)
               FROM
                   gn_synthese.synthese)
SELECT *
    FROM
        t1
    ORDER BY
        meta_last_action_date DESC)
;


COMMIT;

