
CREATE TABLE pr_occtax.t_occurrences_occtax (
    id_occurrence_occtax bigint NOT NULL,
    unique_id_occurence_occtax uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_releve_occtax bigint NOT NULL,
    id_nomenclature_obs_technique integer DEFAULT pr_occtax.get_default_nomenclature_value('METH_OBS'::character varying) NOT NULL,
    id_nomenclature_bio_condition integer DEFAULT pr_occtax.get_default_nomenclature_value('ETA_BIO'::character varying) NOT NULL,
    id_nomenclature_bio_status integer DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_BIO'::character varying),
    id_nomenclature_naturalness integer DEFAULT pr_occtax.get_default_nomenclature_value('NATURALITE'::character varying),
    id_nomenclature_exist_proof integer DEFAULT pr_occtax.get_default_nomenclature_value('PREUVE_EXIST'::character varying),
    id_nomenclature_diffusion_level integer,
    id_nomenclature_observation_status integer DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_OBS'::character varying),
    id_nomenclature_blurring integer DEFAULT pr_occtax.get_default_nomenclature_value('DEE_FLOU'::character varying),
    id_nomenclature_source_status integer DEFAULT pr_occtax.get_default_nomenclature_value('STATUT_SOURCE'::character varying),
    id_nomenclature_behaviour integer DEFAULT pr_occtax.get_default_nomenclature_value('OCC_COMPORTEMENT'::character varying),
    determiner character varying(255),
    id_nomenclature_determination_method integer DEFAULT pr_occtax.get_default_nomenclature_value('METH_DETERMIN'::character varying),
    cd_nom integer,
    nom_cite character varying(255) NOT NULL,
    meta_v_taxref character varying(50) DEFAULT 'SELECT gn_commons.get_default_parameter(''taxref_version'')'::character varying,
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    comment character varying,
    additional_fields jsonb
);

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_obs_technique IS 'Correspondance champs standard occtax = obsTechnique. En raison d''un changement de nom, le code nomenclature associé reste ''METH_OBS'' ';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_bio_condition IS 'Correspondance nomenclature INPN = etat_bio';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_bio_status IS 'Correspondance nomenclature INPN = statut_bio';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_naturalness IS 'Correspondance nomenclature INPN = naturalite';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_exist_proof IS 'Correspondance nomenclature INPN = preuve_exist';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_diffusion_level IS 'Correspondance nomenclature INPN = niv_precis';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_observation_status IS 'Correspondance nomenclature INPN = statut_obs';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_blurring IS 'Correspondance nomenclature INPN = dee_flou';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_source_status IS 'Correspondance nomenclature INPN = statut_source: id = 19';

COMMENT ON COLUMN pr_occtax.t_occurrences_occtax.id_nomenclature_determination_method IS 'Correspondance nomenclature GEONATURE = meth_determin';

CREATE SEQUENCE pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq OWNED BY pr_occtax.t_occurrences_occtax.id_occurrence_occtax;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_accur_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_diffusion_level, 'NIV_PRECIS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_behaviour CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_behaviour, 'OCC_COMPORTEMENT'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_condition, 'ETA_BIO'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_status, 'STATUT_BIO'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_blurring, 'DEE_FLOU'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_determination_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_method, 'METH_DETERMIN'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exist_proof, 'PREUVE_EXIST'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_naturalness, 'NATURALITE'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique, 'METH_OBS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_obs_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_observation_status, 'STATUT_OBS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status, 'STATUT_SOURCE'::character varying)) NOT VALID;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT pk_t_occurrences_occtax PRIMARY KEY (id_occurrence_occtax);

CREATE INDEX i_t_occurrences_occtax_cd_nom ON pr_occtax.t_occurrences_occtax USING btree (cd_nom);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_bio_condition ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_bio_condition);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_bio_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_bio_status);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_blurring ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_blurring);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_determination_method ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_determination_method);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_exist_proof ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_exist_proof);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_naturalness ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_naturalness);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_obs_technique ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_obs_technique);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_observation_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_observation_status);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_source_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_source_status);

CREATE INDEX i_t_occurrences_occtax_id_releve_occtax ON pr_occtax.t_occurrences_occtax USING btree (id_releve_occtax);

CREATE TRIGGER tri_delete_synthese_t_occurrence_occtax AFTER DELETE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_occ();

CREATE TRIGGER tri_delete_t_occurrence_occtax AFTER DELETE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_delete_occ();

CREATE TRIGGER tri_log_changes_t_occurrences_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_update_synthese_t_occurrence_occtax AFTER UPDATE ON pr_occtax.t_occurrences_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_occ();

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_behaviour FOREIGN KEY (id_nomenclature_behaviour) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_bio_condition FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_bio_status FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_blurring FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_determination_method FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_diffusion_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_exist_proof FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_naturalness FOREIGN KEY (id_nomenclature_naturalness) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_obs_meth FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_observation_status FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_t_releves_occtax FOREIGN KEY (id_releve_occtax) REFERENCES pr_occtax.t_releves_occtax(id_releve_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occtax.t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_taxref FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

