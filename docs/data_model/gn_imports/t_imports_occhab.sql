
CREATE TABLE gn_imports.t_imports_occhab (
    id_import integer NOT NULL,
    line_no integer NOT NULL,
    station_valid boolean DEFAULT false,
    habitat_valid boolean DEFAULT false,
    id_station integer,
    id_station_source character varying,
    src_unique_id_sinp_station character varying,
    unique_id_sinp_station uuid,
    src_unique_dataset_id character varying,
    unique_dataset_id uuid,
    id_dataset integer,
    src_date_min character varying,
    date_min timestamp without time zone,
    src_date_max character varying,
    date_max timestamp without time zone,
    observers_txt character varying,
    station_name character varying,
    src_id_nomenclature_exposure character varying,
    id_nomenclature_exposure integer,
    src_altitude_min character varying,
    altitude_min integer,
    src_altitude_max character varying,
    altitude_max integer,
    src_depth_min character varying,
    depth_min integer,
    src_depth_max character varying,
    depth_max integer,
    src_area character varying,
    area integer,
    src_id_nomenclature_area_surface_calculation character varying,
    id_nomenclature_area_surface_calculation integer,
    comment character varying,
    "src_WKT" character varying,
    src_latitude character varying,
    src_longitude character varying,
    geom_local public.geometry,
    geom_4326 public.geometry(Geometry,4326),
    src_precision character varying,
    "precision" integer,
    src_id_digitiser character varying,
    id_digitiser integer,
    src_numerization_scale character varying,
    numerization_scale character varying(15),
    src_id_nomenclature_geographic_object character varying,
    id_nomenclature_geographic_object integer,
    station_line_no integer,
    src_id_habitat character varying,
    id_habitat integer,
    src_unique_id_sinp_hab character varying,
    unique_id_sinp_hab uuid,
    src_cd_hab character varying,
    cd_hab integer,
    nom_cite character varying,
    src_id_nomenclature_determination_type character varying,
    id_nomenclature_determination_type integer,
    determiner character varying,
    src_id_nomenclature_collection_technique character varying,
    id_nomenclature_collection_technique integer,
    src_recovery_percentage character varying,
    recovery_percentage integer,
    src_id_nomenclature_abundance character varying,
    id_nomenclature_abundance integer,
    technical_precision character varying,
    src_unique_id_sinp_grp_occtax character varying,
    unique_id_sinp_grp_occtax uuid,
    src_unique_id_sinp_grp_phyto character varying,
    unique_id_sinp_grp_phyto uuid,
    src_id_nomenclature_sensitivity character varying,
    id_nomenclature_sensitivity integer,
    src_id_nomenclature_community_interest character varying,
    id_nomenclature_community_interest integer,
    src_id_nomenclature_type_mosaique_habitat character varying,
    id_nomenclature_type_mosaique_habitat integer
);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_pkey PRIMARY KEY (id_import, line_no);

CREATE INDEX idx_t_imports_occhab_geom_4326 ON gn_imports.t_imports_occhab USING gist (geom_4326);

CREATE INDEX idx_t_imports_occhab_geom_local ON gn_imports.t_imports_occhab USING gist (geom_local);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_import_fkey FOREIGN KEY (id_import) REFERENCES gn_imports.t_imports(id_import) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_import_station_line_no_fkey FOREIGN KEY (id_import, station_line_no) REFERENCES gn_imports.t_imports_occhab(id_import, line_no);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_abundance_fkey FOREIGN KEY (id_nomenclature_abundance) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_area_surface_calculation_fkey FOREIGN KEY (id_nomenclature_area_surface_calculation) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_collection_technique_fkey FOREIGN KEY (id_nomenclature_collection_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_community_interest_fkey FOREIGN KEY (id_nomenclature_community_interest) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_determination_type_fkey FOREIGN KEY (id_nomenclature_determination_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_exposure_fkey FOREIGN KEY (id_nomenclature_exposure) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_geographic_object_fkey FOREIGN KEY (id_nomenclature_geographic_object) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

ALTER TABLE ONLY gn_imports.t_imports_occhab
    ADD CONSTRAINT t_imports_occhab_id_nomenclature_type_mosaique_habitat_fkey FOREIGN KEY (id_nomenclature_type_mosaique_habitat) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

