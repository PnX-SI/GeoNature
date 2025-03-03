
CREATE TABLE pr_occhab.t_stations (
    id_station integer NOT NULL,
    unique_id_sinp_station uuid DEFAULT public.uuid_generate_v4(),
    id_dataset integer NOT NULL,
    date_min timestamp without time zone DEFAULT now() NOT NULL,
    date_max timestamp without time zone DEFAULT now() NOT NULL,
    observers_txt character varying(500),
    station_name character varying(1000),
    id_nomenclature_exposure integer,
    altitude_min integer,
    altitude_max integer,
    depth_min integer,
    depth_max integer,
    area bigint,
    id_nomenclature_area_surface_calculation integer,
    comment text,
    geom_local public.geometry(Geometry,2154),
    geom_4326 public.geometry(Geometry,4326) NOT NULL,
    "precision" integer,
    id_digitiser integer,
    numerization_scale character varying(15),
    id_nomenclature_geographic_object integer DEFAULT pr_occhab.get_default_nomenclature_value('NAT_OBJ_GEO'::character varying) NOT NULL,
    id_station_source character varying,
    id_import integer,
    id_nomenclature_type_mosaique_habitat integer,
    CONSTRAINT enforce_dims_geom_4326 CHECK ((public.st_ndims(geom_4326) = 2)),
    CONSTRAINT enforce_dims_geom_local CHECK ((public.st_ndims(geom_local) = 2)),
    CONSTRAINT enforce_srid_geom_4326 CHECK ((public.st_srid(geom_4326) = 4326)),
    CONSTRAINT enforce_srid_geom_local CHECK ((public.st_srid(geom_local) = 2154)),
    CONSTRAINT t_stations_altitude_max CHECK ((altitude_max >= altitude_min)),
    CONSTRAINT t_stations_date_max CHECK ((date_min <= date_max))
);

COMMENT ON COLUMN pr_occhab.t_stations.id_nomenclature_exposure IS 'Correspondance nomenclature INPN = exposition d''un terrain, REF_NOMENCLATURES = EXPOSITION';

COMMENT ON COLUMN pr_occhab.t_stations.id_nomenclature_area_surface_calculation IS 'Correspondance nomenclature INPN = exposition d''un terrain, REF_NOMENCLATURES = EXPOSITION';

CREATE SEQUENCE pr_occhab.t_stations_id_station_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occhab.t_stations_id_station_seq OWNED BY pr_occhab.t_stations.id_station;

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_area_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_area_surface_calculation, 'METHOD_CALCUL_SURFACE'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_exposure CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exposure, 'EXPOSITION'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_geographic_object CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geographic_object, 'NAT_OBJ_GEO'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_type_mosaique_habitat CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_mosaique_habitat, 'MOSAIQUE_HAB'::character varying)) NOT VALID;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT pk_t_stations PRIMARY KEY (id_station);

CREATE INDEX i_t_stations_id_dataset ON pr_occhab.t_stations USING btree (id_dataset);

CREATE INDEX i_t_stations_occhab_geom_4326 ON pr_occhab.t_stations USING gist (geom_4326);

CREATE INDEX occhab_station_id_import_idx ON pr_occhab.t_stations USING btree (id_import);

CREATE TRIGGER tri_calculate_geom_local BEFORE INSERT OR UPDATE ON pr_occhab.t_stations FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

CREATE TRIGGER tri_log_changes_delete_t_stations_occhab AFTER DELETE ON pr_occhab.t_stations FOR EACH ROW WHEN ((old.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_insert_t_stations_occhab AFTER INSERT OR UPDATE ON pr_occhab.t_stations FOR EACH ROW WHEN ((new.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT fk_t_releves_occtax_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT fk_t_stations_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT fk_t_stations_id_nomenclature_area_surface_calculation FOREIGN KEY (id_nomenclature_area_surface_calculation) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT fk_t_stations_id_nomenclature_exposure FOREIGN KEY (id_nomenclature_exposure) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT fk_t_stations_id_nomenclature_geographic_object FOREIGN KEY (id_nomenclature_geographic_object) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT t_stations_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT t_stations_id_nomenclature_type_mosaique_habitat_fkey FOREIGN KEY (id_nomenclature_type_mosaique_habitat) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

