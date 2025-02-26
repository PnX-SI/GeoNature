
CREATE TABLE gn_commons.t_validations (
    id_validation integer NOT NULL,
    uuid_attached_row uuid NOT NULL,
    id_nomenclature_valid_status integer,
    validation_auto boolean DEFAULT true NOT NULL,
    id_validator integer,
    validation_comment text,
    validation_date timestamp without time zone DEFAULT now()
);

COMMENT ON COLUMN gn_commons.t_validations.uuid_attached_row IS 'Uuid de l''enregistrement validé';

COMMENT ON COLUMN gn_commons.t_validations.id_nomenclature_valid_status IS 'Correspondance nomenclature INPN = statut_valid (101)';

COMMENT ON COLUMN gn_commons.t_validations.id_validator IS 'Fk vers l''id_role (utilisateurs.t_roles) du validateur';

COMMENT ON COLUMN gn_commons.t_validations.validation_comment IS 'Commentaire concernant la validation';

COMMENT ON COLUMN gn_commons.t_validations.validation_date IS 'Date de la validation';

CREATE SEQUENCE gn_commons.t_validations_id_validation_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.t_validations_id_validation_seq OWNED BY gn_commons.t_validations.id_validation;

ALTER TABLE gn_commons.t_validations
    ADD CONSTRAINT check_t_validations_valid_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_valid_status, 'STATUT_VALID'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_commons.t_validations
    ADD CONSTRAINT pk_t_validations PRIMARY KEY (id_validation);

CREATE INDEX i_t_validations_uuid_attached_row ON gn_commons.t_validations USING btree (uuid_attached_row);

CREATE TRIGGER tri_insert_synthese_update_validation_status AFTER INSERT ON gn_commons.t_validations FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_update_synthese_validation_status();

ALTER TABLE ONLY gn_commons.t_validations
    ADD CONSTRAINT fk_t_validations_t_roles FOREIGN KEY (id_validator) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_commons.t_validations
    ADD CONSTRAINT fk_t_validations_valid_status FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

