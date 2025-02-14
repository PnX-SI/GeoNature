
CREATE TABLE gn_monitoring.t_module_complements (
    id_module integer NOT NULL,
    uuid_module_complement uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_list_observer integer,
    id_list_taxonomy integer,
    b_synthese boolean DEFAULT true,
    taxonomy_display_field_name character varying DEFAULT 'nom_vern,lb_nom'::character varying,
    b_draw_sites_group boolean,
    data jsonb
);

CREATE SEQUENCE gn_monitoring.t_module_complements_id_module_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_module_complements_id_module_seq OWNED BY gn_monitoring.t_module_complements.id_module;

ALTER TABLE ONLY gn_monitoring.t_module_complements
    ADD CONSTRAINT pk_t_module_complements PRIMARY KEY (id_module);

ALTER TABLE ONLY gn_monitoring.t_module_complements
    ADD CONSTRAINT fk_t_module_complements_id_list_observer FOREIGN KEY (id_list_observer) REFERENCES utilisateurs.t_listes(id_liste) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_module_complements
    ADD CONSTRAINT fk_t_module_complements_id_list_taxonomy FOREIGN KEY (id_list_taxonomy) REFERENCES taxonomie.bib_listes(id_liste) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_module_complements
    ADD CONSTRAINT fk_t_module_complements_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

