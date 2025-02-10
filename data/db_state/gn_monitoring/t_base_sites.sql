
CREATE TABLE gn_monitoring.t_base_sites (
    id_base_site integer NOT NULL,
    id_inventor integer,
    id_digitiser integer,
    base_site_name character varying(255) NOT NULL,
    base_site_description text,
    base_site_code character varying(25) DEFAULT NULL::character varying,
    first_use_date date,
    geom public.geometry(Geometry,4326) NOT NULL,
    geom_local public.geometry(Geometry,2154),
    altitude_min integer,
    altitude_max integer,
    uuid_base_site uuid DEFAULT public.uuid_generate_v4(),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    CONSTRAINT enforce_dims_geom CHECK ((public.st_ndims(geom) = 2)),
    CONSTRAINT enforce_srid_geom CHECK ((public.st_srid(geom) = 4326))
);

CREATE SEQUENCE gn_monitoring.t_base_sites_id_base_site_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_base_sites_id_base_site_seq OWNED BY gn_monitoring.t_base_sites.id_base_site;

ALTER TABLE ONLY gn_monitoring.t_base_sites
    ADD CONSTRAINT pk_t_base_sites PRIMARY KEY (id_base_site);

CREATE INDEX idx_t_base_sites_geom ON gn_monitoring.t_base_sites USING gist (geom);

CREATE INDEX idx_t_base_sites_id_inventor ON gn_monitoring.t_base_sites USING btree (id_inventor);

CREATE TRIGGER trg_cor_site_area AFTER INSERT OR UPDATE OF geom ON gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION gn_monitoring.fct_trg_cor_site_area();

CREATE TRIGGER tri_calculate_geom_local BEFORE INSERT OR UPDATE ON gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom', 'geom_local');

CREATE TRIGGER tri_insert_calculate_altitude BEFORE INSERT ON gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom');

CREATE TRIGGER tri_log_changes AFTER INSERT OR DELETE OR UPDATE ON gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_meta_dates_change_t_base_sites BEFORE INSERT OR UPDATE ON gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_t_base_sites_calculate_alt BEFORE INSERT OR UPDATE ON gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom');

CREATE TRIGGER tri_update_calculate_altitude BEFORE UPDATE OF geom_local, geom ON gn_monitoring.t_base_sites FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom');

ALTER TABLE ONLY gn_monitoring.t_base_sites
    ADD CONSTRAINT fk_t_base_sites_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_base_sites
    ADD CONSTRAINT fk_t_base_sites_id_inventor FOREIGN KEY (id_inventor) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

