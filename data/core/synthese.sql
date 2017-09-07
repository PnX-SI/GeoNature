SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA gn_synthese;

SET search_path = gn_synthese, pg_catalog;

SET default_with_oids = false;


CREATE TABLE t_modules (
    id_module integer NOT NULL,
    name_module character varying(255) NOT NULL,
    desc_module text,
    entity_module_pk_field character varying(255),
    url_module character varying(255),
    target character varying(10),
    picto_module character varying(255),
    groupe_module character varying(50) NOT NULL,
    active boolean NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);


CREATE TABLE synthese (
    id_synthese integer NOT NULL,
    unique_id_sinp uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    id_module integer,
    entity_module_pk_value integer,
    id_dataset integer,
    id_nomenclature_typ_inf_geo,
    id_nomenclature_obs_meth integer DEFAULT 42,
    id_nomenclature_obs_technique integer DEFAULT 343,
    id_nomenclature_bio_status integer DEFAULT 30,
    id_nomenclature_bio_condition integer DEFAULT 177,
    id_nomenclature_naturalness integer DEFAULT 181,
    id_nomenclature_exist_proof integer DEFAULT 91,
    id_nomenclature_valid_status integer DEFAULT 346,
    id_nomenclature_diffusion_level integer DEFAULT 163,
    id_nomenclature_life_stage integer DEFAULT 2,
    id_nomenclature_sex integer DEFAULT 188,
    id_nomenclature_obj_count integer DEFAULT 165,
    id_nomenclature_type_count integer DEFAULT 109,
    id_nomenclature_sensitivity integer DEFAULT 68,
    count_min integer,
    count_max integer,
    cd_nom integer NOT NULL,
    nom_cite character varying(255),
    meta_v_taxref character varying(50) DEFAULT 'SELECT get_default_parameter(''taxref_version'',NULL)',
    id_municipality character(25),
    altitude_min integer,
    altitude_max integer,
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Point,4326),
    the_geom_local public.geometry(Geometry,MYLOCALSRID),
    date_min date NOT NULL,
    date_max date NOT NULL,
    id_validator integer,
    observers character varying(255),
    determiner character varying(255),
    determination_method character varying(255),
    comment text,
    deleted boolean DEFAULT false,
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
COMMENT ON COLUMN synthese.id_nomenclature_typ_inf_geo, IS 'Correspondance nomenclature INPN = type_info_geo = 23';
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

CREATE SEQUENCE synthese_id_synthese_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE synthese_id_synthese_seq OWNED BY synthese.id_synthese;
ALTER TABLE ONLY synthese ALTER COLUMN id_synthese SET DEFAULT nextval('synthese_id_synthese_seq'::regclass);


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_modules ADD CONSTRAINT pk_t_modules PRIMARY KEY (id_module);

ALTER TABLE ONLY synthese ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);


---------
--INDEX--
---------
CREATE INDEX fki_synthese_bib_proprietaires ON synthese USING btree (id_organisme);

CREATE INDEX fki_synthese_id_municipality_fkey ON synthese USING btree (id_municipality);

CREATE INDEX fki_synthese_t_modules ON synthese USING btree (id_module);

CREATE INDEX i_synthese_cd_nom ON synthese USING btree (cd_nom);

CREATE INDEX i_synthese_date_min ON synthese USING btree (date_min DESC);

CREATE INDEX i_synthese_date_max ON synthese USING btree (date_max DESC);

CREATE INDEX i_synthese_id_dataset ON synthese USING btree (id_dataset);

CREATE INDEX index_gist_synthese_the_geom_local ON synthese USING gist (the_geom_local);

CREATE INDEX index_gist_synthese_the_geom_4326 ON synthese USING gist (the_geom_4326);

CREATE INDEX index_gist_synthese_the_geom_point ON synthese USING gist (the_geom_point);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_module FOREIGN KEY (id_module) REFERENCES t_modules(id_module) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_typ_inf_geo FOREIGN KEY (id_nomenclature_typ_inf_geo) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

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
    ADD CONSTRAINT fk_synthese_id_validator FOREIGN KEY (id_validator) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


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
  ADD CONSTRAINT check_synthese_typ_inf_geo CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_typ_inf_geo,23));

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_meth,14));

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

ALTER TABLE cor_counting_contact
    ADD CONSTRAINT check_cor_counting_contact_count_min CHECK (count_min > 0);

ALTER TABLE cor_counting_contact
    ADD CONSTRAINT check_cor_counting_contact_count_max CHECK (count_max >= count_min AND count_max > 0);

------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_synthese
  BEFORE INSERT OR UPDATE
  ON synthese
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_t_modules
  BEFORE INSERT OR UPDATE
  ON t_modules
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


--------
--DATA--
--------
INSERT INTO t_modules (id_module, name_module, desc_module, entity_module_pk_field, url_module, target, picto_module, groupe_module, active) VALUES (0, 'API', 'Donnée externe non définie (insérée dans la synthese à partir du service REST de l''API sans entity_module_pk_value fourni)', NULL, NULL, NULL, NULL, 'NONE', false);
