
CREATE TABLE gn_monitoring.t_sites_groups (
    id_sites_group integer NOT NULL,
    sites_group_name character varying(255),
    sites_group_code character varying(255),
    sites_group_description text,
    uuid_sites_group uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    comments text,
    data jsonb,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    id_digitiser integer,
    geom public.geometry(Geometry,4326),
    geom_local public.geometry(Geometry,2154),
    altitude_min integer,
    altitude_max integer,
    CONSTRAINT enforce_srid_geom CHECK ((public.st_srid(geom) = 4326))
);

CREATE SEQUENCE gn_monitoring.t_sites_groups_id_sites_group_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_sites_groups_id_sites_group_seq OWNED BY gn_monitoring.t_sites_groups.id_sites_group;

ALTER TABLE ONLY gn_monitoring.t_sites_groups
    ADD CONSTRAINT pk_t_sites_groups PRIMARY KEY (id_sites_group);

CREATE INDEX idx_t_sites_groups_geom ON gn_monitoring.t_sites_groups USING gist (geom);

CREATE TRIGGER tri_calculate_geom_local BEFORE INSERT OR UPDATE ON gn_monitoring.t_sites_groups FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom', 'geom_local');

CREATE TRIGGER tri_insert_calculate_altitude BEFORE INSERT ON gn_monitoring.t_sites_groups FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom');

CREATE TRIGGER tri_meta_dates_change_t_sites_groups BEFORE INSERT OR UPDATE ON gn_monitoring.t_sites_groups FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_t_sites_groups_calculate_alt BEFORE INSERT OR UPDATE ON gn_monitoring.t_sites_groups FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom');

CREATE TRIGGER tri_update_calculate_altitude BEFORE UPDATE OF geom_local, geom ON gn_monitoring.t_sites_groups FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom');

ALTER TABLE ONLY gn_monitoring.t_sites_groups
    ADD CONSTRAINT fk_t_sites_groups_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

