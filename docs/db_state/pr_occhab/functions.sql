CREATE FUNCTION pr_occhab.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $$
        --Function that return the default nomenclature id with wanteds nomenclature type, organism id
        --Return -1 if nothing matche with given parameters
          DECLARE
            thenomenclatureid integer;
          BEGIN
              SELECT INTO thenomenclatureid id_nomenclature
              FROM (
              	SELECT
              	  n.id_nomenclature,
              	  CASE
        	        WHEN n.id_organism = myidorganism THEN 1
                    ELSE 0
                  END prio_organisme
                FROM
                  pr_occhab.defaults_nomenclatures_value n
                JOIN
                  utilisateurs.bib_organismes o ON o.id_organisme = n.id_organism
                WHERE
                  mnemonique_type = mytype
                  AND (n.id_organism = myidorganism OR o.nom_organisme = 'ALL')
              ) AS defaults_nomenclatures_value
              ORDER BY prio_organisme DESC LIMIT 1;
             
            RETURN thenomenclatureid;
          END;
        $$;

ALTER FUNCTION pr_occhab.get_default_nomenclature_value(mytype character varying, myidorganism integer) OWNER TO geonatadmin;

SET default_tablespace = '';

SET default_table_access_method = heap;

CREATE TABLE pr_occhab.cor_station_observer (
    id_cor_station_observer integer NOT NULL,
    id_station integer NOT NULL,
    id_role integer NOT NULL
);

ALTER TABLE pr_occhab.cor_station_observer OWNER TO geonatadmin;

CREATE SEQUENCE pr_occhab.cor_station_observer_id_cor_station_observer_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occhab.cor_station_observer_id_cor_station_observer_seq OWNER TO geonatadmin;

ALTER SEQUENCE pr_occhab.cor_station_observer_id_cor_station_observer_seq OWNED BY pr_occhab.cor_station_observer.id_cor_station_observer;

CREATE TABLE pr_occhab.defaults_nomenclatures_value (
    mnemonique_type character varying(255) NOT NULL,
    id_organism integer DEFAULT 0 NOT NULL,
    id_nomenclature integer NOT NULL
);

ALTER TABLE pr_occhab.defaults_nomenclatures_value OWNER TO geonatadmin;

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

ALTER TABLE pr_occhab.t_habitats OWNER TO geonatadmin;

CREATE SEQUENCE pr_occhab.t_habitats_id_habitat_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occhab.t_habitats_id_habitat_seq OWNER TO geonatadmin;

ALTER SEQUENCE pr_occhab.t_habitats_id_habitat_seq OWNED BY pr_occhab.t_habitats.id_habitat;

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

ALTER TABLE pr_occhab.t_stations OWNER TO geonatadmin;

COMMENT ON COLUMN pr_occhab.t_stations.id_nomenclature_exposure IS 'Correspondance nomenclature INPN = exposition d''un terrain, REF_NOMENCLATURES = EXPOSITION';

COMMENT ON COLUMN pr_occhab.t_stations.id_nomenclature_area_surface_calculation IS 'Correspondance nomenclature INPN = exposition d''un terrain, REF_NOMENCLATURES = EXPOSITION';

CREATE SEQUENCE pr_occhab.t_stations_id_station_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occhab.t_stations_id_station_seq OWNER TO geonatadmin;

ALTER SEQUENCE pr_occhab.t_stations_id_station_seq OWNED BY pr_occhab.t_stations.id_station;

CREATE VIEW pr_occhab.v_export_sinp AS
SELECT
    NULL::integer AS id_station,
    NULL::integer AS id_dataset,
    NULL::integer AS id_digitiser,
    NULL::uuid AS uuid_station,
    NULL::uuid AS uuid_jdd,
    NULL::text AS date_debut,
    NULL::text AS date_fin,
    NULL::text AS observateurs,
    NULL::character varying(255) AS methode_calcul_surface,
    NULL::bigint AS surface,
    NULL::text AS geometry,
    NULL::text AS geojson,
    NULL::public.geometry(Geometry,2154) AS geom_local,
    NULL::character varying(255) AS nature_objet_geo,
    NULL::uuid AS uuid_habitat,
    NULL::integer AS altitude_min,
    NULL::integer AS altitude_max,
    NULL::character varying(255) AS exposition,
    NULL::character varying(500) AS nom_cite,
    NULL::integer AS cd_hab,
    NULL::character varying(500) AS precision_technique;

ALTER VIEW pr_occhab.v_export_sinp OWNER TO geonatadmin;

ALTER TABLE ONLY pr_occhab.cor_station_observer ALTER COLUMN id_cor_station_observer SET DEFAULT nextval('pr_occhab.cor_station_observer_id_cor_station_observer_seq'::regclass);

ALTER TABLE ONLY pr_occhab.t_habitats ALTER COLUMN id_habitat SET DEFAULT nextval('pr_occhab.t_habitats_id_habitat_seq'::regclass);

