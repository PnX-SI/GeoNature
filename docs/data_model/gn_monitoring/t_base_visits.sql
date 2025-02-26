
CREATE TABLE gn_monitoring.t_base_visits (
    id_base_visit integer NOT NULL,
    id_base_site integer,
    id_dataset integer NOT NULL,
    id_module integer NOT NULL,
    id_digitiser integer,
    visit_date_min date NOT NULL,
    visit_date_max date,
    id_nomenclature_tech_collect_campanule integer DEFAULT ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS'::character varying, '133'::character varying),
    id_nomenclature_grp_typ integer DEFAULT ref_nomenclatures.get_id_nomenclature('TYP_GRP'::character varying, 'PASS'::character varying),
    comments text,
    uuid_base_visit uuid DEFAULT public.uuid_generate_v4(),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    observers_txt text
);

CREATE SEQUENCE gn_monitoring.t_base_visits_id_base_visit_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_base_visits_id_base_visit_seq OWNED BY gn_monitoring.t_base_visits.id_base_visit;

ALTER TABLE gn_monitoring.t_base_visits
    ADD CONSTRAINT check_t_base_visits_id_nomenclature_grp_typ CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ, 'TYP_GRP'::character varying)) NOT VALID;

ALTER TABLE gn_monitoring.t_base_visits
    ADD CONSTRAINT check_t_base_visits_id_nomenclature_tech_collect_campanule CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_tech_collect_campanule, 'TECHNIQUE_OBS'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT pk_t_base_visits PRIMARY KEY (id_base_visit);

CREATE INDEX idx_t_base_visits_fk_bs_id ON gn_monitoring.t_base_visits USING btree (id_base_site);

CREATE TRIGGER tri_log_changes AFTER INSERT OR DELETE OR UPDATE ON gn_monitoring.t_base_visits FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_meta_dates_change_t_base_visits BEFORE INSERT OR UPDATE ON gn_monitoring.t_base_visits FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_visite_date_max BEFORE INSERT OR UPDATE OF visit_date_min ON gn_monitoring.t_base_visits FOR EACH ROW EXECUTE FUNCTION gn_monitoring.fct_trg_visite_date_max();

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites(id_base_site) ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_nomenclature_grp_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_nomenclature_tech_collect_campanule FOREIGN KEY (id_nomenclature_tech_collect_campanule) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

