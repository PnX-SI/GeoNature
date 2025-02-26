
CREATE TABLE pr_occhab.t_habitats (
    id_habitat integer NOT NULL,
    id_station integer NOT NULL,
    unique_id_sinp_hab uuid DEFAULT public.uuid_generate_v4(),
    cd_hab integer NOT NULL,
    nom_cite character varying(500) NOT NULL,
    id_nomenclature_determination_type integer,
    determiner character varying(500),
    id_nomenclature_collection_technique integer DEFAULT pr_occhab.get_default_nomenclature_value('TECHNIQUE_COLLECT_HAB'::character varying) NOT NULL,
    recovery_percentage numeric,
    id_nomenclature_abundance integer,
    technical_precision character varying(500),
    unique_id_sinp_grp_occtax uuid,
    unique_id_sinp_grp_phyto uuid,
    id_nomenclature_sensitvity integer,
    id_nomenclature_community_interest integer,
    id_import integer
);

CREATE SEQUENCE pr_occhab.t_habitats_id_habitat_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occhab.t_habitats_id_habitat_seq OWNED BY pr_occhab.t_habitats.id_habitat;

ALTER TABLE pr_occhab.t_habitats
    ADD CONSTRAINT check_t_habitats_abondance CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_abundance, 'ABONDANCE_HAB'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
    ADD CONSTRAINT check_t_habitats_collection_techn CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_collection_technique, 'TECHNIQUE_COLLECT_HAB'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
    ADD CONSTRAINT check_t_habitats_community_interest CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_community_interest, 'HAB_INTERET_COM'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
    ADD CONSTRAINT check_t_habitats_determini_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_type, 'DETERMINATION_TYP_HAB'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_habitats
    ADD CONSTRAINT check_t_habitats_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitvity, 'SENSIBILITE'::character varying)) NOT VALID;

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT pk_t_habitats PRIMARY KEY (id_habitat);

CREATE INDEX i_t_habitats_cd_hab ON pr_occhab.t_habitats USING btree (cd_hab);

CREATE INDEX i_t_habitats_id_station ON pr_occhab.t_habitats USING btree (id_station);

CREATE INDEX occhab_habitat_id_import_idx ON pr_occhab.t_habitats USING btree (id_import);

CREATE TRIGGER tri_log_changes_delete_t_habitats_occhab AFTER DELETE ON pr_occhab.t_habitats FOR EACH ROW WHEN ((old.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_insert_t_habitats_occhab AFTER INSERT OR UPDATE ON pr_occhab.t_habitats FOR EACH ROW WHEN ((new.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT fk_t_habitats_id_nomenclature_abundance FOREIGN KEY (id_nomenclature_abundance) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT fk_t_habitats_id_nomenclature_collection_technique FOREIGN KEY (id_nomenclature_collection_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT fk_t_habitats_id_nomenclature_community_interest FOREIGN KEY (id_nomenclature_community_interest) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT fk_t_habitats_id_nomenclature_determination_type FOREIGN KEY (id_nomenclature_determination_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT fk_t_habitats_id_nomenclature_sensitvity FOREIGN KEY (id_nomenclature_sensitvity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT fk_t_habitats_id_station FOREIGN KEY (id_station) REFERENCES pr_occhab.t_stations(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT t_habitats_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE;