ALTER TABLE ONLY pr_occhab.t_stations ALTER COLUMN id_station SET DEFAULT nextval('pr_occhab.t_stations_id_station_seq'::regclass);

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

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_area_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_area_surface_calculation, 'METHOD_CALCUL_SURFACE'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_exposure CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exposure, 'EXPOSITION'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_geographic_object CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geographic_object, 'NAT_OBJ_GEO'::character varying)) NOT VALID;

ALTER TABLE pr_occhab.t_stations
    ADD CONSTRAINT check_t_stations_type_mosaique_habitat CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_mosaique_habitat, 'MOSAIQUE_HAB'::character varying)) NOT VALID;

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT pk_cor_station_observer PRIMARY KEY (id_cor_station_observer);

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT pk_pr_occhab_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism);

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT pk_t_habitats PRIMARY KEY (id_habitat);

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT pk_t_stations PRIMARY KEY (id_station);

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT unique_cor_station_observer UNIQUE (id_station, id_role);

CREATE INDEX i_t_habitats_cd_hab ON pr_occhab.t_habitats USING btree (cd_hab);

CREATE INDEX i_t_habitats_id_station ON pr_occhab.t_habitats USING btree (id_station);

CREATE INDEX i_t_stations_id_dataset ON pr_occhab.t_stations USING btree (id_dataset);

CREATE INDEX i_t_stations_occhab_geom_4326 ON pr_occhab.t_stations USING gist (geom_4326);

CREATE OR REPLACE VIEW pr_occhab.v_export_sinp AS
 SELECT s.id_station,
    s.id_dataset,
    s.id_digitiser,
    s.unique_id_sinp_station AS uuid_station,
    ds.unique_dataset_id AS uuid_jdd,
    to_char(s.date_min, 'DD/MM/YYYY'::text) AS date_debut,
    to_char(s.date_max, 'DD/MM/YYYY'::text) AS date_fin,
    COALESCE(string_agg(DISTINCT (((r.nom_role)::text || ' '::text) || (r.prenom_role)::text), ','::text), (s.observers_txt)::text) AS observateurs,
    nom2.cd_nomenclature AS methode_calcul_surface,
    s.area AS surface,
    public.st_astext(s.geom_4326) AS geometry,
    public.st_asgeojson(s.geom_4326) AS geojson,
    s.geom_local,
    nom3.cd_nomenclature AS nature_objet_geo,
    h.unique_id_sinp_hab AS uuid_habitat,
    s.altitude_min,
    s.altitude_max,
    nom5.cd_nomenclature AS exposition,
    h.nom_cite,
    h.cd_hab,
    h.technical_precision AS precision_technique
   FROM (((((((((pr_occhab.t_stations s
     JOIN pr_occhab.t_habitats h ON ((h.id_station = s.id_station)))
     JOIN gn_meta.t_datasets ds ON ((ds.id_dataset = s.id_dataset)))
     LEFT JOIN pr_occhab.cor_station_observer cso ON ((cso.id_station = s.id_station)))
     LEFT JOIN utilisateurs.t_roles r ON ((r.id_role = cso.id_role)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom1 ON ((nom1.id_nomenclature = ds.id_nomenclature_data_origin)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom2 ON ((nom2.id_nomenclature = s.id_nomenclature_area_surface_calculation)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom3 ON ((nom3.id_nomenclature = s.id_nomenclature_geographic_object)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom4 ON ((nom4.id_nomenclature = h.id_nomenclature_collection_technique)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom5 ON ((nom5.id_nomenclature = s.id_nomenclature_exposure)))
  GROUP BY s.id_station, s.id_dataset, ds.unique_dataset_id, nom2.cd_nomenclature, h.technical_precision, h.cd_hab, h.nom_cite, nom3.cd_nomenclature, h.unique_id_sinp_hab, nom5.cd_nomenclature;

CREATE TRIGGER tri_calculate_geom_local BEFORE INSERT OR UPDATE ON pr_occhab.t_stations FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

CREATE TRIGGER tri_log_changes_delete_t_habitats_occhab AFTER DELETE ON pr_occhab.t_habitats FOR EACH ROW WHEN ((old.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_delete_t_stations_occhab AFTER DELETE ON pr_occhab.t_stations FOR EACH ROW WHEN ((old.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_insert_t_habitats_occhab AFTER INSERT OR UPDATE ON pr_occhab.t_habitats FOR EACH ROW WHEN ((new.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_insert_t_stations_occhab AFTER INSERT OR UPDATE ON pr_occhab.t_stations FOR EACH ROW WHEN ((new.id_import IS NULL)) EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT fk_cor_station_observer_id_station FOREIGN KEY (id_station) REFERENCES pr_occhab.t_stations(id_station) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY pr_occhab.cor_station_observer
    ADD CONSTRAINT fk_cor_station_observer_t_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occhab_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occhab_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occhab_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

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

ALTER TABLE ONLY pr_occhab.t_habitats
    ADD CONSTRAINT t_habitats_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT t_stations_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occhab.t_stations
    ADD CONSTRAINT t_stations_id_nomenclature_type_mosaique_habitat_fkey FOREIGN KEY (id_nomenclature_type_mosaique_habitat) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

