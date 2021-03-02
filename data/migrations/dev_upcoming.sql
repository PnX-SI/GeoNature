-- Upcoming updates from devs to merge into migration files

BEGIN;

/* CREATE TYPE IF NOT EXISTS data_actions AS ENUM ('I', 'U', 'D'); */
DROP TABLE IF EXISTS gn_synthese.t_log_synthese
;

CREATE TABLE gn_synthese.t_log_synthese
(
    id_synthese      INT PRIMARY KEY,
    unique_id_sinp   UUID,
    last_action      CHAR(1),
    meta_action_date TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
)
;

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
      , now()              AS meta_action_date;
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
COMMIT;

