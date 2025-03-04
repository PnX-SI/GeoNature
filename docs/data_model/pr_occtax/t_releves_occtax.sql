
CREATE TABLE pr_occtax.t_releves_occtax (
    id_releve_occtax bigint NOT NULL,
    unique_id_sinp_grp uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_dataset integer NOT NULL,
    id_digitiser integer,
    observers_txt character varying(500),
    id_nomenclature_tech_collect_campanule integer DEFAULT pr_occtax.get_default_nomenclature_value('TECHNIQUE_OBS'::character varying),
    id_nomenclature_grp_typ integer DEFAULT pr_occtax.get_default_nomenclature_value('TYP_GRP'::character varying) NOT NULL,
    grp_method character varying(255),
    date_min timestamp without time zone DEFAULT now() NOT NULL,
    date_max timestamp without time zone DEFAULT now() NOT NULL,
    hour_min time without time zone,
    hour_max time without time zone,
    cd_hab integer,
    altitude_min integer,
    altitude_max integer,
    depth_min integer,
    depth_max integer,
    place_name character varying(500),
    meta_device_entry character varying(20),
    comment text,
    geom_local public.geometry(Geometry,2154),
    geom_4326 public.geometry(Geometry,4326),
    id_nomenclature_geo_object_nature integer DEFAULT pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'::character varying),
    "precision" integer,
    additional_fields jsonb,
    id_module integer NOT NULL,
    CONSTRAINT check_t_releves_occtax_altitude_max CHECK ((altitude_max >= altitude_min)),
    CONSTRAINT check_t_releves_occtax_date_max CHECK ((date_max >= date_min)),
    CONSTRAINT check_t_releves_occtax_depth CHECK ((depth_max >= depth_min)),
    CONSTRAINT check_t_releves_occtax_hour_max CHECK (((hour_min <= hour_max) OR (date_min < date_max))),
    CONSTRAINT enforce_dims_geom_4326 CHECK ((public.st_ndims(geom_4326) = 2)),
    CONSTRAINT enforce_dims_geom_local CHECK ((public.st_ndims(geom_local) = 2)),
    CONSTRAINT enforce_srid_geom_4326 CHECK ((public.st_srid(geom_4326) = 4326)),
    CONSTRAINT enforce_srid_geom_local CHECK ((public.st_srid(geom_local) = 2154))
);

COMMENT ON COLUMN pr_occtax.t_releves_occtax.id_nomenclature_tech_collect_campanule IS 'Correspondance nomenclature CAMPANULE = technique_obs';

COMMENT ON COLUMN pr_occtax.t_releves_occtax.id_nomenclature_grp_typ IS 'Correspondance nomenclature INPN = Type de regroupement';

CREATE SEQUENCE pr_occtax.t_releves_occtax_id_releve_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pr_occtax.t_releves_occtax_id_releve_occtax_seq OWNED BY pr_occtax.t_releves_occtax.id_releve_occtax;

ALTER TABLE pr_occtax.t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geo_object_nature, 'NAT_OBJ_GEO'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_tech_collect_campanule, 'TECHNIQUE_OBS'::character varying)) NOT VALID;

ALTER TABLE pr_occtax.t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_regroupement_typ CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ, 'TYP_GRP'::character varying)) NOT VALID;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT pk_t_releves_occtax PRIMARY KEY (id_releve_occtax);

CREATE INDEX i_t_releves_occtax_date_max ON pr_occtax.t_releves_occtax USING btree (date_max);

CREATE INDEX i_t_releves_occtax_geom_4326 ON pr_occtax.t_releves_occtax USING gist (geom_4326);

CREATE INDEX i_t_releves_occtax_geom_local ON pr_occtax.t_releves_occtax USING gist (geom_local);

CREATE INDEX i_t_releves_occtax_id_dataset ON pr_occtax.t_releves_occtax USING btree (id_dataset);

CREATE INDEX i_t_releves_occtax_id_nomenclature_grp_typ ON pr_occtax.t_releves_occtax USING btree (id_nomenclature_grp_typ);

CREATE INDEX i_t_releves_occtax_id_nomenclature_tech_collect_campanule ON pr_occtax.t_releves_occtax USING btree (id_nomenclature_tech_collect_campanule);

CREATE TRIGGER tri_calculate_altitude BEFORE INSERT OR UPDATE OF geom_4326 ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_alt_minmax('geom_4326');

CREATE TRIGGER tri_calculate_geom_local BEFORE INSERT OR UPDATE OF geom_4326 ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

CREATE TRIGGER tri_delete_synthese_t_releve_occtax AFTER DELETE ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_delete_releve();

CREATE TRIGGER tri_log_changes_t_releves_occtax AFTER INSERT OR DELETE OR UPDATE ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_update_synthese_t_releve_occtax AFTER UPDATE ON pr_occtax.t_releves_occtax FOR EACH ROW EXECUTE FUNCTION pr_occtax.fct_tri_synthese_update_releve();

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_id_nomenclature_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_obs_technique_campanule FOREIGN KEY (id_nomenclature_tech_collect_campanule) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_regroupement_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_t_roles FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

