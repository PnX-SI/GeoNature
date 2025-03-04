
CREATE TABLE gn_synthese.synthese (
    id_synthese integer NOT NULL,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    id_source integer NOT NULL,
    id_module integer,
    entity_source_pk_value character varying,
    id_dataset integer,
    id_nomenclature_geo_object_nature integer DEFAULT gn_synthese.get_default_nomenclature_value('NAT_OBJ_GEO'::character varying),
    id_nomenclature_grp_typ integer DEFAULT gn_synthese.get_default_nomenclature_value('TYP_GRP'::character varying),
    grp_method character varying(255),
    id_nomenclature_obs_technique integer DEFAULT gn_synthese.get_default_nomenclature_value('METH_OBS'::character varying),
    id_nomenclature_bio_status integer DEFAULT gn_synthese.get_default_nomenclature_value('STATUT_BIO'::character varying),
    id_nomenclature_bio_condition integer DEFAULT gn_synthese.get_default_nomenclature_value('ETA_BIO'::character varying),
    id_nomenclature_naturalness integer DEFAULT gn_synthese.get_default_nomenclature_value('NATURALITE'::character varying),
    id_nomenclature_exist_proof integer DEFAULT gn_synthese.get_default_nomenclature_value('PREUVE_EXIST'::character varying),
    id_nomenclature_valid_status integer DEFAULT gn_synthese.get_default_nomenclature_value('STATUT_VALID'::character varying),
    id_nomenclature_diffusion_level integer,
    id_nomenclature_life_stage integer DEFAULT gn_synthese.get_default_nomenclature_value('STADE_VIE'::character varying),
    id_nomenclature_sex integer DEFAULT gn_synthese.get_default_nomenclature_value('SEXE'::character varying),
    id_nomenclature_obj_count integer DEFAULT gn_synthese.get_default_nomenclature_value('OBJ_DENBR'::character varying),
    id_nomenclature_type_count integer DEFAULT gn_synthese.get_default_nomenclature_value('TYP_DENBR'::character varying),
    id_nomenclature_sensitivity integer,
    id_nomenclature_observation_status integer DEFAULT gn_synthese.get_default_nomenclature_value('STATUT_OBS'::character varying),
    id_nomenclature_blurring integer DEFAULT gn_synthese.get_default_nomenclature_value('DEE_FLOU'::character varying),
    id_nomenclature_source_status integer DEFAULT gn_synthese.get_default_nomenclature_value('STATUT_SOURCE'::character varying),
    id_nomenclature_info_geo_type integer DEFAULT gn_synthese.get_default_nomenclature_value('TYP_INF_GEO'::character varying),
    id_nomenclature_behaviour integer DEFAULT gn_synthese.get_default_nomenclature_value('OCC_COMPORTEMENT'::character varying),
    id_nomenclature_biogeo_status integer DEFAULT gn_synthese.get_default_nomenclature_value('STAT_BIOGEO'::character varying),
    reference_biblio character varying(5000),
    count_min integer,
    count_max integer,
    cd_nom integer,
    cd_hab integer,
    nom_cite character varying(1000) NOT NULL,
    meta_v_taxref character varying(50) DEFAULT gn_commons.get_default_parameter('taxref_version'::text, NULL::integer),
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    altitude_min integer,
    altitude_max integer,
    depth_min integer,
    depth_max integer,
    place_name character varying(500),
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Point,4326),
    the_geom_local public.geometry(Geometry,2154),
    "precision" integer,
    id_area_attachment integer,
    date_min timestamp without time zone NOT NULL,
    date_max timestamp without time zone NOT NULL,
    validator character varying(1000),
    validation_comment text,
    observers character varying(1000),
    determiner character varying(1000),
    id_digitiser integer,
    id_nomenclature_determination_method integer DEFAULT gn_synthese.get_default_nomenclature_value('METH_DETERMIN'::character varying),
    comment_context text,
    comment_description text,
    additional_data jsonb,
    meta_validation_date timestamp without time zone,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    last_action character(1),
    id_import integer,
    CONSTRAINT check_synthese_altitude_max CHECK ((altitude_max >= altitude_min)),
    CONSTRAINT check_synthese_count_max CHECK ((count_max >= count_min)),
    CONSTRAINT check_synthese_date_max CHECK ((date_max >= date_min)),
    CONSTRAINT check_synthese_depth_max CHECK ((depth_max >= depth_min)),
    CONSTRAINT enforce_dims_the_geom_4326 CHECK ((public.st_ndims(the_geom_4326) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_point CHECK ((public.st_ndims(the_geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(the_geom_point) = 'POINT'::text) OR (the_geom_point IS NULL))),
    CONSTRAINT enforce_srid_the_geom_4326 CHECK ((public.st_srid(the_geom_4326) = 4326)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = 2154)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 4326))
);

COMMENT ON TABLE gn_synthese.synthese IS 'Table de synthèse destinée à recevoir les données de tous les protocoles. Pour consultation uniquement';

COMMENT ON COLUMN gn_synthese.synthese.id_source IS 'Permet d''identifier la localisation de l''enregistrement correspondant dans les schémas et tables de la base';

COMMENT ON COLUMN gn_synthese.synthese.id_module IS 'Permet d''identifier le module qui a permis la création de l''enregistrement. Ce champ est en lien avec utilisateurs.t_applications et permet de gérer le CRUVED grace à la table utilisateurs.cor_app_privileges';

