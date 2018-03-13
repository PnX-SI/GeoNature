SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA gn_synthese;

SET search_path = gn_synthese, pg_catalog;

SET default_with_oids = false;


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION get_default_nomenclature_value(myidtype integer, myidorganism integer DEFAULT 0, myregne character varying(20) DEFAULT '0', mygroup2inpn character varying(255) DEFAULT '0') RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
--Return -1 if nothing matche with given parameters
  DECLARE
    thenomenclatureid integer;
  BEGIN
      SELECT INTO thenomenclatureid id_nomenclature
      FROM gn_synthese.defaults_nomenclatures_value
      WHERE id_type = myidtype
      AND (id_organism = 0 OR id_organism = myidorganism)
      AND (regne = '0' OR regne = myregne)
      AND (group2_inpn = '0' OR group2_inpn = mygroup2inpn)
      ORDER BY group2_inpn DESC, regne DESC, id_organism DESC LIMIT 1;
    IF (thenomenclatureid IS NOT NULL) THEN
      RETURN thenomenclatureid;
    END IF;
    RETURN NULL;
  END;
$$;


------------------------
--TABLES AND SEQUENCES--
------------------------
CREATE TABLE t_sources (
    id_source integer NOT NULL,
    name_source character varying(255) NOT NULL,
    desc_source text,
    entity_source_pk_field character varying(255),
    url_source character varying(255),
    target character varying(10),
    picto_source character varying(255),
    groupe_source character varying(50) NOT NULL,
    active boolean NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);


CREATE TABLE synthese (
    id_synthese integer NOT NULL,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    id_source integer,
    entity_source_pk_value integer,
    id_dataset integer,
    id_nomenclature_geo_object_nature integer DEFAULT get_default_nomenclature_value(3),
    id_nomenclature_grp_typ integer DEFAULT get_default_nomenclature_value(24),
    id_nomenclature_obs_meth integer DEFAULT get_default_nomenclature_value(14),
    id_nomenclature_obs_technique integer DEFAULT get_default_nomenclature_value(100),
    id_nomenclature_bio_status integer DEFAULT get_default_nomenclature_value(13),
    id_nomenclature_bio_condition integer DEFAULT get_default_nomenclature_value(7),
    id_nomenclature_naturalness integer DEFAULT get_default_nomenclature_value(8),
    id_nomenclature_exist_proof integer DEFAULT get_default_nomenclature_value(15),
    id_nomenclature_valid_status integer DEFAULT get_default_nomenclature_value(101),
    id_nomenclature_diffusion_level integer DEFAULT get_default_nomenclature_value(5),
    id_nomenclature_life_stage integer DEFAULT get_default_nomenclature_value(10),
    id_nomenclature_sex integer DEFAULT get_default_nomenclature_value(9),
    id_nomenclature_obj_count integer DEFAULT get_default_nomenclature_value(6),
    id_nomenclature_type_count integer DEFAULT get_default_nomenclature_value(21),
    id_nomenclature_sensitivity integer DEFAULT get_default_nomenclature_value(16),
    id_nomenclature_observation_status integer DEFAULT get_default_nomenclature_value(18),
    id_nomenclature_blurring integer DEFAULT get_default_nomenclature_value(4),
    id_nomenclature_source_status integer DEFAULT get_default_nomenclature_value(19),
    id_nomenclature_info_geo_type integer DEFAULT get_default_nomenclature_value(23),
    id_municipality character(25),
    count_min integer,
    count_max integer,
    cd_nom integer,
    nom_cite character varying(255) NOT NULL,
    meta_v_taxref character varying(50) DEFAULT 'SELECT get_default_parameter(''taxref_version'',NULL)',
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    altitude_min integer,
    altitude_max integer,
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Point,4326),
    the_geom_local public.geometry(Geometry,MYLOCALSRID),
    id_area integer,
    date_min date NOT NULL,
    date_max date NOT NULL,
    id_validator integer,
    validation_comment text,
    observers character varying(255),
    determiner character varying(255),
    determination_method character varying(255),
    comments text,
    deleted boolean DEFAULT false,
    meta_validation_date timestamp without time zone DEFAULT now(),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    last_action character(1),
    CONSTRAINT enforce_dims_the_geom_4326 CHECK ((public.st_ndims(the_geom_4326) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_point CHECK ((public.st_ndims(the_geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(the_geom_point) = 'POINT'::text) OR (the_geom_point IS NULL))),
    CONSTRAINT enforce_srid_the_geom_4326 CHECK ((public.st_srid(the_geom_4326) = 4326)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 4326))
);
COMMENT ON TABLE synthese IS 'Table de synthèse destinée à recevoir les données de tous les protocoles. Pour consultation uniquement';
COMMENT ON COLUMN synthese.id_nomenclature_geo_object_nature IS 'Correspondance nomenclature INPN = nat_obj_geo = 3';
COMMENT ON COLUMN synthese.id_nomenclature_grp_typ IS 'Correspondance nomenclature INPN = typ_grp = 24';
COMMENT ON COLUMN synthese.id_nomenclature_obs_meth IS 'Correspondance nomenclature INPN = methode_obs = 14';
COMMENT ON COLUMN synthese.id_nomenclature_obs_technique IS 'Correspondance nomenclature CAMPANULE = technique_obs = 100';
COMMENT ON COLUMN synthese.id_nomenclature_bio_status IS 'Correspondance nomenclature INPN = statut_bio = 13';
COMMENT ON COLUMN synthese.id_nomenclature_bio_condition IS 'Correspondance nomenclature INPN = etat_bio = 7';
COMMENT ON COLUMN synthese.id_nomenclature_naturalness IS 'Correspondance nomenclature INPN = naturalite = 8';
COMMENT ON COLUMN synthese.id_nomenclature_exist_proof IS 'Correspondance nomenclature INPN = preuve_exist = 15';
COMMENT ON COLUMN synthese.id_nomenclature_valid_status IS 'Correspondance nomenclature GEONATURE = statut_valide = 101';
COMMENT ON COLUMN synthese.id_nomenclature_diffusion_level IS 'Correspondance nomenclature INPN = niv_precis = 5';
COMMENT ON COLUMN synthese.id_nomenclature_life_stage IS 'Correspondance nomenclature INPN = stade_vie = 10';
COMMENT ON COLUMN synthese.id_nomenclature_sex IS 'Correspondance nomenclature INPN = sexe = 9';
COMMENT ON COLUMN synthese.id_nomenclature_obj_count IS 'Correspondance nomenclature INPN = obj_denbr = 6';
COMMENT ON COLUMN synthese.id_nomenclature_type_count IS 'Correspondance nomenclature INPN = typ_denbr = 21';
COMMENT ON COLUMN synthese.id_nomenclature_sensitivity IS 'Correspondance nomenclature INPN = sensibilite = 16';
COMMENT ON COLUMN synthese.id_nomenclature_observation_status IS 'Correspondance nomenclature INPN = statut_obs = 18';
COMMENT ON COLUMN synthese.id_nomenclature_blurring IS 'Correspondance nomenclature INPN = dee_flou = 4';
COMMENT ON COLUMN synthese.id_nomenclature_source_status IS 'Correspondance nomenclature INPN = statut_source = 19';
COMMENT ON COLUMN synthese.id_nomenclature_info_geo_type IS 'Correspondance nomenclature INPN = typ_inf_geo = 23';

