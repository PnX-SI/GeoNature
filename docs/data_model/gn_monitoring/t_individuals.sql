

CREATE TABLE gn_monitoring.t_individuals (
    id_individual integer NOT NULL,
    uuid_individual uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    individual_name character varying(255) NOT NULL,
    cd_nom integer NOT NULL,
    id_nomenclature_sex integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('SEXE'::character varying),
    active boolean DEFAULT true,
    comment text,
    id_digitiser integer NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);

CREATE SEQUENCE gn_monitoring.t_individuals_id_individual_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_individuals_id_individual_seq OWNED BY gn_monitoring.t_individuals.id_individual;

ALTER TABLE ONLY gn_monitoring.t_individuals
    ADD CONSTRAINT t_individuals_pkey PRIMARY KEY (id_individual);

CREATE TRIGGER trg_update_t_observations_cd_nom AFTER UPDATE ON gn_monitoring.t_individuals FOR EACH ROW EXECUTE FUNCTION gn_monitoring.fct_trg_t_individuals_t_observations_cd_nom();

ALTER TABLE ONLY gn_monitoring.t_individuals
    ADD CONSTRAINT t_individuals_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom);

ALTER TABLE ONLY gn_monitoring.t_individuals
    ADD CONSTRAINT t_individuals_id_digitiser_fkey FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role);

ALTER TABLE ONLY gn_monitoring.t_individuals
    ADD CONSTRAINT t_individuals_id_nomenclature_sex_fkey FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);


