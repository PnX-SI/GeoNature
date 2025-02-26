
CREATE TABLE gn_commons.t_history_actions (
    id_history_action integer NOT NULL,
    id_table_location integer NOT NULL,
    uuid_attached_row uuid NOT NULL,
    operation_type character(1),
    operation_date timestamp without time zone,
    table_content json,
    CONSTRAINT check_t_history_actions_operation_type CHECK ((operation_type = ANY (ARRAY['I'::bpchar, 'U'::bpchar, 'D'::bpchar])))
);

COMMENT ON COLUMN gn_commons.t_history_actions.id_table_location IS 'FK vers la table où se trouve l''enregistrement tracé';

COMMENT ON COLUMN gn_commons.t_history_actions.uuid_attached_row IS 'Uuid de l''enregistrement tracé';

COMMENT ON COLUMN gn_commons.t_history_actions.operation_type IS 'Type d''événement tracé (Create, Update, Delete)';

COMMENT ON COLUMN gn_commons.t_history_actions.operation_date IS 'Date de l''événement';

COMMENT ON COLUMN gn_commons.t_history_actions.table_content IS 'Contenu au format json de l''événement tracé. On enregistre le NEW pour CREATE et UPDATE. LE OLD (ou rien?) pour le DELETE.';

CREATE SEQUENCE gn_commons.t_history_actions_id_history_action_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.t_history_actions_id_history_action_seq OWNED BY gn_commons.t_history_actions.id_history_action;

ALTER TABLE ONLY gn_commons.t_history_actions
    ADD CONSTRAINT pk_t_history_actions PRIMARY KEY (id_history_action);

ALTER TABLE ONLY gn_commons.t_history_actions
    ADD CONSTRAINT fk_t_history_actions_bib_tables_location FOREIGN KEY (id_table_location) REFERENCES gn_commons.bib_tables_location(id_table_location) ON UPDATE CASCADE;

