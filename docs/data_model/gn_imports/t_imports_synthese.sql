
CREATE TABLE gn_imports.t_imports_synthese (
    id_import integer NOT NULL,
    line_no integer NOT NULL,
    valid boolean,
    "src_WKT" character varying,
    src_codecommune character varying,
    src_codedepartement character varying,
    src_codemaille character varying,
    src_hour_max character varying,
    src_hour_min character varying,
    src_latitude character varying,
    src_longitude character varying,
    src_unique_id_sinp character varying,
    src_unique_id_sinp_grp character varying,
    src_id_nomenclature_geo_object_nature character varying,
    src_id_nomenclature_grp_typ character varying,
    src_id_nomenclature_obs_technique character varying,
    src_id_nomenclature_bio_status character varying,
    src_id_nomenclature_bio_condition character varying,
    src_id_nomenclature_naturalness character varying,
    src_id_nomenclature_valid_status character varying,
    src_id_nomenclature_exist_proof character varying,
    src_id_nomenclature_diffusion_level character varying,
    src_id_nomenclature_life_stage character varying,
    src_id_nomenclature_sex character varying,
    src_id_nomenclature_obj_count character varying,
    src_id_nomenclature_type_count character varying,
    src_id_nomenclature_sensitivity character varying,
    src_id_nomenclature_observation_status character varying,
    src_id_nomenclature_blurring character varying,
    src_id_nomenclature_source_status character varying,
    src_id_nomenclature_info_geo_type character varying,
    src_id_nomenclature_behaviour character varying,
    src_id_nomenclature_biogeo_status character varying,
    src_id_nomenclature_determination_method character varying,
    src_count_min character varying,
    src_count_max character varying,
    src_cd_nom character varying,
    src_cd_hab character varying,
    src_altitude_min character varying,
    src_altitude_max character varying,
    src_depth_min character varying,
    src_depth_max character varying,
    src_precision character varying,
    src_id_area_attachment character varying,
    src_date_min character varying,
    src_date_max character varying,
    src_id_digitiser character varying,
    src_meta_validation_date character varying,
    src_meta_create_date character varying,
    src_meta_update_date character varying,
    extra_fields public.hstore,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    entity_source_pk_value character varying,
    grp_method character varying(255),
    id_nomenclature_geo_object_nature integer,
    id_nomenclature_grp_typ integer,
    id_nomenclature_obs_technique integer,
    id_nomenclature_bio_status integer,
    id_nomenclature_bio_condition integer,
    id_nomenclature_naturalness integer,
    id_nomenclature_valid_status integer,
    id_nomenclature_exist_proof integer,
    id_nomenclature_diffusion_level integer,
    id_nomenclature_life_stage integer,
    id_nomenclature_sex integer,
    id_nomenclature_obj_count integer,
    id_nomenclature_type_count integer,
    id_nomenclature_sensitivity integer,
    id_nomenclature_observation_status integer,
    id_nomenclature_blurring integer,
    id_nomenclature_source_status integer,
    id_nomenclature_info_geo_type integer,
    id_nomenclature_behaviour integer,
    id_nomenclature_biogeo_status integer,
    id_nomenclature_determination_method integer,
    reference_biblio character varying,
    count_min integer,
    count_max integer,
    cd_nom integer,
    cd_hab integer,
    nom_cite character varying,
    meta_v_taxref character varying,
    digital_proof text,
    non_digital_proof text,
    altitude_min integer,
    altitude_max integer,
    depth_min integer,
    depth_max integer,
    place_name character varying,
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Geometry,4326),
    the_geom_local public.geometry,
    "precision" integer,
    date_min timestamp without time zone,
    date_max timestamp without time zone,
    validator character varying,
    validation_comment character varying,
    observers character varying,
    determiner character varying,
    id_digitiser integer,
    comment_context text,
    comment_description text,
    additional_data jsonb,
    meta_validation_date timestamp without time zone,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    id_area_attachment integer,
    src_unique_dataset_id character varying,
    unique_dataset_id uuid,
    id_dataset integer
);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_pkey PRIMARY KEY (id_import, line_no);

CREATE INDEX idx_t_imports_synthese_the_geom_4326 ON gn_imports.t_imports_synthese USING gist (the_geom_4326);

CREATE INDEX idx_t_imports_synthese_the_geom_local ON gn_imports.t_imports_synthese USING gist (the_geom_local);

CREATE INDEX idx_t_imports_synthese_the_geom_point ON gn_imports.t_imports_synthese USING gist (the_geom_point);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_area_attachment_fkey FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas(id_area);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_digitiser_fkey FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_behaviour_fkey FOREIGN KEY (id_nomenclature_behaviour) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_bio_condition_fkey FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_bio_status_fkey FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_biogeo_status_fkey FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_blurring_fkey FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_determination_method_fkey FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_diffusion_level_fkey FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_exist_proof_fkey FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_geo_object_nature_fkey FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_grp_typ_fkey FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_info_geo_type_fkey FOREIGN KEY (id_nomenclature_info_geo_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_life_stage_fkey FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_naturalness_fkey FOREIGN KEY (id_nomenclature_naturalness) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_obj_count_fkey FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_obs_technique_fkey FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_observation_status_fkey FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_sex_fkey FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_source_status_fkey FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_type_count_fkey FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_synthese
    ADD CONSTRAINT t_imports_synthese_id_nomenclature_valid_status_fkey FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

