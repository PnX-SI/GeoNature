SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
--SET row_security = off;


CREATE SCHEMA pr_contact;


SET search_path = pr_contact, pg_catalog;
SET default_with_oids = false;

------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_releves_contact (
    id_releve_contact bigint NOT NULL,
    id_dataset integer NOT NULL,
    id_nomenclature_obs_technique integer NOT NULL DEFAULT 343,
    id_digitiser integer,
    date_min timestamp without time zone DEFAULT now() NOT NULL,
    date_max timestamp without time zone DEFAULT now() NOT NULL,
    altitude_min integer,
    altitude_max integer,
    meta_device_entry character varying(20),
    deleted boolean DEFAULT false NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    comment text,
    the_geom_local public.geometry(Geometry,MYLOCALSRID),
    the_geom_3857 public.geometry(Geometry,3857),
    precision integer DEFAULT 10,
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID))
);

CREATE SEQUENCE t_releves_contact_id_releve_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_releves_contact_id_releve_contact_seq OWNED BY t_releves_contact.id_releve_contact;
ALTER TABLE ONLY t_releves_contact ALTER COLUMN id_releve_contact SET DEFAULT nextval('t_releves_contact_id_releve_contact_seq'::regclass);
SELECT pg_catalog.setval('t_releves_contact_id_releve_contact_seq', 1, false);


CREATE TABLE t_occurrences_contact (
    id_occurrence_contact bigint NOT NULL,
    id_releve_contact bigint NOT NULL,
    id_nomenclature_obs_meth integer DEFAULT 42,
    id_nomenclature_bio_condition integer NOT NULL DEFAULT 177,
    id_nomenclature_bio_status integer DEFAULT 30,
    id_nomenclature_naturalness integer DEFAULT 182,
    id_nomenclature_exist_proof integer DEFAULT 91,
    id_nomenclature_valid_status integer DEFAULT 347,
    id_nomenclature_diffusion_level integer DEFAULT 163,
    id_validator integer,
    determiner character varying(255),
    determination_method character varying(255),
    cd_nom integer,
    nom_cite character varying(255),
    meta_v_taxref character varying(50) DEFAULT 'Taxref V9.0',
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    deleted boolean DEFAULT false NOT NULL,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    comment character varying
);
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_obs_meth IS 'Correspondance nomenclature INPN = methode_obs';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_bio_condition IS 'Correspondance nomenclature INPN = etat_bio';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_bio_status IS 'Correspondance nomenclature INPN = statut_bio';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_naturalness IS 'Correspondance nomenclature INPN = naturalite';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_exist_proof IS 'Correspondance nomenclature INPN = preuve_exist';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_valid_status IS 'Correspondance nomenclature INPN = statut_valide';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_diffusion_level IS 'Correspondance nomenclature INPN = niv_precis';

CREATE SEQUENCE t_occurrences_contact_id_occurrence_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_occurrences_contact_id_occurrence_contact_seq OWNED BY t_occurrences_contact.id_occurrence_contact;
ALTER TABLE ONLY t_occurrences_contact ALTER COLUMN id_occurrence_contact SET DEFAULT nextval('t_occurrences_contact_id_occurrence_contact_seq'::regclass);
SELECT pg_catalog.setval('t_occurrences_contact_id_occurrence_contact_seq', 1, false);


CREATE TABLE cor_counting_contact (
    id_occurrence_contact bigint NOT NULL,
    id_nomenclature_life_stage integer NOT NULL,
    id_nomenclature_sex integer NOT NULL,
    id_nomenclature_obj_count integer NOT NULL DEFAULT 166,
    id_nomenclature_type_count integer DEFAULT 107,
    count_min integer,
    count_max integer
);


CREATE TABLE cor_role_releves_contact (
    id_releve_contact bigint NOT NULL,
    id_role integer NOT NULL
);


CREATE TABLE cor_municipality_releves_contact (
    id_releve_contact bigint NOT NULL,
    id_municipality character varying(20) NOT NULL
);

---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT pk_t_occurrences_contact PRIMARY KEY (id_occurrence_contact);

ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT pk_t_releves_contact PRIMARY KEY (id_releve_contact);

ALTER TABLE ONLY cor_counting_contact
    ADD CONSTRAINT pk_cor_counting_contact_contact PRIMARY KEY (id_occurrence_contact, id_nomenclature_life_stage, id_nomenclature_sex);

ALTER TABLE ONLY cor_role_releves_contact
    ADD CONSTRAINT pk_cor_role_releves_contact PRIMARY KEY (id_releve_contact, id_role);

