
CREATE TABLE pr_occtax.cor_counting_occtax (
    id_counting_occtax bigint NOT NULL,
    unique_id_sinp_occtax uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_occurrence_occtax bigint NOT NULL,
    id_nomenclature_life_stage integer DEFAULT pr_occtax.get_default_nomenclature_value('STADE_VIE'::character varying) NOT NULL,
    id_nomenclature_sex integer DEFAULT pr_occtax.get_default_nomenclature_value('SEXE'::character varying) NOT NULL,
    id_nomenclature_obj_count integer DEFAULT pr_occtax.get_default_nomenclature_value('OBJ_DENBR'::character varying) NOT NULL,
    id_nomenclature_type_count integer DEFAULT pr_occtax.get_default_nomenclature_value('TYP_DENBR'::character varying),
    count_min integer,
    count_max integer,
    additional_fields jsonb,
    CONSTRAINT check_cor_counting_occtax_count_max CHECK (((count_max >= count_min) AND (count_max >= 0))),
    CONSTRAINT check_cor_counting_occtax_count_min CHECK ((count_min >= 0))
);

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_life_stage IS 'Correspondance nomenclature INPN = stade_vie (10)';

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_sex IS 'Correspondance nomenclature INPN = sexe (9)';

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_obj_count IS 'Correspondance nomenclature INPN = obj_denbr (6)';

COMMENT ON COLUMN pr_occtax.cor_counting_occtax.id_nomenclature_type_count IS 'Correspondance nomenclature INPN = typ_denbr (21)';

CREATE SEQUENCE pr_occtax.cor_counting_occtax_id_counting_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occtax.cor_counting_occtax_id_counting_occtax_seq OWNED BY pr_occtax.cor_counting_occtax.id_counting_occtax;

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_life_stage, 'STADE_VIE'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obj_count, 'OBJ_DENBR'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_sexe CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sex, 'SEXE'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_count, 'TYP_DENBR'::character varying)) NOT VALID;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT pk_cor_counting_occtax_occtax PRIMARY KEY (id_counting_occtax);

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT unique_id_sinp_occtax_unique UNIQUE (unique_id_sinp_occtax);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_life_stage ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_life_stage);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_obj_count ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_obj_count);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_sex ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_sex);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_type_count ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_type_count);

CREATE INDEX i_cor_counting_occtax_id_occurrence_occtax ON pr_occtax.cor_counting_occtax USING btree (id_occurrence_occtax);

CREATE TRIGGER tri_delete_cor_counting_occtax AFTER DELETE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_delete_counting();

CREATE TRIGGER tri_delete_synthese_cor_counting_occtax AFTER DELETE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_counting();

CREATE TRIGGER tri_insert_default_validation_status AFTER INSERT ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_add_default_validation_status();

CREATE TRIGGER tri_insert_synthese_cor_counting_occtax AFTER INSERT ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_insert_counting();

CREATE TRIGGER tri_log_changes_cor_counting_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_update_synthese_cor_counting_occtax AFTER UPDATE ON pr_occtax.cor_counting_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_counting();

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_life_stage FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_obj_count FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_sexe FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_typ_count FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT fk_cor_stage_number_id_taxon FOREIGN KEY (id_occurrence_occtax) REFERENCES pr_occtax.t_occurrences_occtax(id_occurrence_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

