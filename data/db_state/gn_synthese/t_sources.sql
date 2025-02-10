
CREATE TABLE gn_synthese.t_sources (
    id_source integer NOT NULL,
    name_source character varying(255) NOT NULL,
    desc_source text,
    entity_source_pk_field character varying(255),
    url_source character varying(255),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    id_module integer
);

CREATE SEQUENCE gn_synthese.t_sources_id_source_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_synthese.t_sources_id_source_seq OWNED BY gn_synthese.t_sources.id_source;

ALTER TABLE ONLY gn_synthese.t_sources
    ADD CONSTRAINT pk_t_sources PRIMARY KEY (id_source);

ALTER TABLE ONLY gn_synthese.t_sources
    ADD CONSTRAINT unique_name_source UNIQUE (name_source);

CREATE UNIQUE INDEX i_unique_t_sources_name_source ON gn_synthese.t_sources USING btree (name_source);

CREATE TRIGGER tri_meta_dates_t_sources BEFORE INSERT OR UPDATE ON gn_synthese.t_sources FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY gn_synthese.t_sources
    ADD CONSTRAINT t_sources_id_module_fkey FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module);