ALTER TABLE ONLY cor_municipality_releves_contact
    ADD CONSTRAINT pk_cor_municipality_releves_contact PRIMARY KEY (id_releve_contact, id_municipality);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT fk_t_releves_contact_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT fk_t_releves_contact_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT fk_t_releves_contact_t_roles FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_t_releves_contact FOREIGN KEY (id_releve_contact) REFERENCES t_releves_contact(id_releve_contact) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_t_roles FOREIGN KEY (id_validator) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_taxref FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_obs_meth FOREIGN KEY (id_nomenclature_obs_meth) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_bio_condition FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_bio_status FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_naturalness FOREIGN KEY (id_nomenclature_naturalness) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_exist_proof FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_valid_status FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_accur_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_counting_contact
    ADD CONSTRAINT fk_cor_stage_number_id_taxon FOREIGN KEY (id_occurrence_contact) REFERENCES t_occurrences_contact(id_occurrence_contact) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_counting_contact
    ADD CONSTRAINT fk_cor_counting_contact_sexe FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_counting_contact
    ADD CONSTRAINT fk_cor_counting_contact_life_stage FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_counting_contact
    ADD CONSTRAINT fk_cor_counting_contact_obj_count FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_counting_contact
    ADD CONSTRAINT fk_cor_counting_contact_typ_count FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_role_releves_contact
    ADD CONSTRAINT fk_cor_role_releves_contact_t_releves_contact FOREIGN KEY (id_releve_contact) REFERENCES t_releves_contact(id_releve_contact) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_releves_contact
    ADD CONSTRAINT fk_cor_role_releves_contact_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_municipality_releves_contact
     ADD CONSTRAINT fk_cor_municipality_releves_contact_t_releves_contact FOREIGN KEY (id_releve_contact) REFERENCES t_releves_contact(id_releve_contact) ON UPDATE CASCADE ON DELETE CASCADE;
--TODO FK on municipality table


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT check_t_releves_contact_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT check_t_releves_contact_date_max CHECK (date_max >= date_min);

ALTER TABLE t_releves_contact
  ADD CONSTRAINT check_t_releves_contact_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_technique,100));


ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT check_t_occurrences_contact_cd_nom_isinbib_noms CHECK (taxonomie.check_is_inbibnoms(cd_nom));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_releves_contact_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_meth,14));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_condition,7));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_bio_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_status,13));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_naturalness CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_naturalness,8));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_exist_proof,15));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_valid_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_valid_status,101));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check__occurrences_contact_accur_level CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_diffusion_level,5));


ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_t_releves_contact_life_stage CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_life_stage,10));

ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_t_releves_contact_sexe CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sex,9));

ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_t_releves_contact_obj_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obj_count,6));

ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_t_releves_contact_type_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_type_count,21));

ALTER TABLE cor_counting_contact
    ADD CONSTRAINT check_cor_counting_contact_count_min CHECK (count_min > 0);

ALTER TABLE cor_counting_contact
    ADD CONSTRAINT check_cor_counting_contact_count_max CHECK (count_max >= count_min AND count_max > 0);

----------------------
--FUNCTIONS TRIGGERS--
----------------------
CREATE OR REPLACE FUNCTION insert_occurrences_contact()
  RETURNS trigger AS
$BODY$
DECLARE
    idsensibilite integer;
BEGIN
    --calcul de la valeur de la sensibilité
    SELECT INTO idsensibilite ref_nomenclatures.calculate_sensitivity(new.cd_nom,new.id_nomenclature_obs_meth);
    new.id_nomenclature_diffusion_level = idsensibilite;
    RETURN NEW;             
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION update_occurrences_contact()
  RETURNS trigger AS
$BODY$
DECLARE
    idsensibilite integer;
BEGIN
    --calcul de la valeur de la sensibilité
    SELECT INTO idsensibilite ref_nomenclatures.calculate_sensitivity(new.cd_nom,new.id_nomenclature_obs_meth);
    new.id_nomenclature_diffusion_level = idsensibilite;
    RETURN NEW;             
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


------------
--TRIGGERS--
------------
CREATE TRIGGER tri_insert_occurrences_contact
  BEFORE INSERT
  ON t_occurrences_contact
  FOR EACH ROW
  EXECUTE PROCEDURE insert_occurrences_contact();

CREATE TRIGGER tri_update_occurrences_contact
  BEFORE INSERT
  ON t_occurrences_contact
  FOR EACH ROW
  EXECUTE PROCEDURE update_occurrences_contact();