CREATE SEQUENCE synthese_id_synthese_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE synthese_id_synthese_seq OWNED BY synthese.id_synthese;
ALTER TABLE ONLY synthese ALTER COLUMN id_synthese SET DEFAULT nextval('synthese_id_synthese_seq'::regclass);

CREATE TABLE cor_area_synthese (
    id_synthese integer,
    id_area integer
);

CREATE TABLE defaults_nomenclatures_value (
    id_type integer NOT NULL,
    id_organism integer NOT NULL DEFAULT 0,
    regne character varying(20) NOT NULL DEFAULT '0',
    group2_inpn character varying(255) NOT NULL DEFAULT '0',
    id_nomenclature integer NOT NULL
);
---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_sources ADD CONSTRAINT pk_t_sources PRIMARY KEY (id_source);

ALTER TABLE ONLY synthese ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);

ALTER TABLE ONLY cor_area_synthese ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area);

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT pk_gn_synthese_defaults_nomenclatures_value PRIMARY KEY (id_type, id_organism, regne, group2_inpn);


---------
--INDEX--
---------
CREATE INDEX index_synthese_t_sources ON synthese USING btree (id_source);

CREATE INDEX index_synthese_cd_nom ON synthese USING btree (cd_nom);

CREATE INDEX index_synthese_date_min ON synthese USING btree (date_min DESC);

CREATE INDEX index_synthese_date_max ON synthese USING btree (date_max DESC);

CREATE INDEX index_synthese_id_dataset ON synthese USING btree (id_dataset);

CREATE INDEX index_synthese_the_geom_local ON synthese USING gist (the_geom_local);

CREATE INDEX index_synthese_the_geom_4326 ON synthese USING gist (the_geom_4326);

CREATE INDEX index_synthese_the_geom_point ON synthese USING gist (the_geom_point);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_source FOREIGN KEY (id_source) REFERENCES t_sources(id_source) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_typ_grp FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_obs_meth FOREIGN KEY (id_nomenclature_obs_meth) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_bio_status FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_bio_condition FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_naturalness FOREIGN KEY (id_nomenclature_naturalness) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_exist_proof FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_valid_status FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_diffusion_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_life_stage FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_sex FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_obj_count FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_type_count FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_sensitivity FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_observation_status FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_blurring FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_info_geo_type FOREIGN KEY (id_nomenclature_info_geo_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;
    
ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_validator FOREIGN KEY (id_validator) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_synthese FOREIGN KEY (id_synthese) REFERENCES synthese(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_id_type FOREIGN KEY (id_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_date_max CHECK (date_max >= date_min);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_count_max CHECK (count_max >= count_min);


ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_meth,14));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_geo_object_nature,3));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_typ_grp CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_grp_typ,24));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_technique,100));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_bio_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_status,13));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_condition,7));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_naturalness CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_naturalness,8));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_exist_proof,15));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_valid_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_valid_status,101));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_diffusion_level CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_diffusion_level,5));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_life_stage CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_life_stage,10));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_sex CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sex,9));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obj_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obj_count,6));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_type_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_type_count,21));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sensitivity,16));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_observation_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_observation_status,18));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_blurring CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_blurring,4));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_source_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_source_status,19));


ALTER TABLE cor_area_synthese
  ADD CONSTRAINT check_cor_area_synthese_info_geo_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_info_geo_type,23));

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature, id_type));

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isgroup2inpn CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = '0'::text);

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isregne CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = '0'::text);


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_synthese
  BEFORE INSERT OR UPDATE
  ON synthese
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_t_sources
  BEFORE INSERT OR UPDATE
  ON t_sources
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


--------
--DATA--
--------
INSERT INTO t_sources (id_source, name_source, desc_source, entity_source_pk_field, url_source, target, picto_source, groupe_source, active) VALUES (0, 'API', 'Donnée externe non définie (insérée dans la synthese à partir du service REST de l''API sans entity_source_pk_value fourni)', NULL, NULL, NULL, NULL, 'NONE', false);