COMMENT ON COLUMN gn_synthese.synthese.id_nomenclature_obs_technique IS 'Correspondance champs standard occtax = obsTechnique. En raison d''un changement de nom, le code nomenclature associé reste ''METH_OBS'' ';

COMMENT ON COLUMN gn_synthese.synthese.id_area_attachment IS 'Id area du rattachement géographique - cas des observations sans géométrie précise';

COMMENT ON COLUMN gn_synthese.synthese.comment_context IS 'Commentaire du releve (ou regroupement)';

COMMENT ON COLUMN gn_synthese.synthese.comment_description IS 'Commentaire de l''occurrence';

CREATE SEQUENCE gn_synthese.synthese_id_synthese_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_synthese.synthese_id_synthese_seq OWNED BY gn_synthese.synthese.id_synthese;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_condition, 'ETA_BIO'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_status, 'STATUT_BIO'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_biogeo_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_biogeo_status, 'STAT_BIOGEO'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_blurring, 'DEE_FLOU'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_diffusion_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_diffusion_level, 'NIV_PRECIS'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exist_proof, 'PREUVE_EXIST'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geo_object_nature, 'NAT_OBJ_GEO'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_info_geo_type_id_area_attachment CHECK ((NOT (((ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type))::text = '2'::text) AND (id_area_attachment IS NULL)))) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_life_stage, 'STADE_VIE'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_naturalness, 'NATURALITE'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obj_count, 'OBJ_DENBR'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique, 'METH_OBS'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_observation_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_observation_status, 'STATUT_OBS'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_sex CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sex, 'SEXE'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status, 'STATUT_SOURCE'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_typ_grp CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ, 'TYP_GRP'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_count, 'TYP_DENBR'::character varying)) NOT VALID;

ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_valid_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_valid_status, 'STATUT_VALID'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT unique_id_sinp_unique UNIQUE (unique_id_sinp);

CREATE INDEX i_synthese_altitude_max ON gn_synthese.synthese USING btree (altitude_max);

CREATE INDEX i_synthese_altitude_min ON gn_synthese.synthese USING btree (altitude_min);

CREATE INDEX i_synthese_cd_nom ON gn_synthese.synthese USING btree (cd_nom);

CREATE INDEX i_synthese_date_max ON gn_synthese.synthese USING btree (date_max DESC);

CREATE INDEX i_synthese_date_min ON gn_synthese.synthese USING btree (date_min DESC);

CREATE INDEX i_synthese_id_dataset ON gn_synthese.synthese USING btree (id_dataset);

CREATE INDEX i_synthese_t_sources ON gn_synthese.synthese USING btree (id_source);

CREATE INDEX i_synthese_the_geom_4326 ON gn_synthese.synthese USING gist (the_geom_4326);

CREATE INDEX i_synthese_the_geom_local ON gn_synthese.synthese USING gist (the_geom_local);

CREATE INDEX i_synthese_the_geom_point ON gn_synthese.synthese USING gist (the_geom_point);

CREATE INDEX synthese_id_import_idx ON gn_synthese.synthese USING btree (id_import);

CREATE INDEX synthese_observers_idx ON gn_synthese.synthese USING btree (observers);

CREATE TRIGGER tri_insert_calculate_sensitivity AFTER INSERT ON gn_synthese.synthese REFERENCING NEW TABLE AS new FOR EACH STATEMENT EXECUTE FUNCTION gn_synthese.fct_tri_calculate_sensitivity_on_each_statement();

CREATE TRIGGER tri_insert_cor_area_synthese AFTER INSERT ON gn_synthese.synthese REFERENCING NEW TABLE AS new FOR EACH STATEMENT EXECUTE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement();

CREATE TRIGGER tri_log_delete_synthese AFTER DELETE ON gn_synthese.synthese REFERENCING OLD TABLE AS old_table FOR EACH STATEMENT EXECUTE FUNCTION gn_synthese.fct_tri_log_delete_on_synthese();

CREATE TRIGGER tri_meta_dates_change_synthese BEFORE INSERT OR UPDATE ON gn_synthese.synthese FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_update_calculate_sensitivity BEFORE UPDATE OF date_min, date_max, cd_nom, the_geom_local, id_nomenclature_bio_status, id_nomenclature_behaviour ON gn_synthese.synthese FOR EACH ROW EXECUTE FUNCTION gn_synthese.fct_tri_update_sensitivity_on_each_row();

CREATE TRIGGER tri_update_cor_area_synthese AFTER UPDATE OF the_geom_local, the_geom_4326 ON gn_synthese.synthese FOR EACH ROW EXECUTE FUNCTION gn_synthese.fct_trig_update_in_cor_area_synthese();

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_area_attachment FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_bio_condition FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_bio_status FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_biogeo_status FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_blurring FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_determination_method FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_diffusion_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_exist_proof FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_id_nomenclature_grp_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_info_geo_type FOREIGN KEY (id_nomenclature_info_geo_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_life_stage FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_obj_count FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_observation_status FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_sensitivity FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_sex FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_type_count FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_valid_status FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_source FOREIGN KEY (id_source) REFERENCES gn_synthese.t_sources(id_source) ON UPDATE CASCADE;

