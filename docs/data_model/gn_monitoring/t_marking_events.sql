

CREATE TABLE gn_monitoring.t_marking_events (
    id_marking integer NOT NULL,
    uuid_marking uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_module integer,
    id_individual integer NOT NULL,
    marking_date date NOT NULL,
    id_operator integer NOT NULL,
    id_base_marking_site integer,
    id_nomenclature_marking_type integer NOT NULL,
    marking_location character varying(255),
    marking_code character varying(255),
    marking_details text,
    data jsonb,
    id_digitiser integer NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);

CREATE SEQUENCE gn_monitoring.t_marking_events_id_marking_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_marking_events_id_marking_seq OWNED BY gn_monitoring.t_marking_events.id_marking;

ALTER TABLE gn_monitoring.t_marking_events
    ADD CONSTRAINT check_marking_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_marking_type, 'TYP_MARQUAGE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_monitoring.t_marking_events
    ADD CONSTRAINT t_marking_events_pkey PRIMARY KEY (id_marking);

ALTER TABLE ONLY gn_monitoring.t_marking_events
    ADD CONSTRAINT t_marking_events_id_base_marking_site_fkey FOREIGN KEY (id_base_marking_site) REFERENCES gn_monitoring.t_base_sites(id_base_site);

ALTER TABLE ONLY gn_monitoring.t_marking_events
    ADD CONSTRAINT t_marking_events_id_digitiser_fkey FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role);

ALTER TABLE ONLY gn_monitoring.t_marking_events
    ADD CONSTRAINT t_marking_events_id_individual_fkey FOREIGN KEY (id_individual) REFERENCES gn_monitoring.t_individuals(id_individual) ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_marking_events
    ADD CONSTRAINT t_marking_events_id_module_fkey FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_marking_events
    ADD CONSTRAINT t_marking_events_id_nomenclature_marking_type_fkey FOREIGN KEY (id_nomenclature_marking_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_monitoring.t_marking_events
    ADD CONSTRAINT t_marking_events_id_operator_fkey FOREIGN KEY (id_operator) REFERENCES utilisateurs.t_roles(id_role);


