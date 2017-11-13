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


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION pr_contact.get_default_nomenclature_value(myidtype integer, myidorganism integer DEFAULT 0) RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id 
--Return -1 if nothing matche with given parameters
  DECLARE
    thenomenclatureid integer;
  BEGIN
      SELECT INTO thenomenclatureid id_nomenclature
      FROM pr_contact.defaults_nomenclatures_value 
      WHERE id_type = myidtype 
      AND (id_organism = myidorganism OR id_organism = 0)
      ORDER BY id_organism DESC LIMIT 1;
    IF (thenomenclatureid IS NOT NULL) THEN
      RETURN thenomenclatureid;
    END IF;
    RETURN -1;
  END;
$$;


------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_releves_contact (
    id_releve_contact bigint NOT NULL,
    id_dataset integer NOT NULL,
    id_digitiser integer,
    observers_txt varchar(500),
    date_min timestamp without time zone DEFAULT now() NOT NULL,
    date_max timestamp without time zone DEFAULT now() NOT NULL,
    hour_min time,
    hour_max time,
    altitude_min integer,
    altitude_max integer,
    deleted boolean DEFAULT false NOT NULL,
    meta_device_entry character varying(20),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    comment text,
    geom_local public.geometry(Geometry,MYLOCALSRID),
    geom_4326 public.geometry(Geometry,4326),
    precision integer DEFAULT 100,
    CONSTRAINT enforce_dims_geom_4326 CHECK ((public.st_ndims(geom_4326) = 2)),
    CONSTRAINT enforce_dims_geom_local CHECK ((public.st_ndims(geom_local) = 2)),
    CONSTRAINT enforce_srid_geom_4326 CHECK ((public.st_srid(geom_4326) = 4326)),
    CONSTRAINT enforce_srid_geom_local CHECK ((public.st_srid(geom_local) = MYLOCALSRID))
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
    id_nomenclature_obs_technique integer NOT NULL DEFAULT 343,
    id_nomenclature_obs_meth integer NOT NULL, -- DEFAULT get_default_nomenclature_value(14),
    id_nomenclature_bio_condition integer NOT NULL, -- DEFAULT get_default_nomenclature_value(7),
    id_nomenclature_bio_status integer DEFAULT, -- get_default_nomenclature_value(13),
    id_nomenclature_naturalness integer DEFAULT, -- get_default_nomenclature_value(8),
    id_nomenclature_exist_proof integer DEFAULT, -- get_default_nomenclature_value(15),
    id_nomenclature_valid_status integer DEFAULT, -- get_default_nomenclature_value(101),
    id_nomenclature_diffusion_level integer DEFAULT, -- get_default_nomenclature_value(5),
    id_nomenclature_observation_status integer, --DEFAULT get_default_nomenclature_value(18),
    id_nomenclature_blurring integer DEFAULT, -- get_default_nomenclature_value(4),
    id_validator integer,
    determiner character varying(255),
    id_nomenclature_determination_method integer DEFAULT, -- get_default_nomenclature_value(106),
    determination_method_as_text text,
    cd_nom integer,
    nom_cite character varying(255),
    meta_v_taxref character varying(50) DEFAULT 'SELECT get_default_parameter(''taxref_version'')',
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    deleted boolean DEFAULT false NOT NULL,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    comment character varying
);
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_obs_technique IS 'Correspondance nomenclature INPN = technique_obs';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_obs_meth IS 'Correspondance nomenclature INPN = methode_obs';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_bio_condition IS 'Correspondance nomenclature INPN = etat_bio';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_bio_status IS 'Correspondance nomenclature INPN = statut_bio';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_naturalness IS 'Correspondance nomenclature INPN = naturalite';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_exist_proof IS 'Correspondance nomenclature INPN = preuve_exist';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_valid_status IS 'Correspondance nomenclature INPN = statut_valide';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_diffusion_level IS 'Correspondance nomenclature INPN = niv_precis';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_observation_status IS 'Correspondance nomenclature INPN = statut_obs';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_blurring IS 'Correspondance nomenclature INPN = dee_flou';
COMMENT ON COLUMN t_occurrences_contact.id_nomenclature_determination_method IS 'Correspondance nomenclature GEONATURE = meth_determin';

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
    id_counting_contact bigint NOT NULL,
    id_occurrence_contact bigint NOT NULL,
    id_nomenclature_life_stage integer NOT NULL DEFAULT, -- get_default_nomenclature_value(10),
    id_nomenclature_sex integer NOT NULL DEFAULT, -- get_default_nomenclature_value(9),
    id_nomenclature_obj_count integer NOT NULL, -- DEFAULT get_default_nomenclature_value(6),
    id_nomenclature_type_count integer DEFAULT, -- get_default_nomenclature_value(21),
    count_min integer,
    count_max integer,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    unique_id_sinp uuid NOT NULL DEFAULT public.uuid_generate_v4()
);
CREATE SEQUENCE cor_counting_contact_id_counting_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE cor_counting_contact_id_counting_contact_seq OWNED BY t_occurrences_contact.id_occurrence_contact;
ALTER TABLE ONLY cor_counting_contact ALTER COLUMN id_counting_contact SET DEFAULT nextval('cor_counting_contact_id_counting_contact_seq'::regclass);
SELECT pg_catalog.setval('cor_counting_contact_id_counting_contact_seq', 1, false);


CREATE TABLE cor_role_releves_contact (
    id_releve_contact bigint NOT NULL,
    id_role integer NOT NULL
);


CREATE TABLE defaults_nomenclatures_value (
    id_type integer NOT NULL,
    id_organism integer NOT NULL,
    id_nomenclature integer NOT NULL
);


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT pk_t_occurrences_contact PRIMARY KEY (id_occurrence_contact);

ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT pk_t_releves_contact PRIMARY KEY (id_releve_contact);

ALTER TABLE ONLY cor_counting_contact
    ADD CONSTRAINT pk_cor_counting_contact_contact PRIMARY KEY (id_counting_contact);

ALTER TABLE ONLY cor_role_releves_contact
    ADD CONSTRAINT pk_cor_role_releves_contact PRIMARY KEY (id_releve_contact, id_role);

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT pk_defaults_nomenclatures_value PRIMARY KEY (id_type, id_organism);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT fk_t_releves_contact_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT fk_t_releves_contact_t_roles FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_t_releves_contact FOREIGN KEY (id_releve_contact) REFERENCES t_releves_contact(id_releve_contact) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

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
    ADD CONSTRAINT fk_t_occurrences_contact_diffusion_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_observation_status FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_blurring FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT fk_t_occurrences_contact_determination_method FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


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


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_contact_defaults_nomenclatures_value_id_type FOREIGN KEY (id_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(id_type) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_contact_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_contact_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT check_t_releves_contact_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY t_releves_contact
    ADD CONSTRAINT check_t_releves_contact_date_max CHECK (date_max >= date_min);

ALTER TABLE t_releves_contact
  ADD CONSTRAINT check_t_releves_contact_hour_max CHECK (hour_min <= hour_max OR date_min < date_max);


ALTER TABLE ONLY t_occurrences_contact
    ADD CONSTRAINT check_t_occurrences_contact_cd_nom_isinbib_noms CHECK (taxonomie.check_is_inbibnoms(cd_nom));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_technique,100));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_meth,14));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_condition,7));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_bio_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_status,13));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_naturalness CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_naturalness,8));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_exist_proof,15));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_valid_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_valid_status,101));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_accur_level CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_diffusion_level,5));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_obs_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_observation_status,18));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_blurring CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_blurring,4));

ALTER TABLE t_occurrences_contact
  ADD CONSTRAINT check_t_occurrences_contact_determination_method CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_determination_method,106));


ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_cor_counting_contact_life_stage CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_life_stage,10));

ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_cor_counting_contact_sexe CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sex,9));

ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_cor_counting_contact_obj_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obj_count,6));

ALTER TABLE cor_counting_contact
  ADD CONSTRAINT check_cor_counting_contact_type_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_type_count,21));

ALTER TABLE cor_counting_contact
    ADD CONSTRAINT check_cor_counting_contact_count_min CHECK (count_min > 0);

ALTER TABLE cor_counting_contact
    ADD CONSTRAINT check_cor_counting_contact_count_max CHECK (count_max >= count_min AND count_max > 0);


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_contact_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature, id_type));



----------------------
--FUNCTIONS TRIGGERS--
----------------------
CREATE OR REPLACE FUNCTION insert_occurrences_contact()
  RETURNS trigger AS
$BODY$
DECLARE
    idsensitivity integer;
BEGIN
    --Calculate sensitivity value
    SELECT INTO idsensitivity ref_nomenclatures.calculate_sensitivity(new.cd_nom,new.id_nomenclature_obs_meth);
    new.id_nomenclature_diffusion_level = idsensitivity;
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION update_occurrences_contact()
  RETURNS trigger AS
$BODY$
DECLARE
    idsensitivity integer;
BEGIN
    --Calculate sensitivity value
    SELECT INTO idsensitivity ref_nomenclatures.calculate_sensitivity(new.cd_nom,new.id_nomenclature_obs_meth);
    new.id_nomenclature_diffusion_level = idsensitivity;
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

CREATE TRIGGER tri_meta_dates_change_occurrences_contact
  BEFORE INSERT OR UPDATE
  ON t_occurrences_contact
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_change_t_releves_contact
  BEFORE INSERT OR UPDATE
  ON t_releves_contact
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_change_cor_counting_contact
  BEFORE INSERT OR UPDATE
  ON cor_counting_contact
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


------------
--VIEWS--
------------
--Vue représentant l'ensemble des observations du protocole contact pour la représentation du module carte liste
DROP VIEW IF EXISTS v_releve_contact;
CREATE OR REPLACE VIEW pr_contact.v_releve_contact AS 
 SELECT rel.id_releve_contact,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.deleted,
    rel.meta_device_entry,
    rel.meta_create_date,
    rel.meta_update_date,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    occ.id_occurrence_contact,
    occ.cd_nom,
    occ.nom_cite,
    occ.deleted AS occ_deleted,
    occ.meta_create_date AS occ_meta_create_date,
    occ.meta_update_date AS occ_meta_update_date,
    t.lb_nom,
    t.nom_valide,
    t.nom_vern,
    (((t.nom_complet_html::text || ' '::text) || rel.date_min::date) || '<br/>'::text) || string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text) AS leaflet_popup,
    COALESCE ( string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text),rel.observers_txt) AS observateurs
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_contact.cor_role_releves_contact cor_role ON cor_role.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
  GROUP BY rel.id_releve_contact, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.deleted, rel.meta_device_entry, rel.meta_create_date, rel.meta_update_date, rel.comment, rel.geom_4326, rel."precision", t.cd_nom, occ.nom_cite, occ.id_occurrence_contact, occ.deleted, occ.meta_create_date, occ.meta_update_date, t.lb_nom, t.nom_valide, t.nom_complet_html, t.nom_vern;





--Vue représentant l'ensemble des relevés du protocole contact pour la représentation du module carte liste
CREATE OR REPLACE VIEW pr_contact.v_releve_list AS 
 SELECT rel.id_releve_contact,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.deleted,
    rel.meta_device_entry,
    rel.meta_create_date,
    rel.meta_update_date,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    string_agg(t.nom_valide::text, ','::text) AS taxons,
    (((string_agg(t.nom_valide::text, ','::text) || '<br/>'::text) || rel.date_min::date) || '<br/>'::text) || COALESCE(string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt) AS leaflet_popup,
    COALESCE(string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS observateurs
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_contact.cor_role_releves_contact cor_role ON cor_role.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
  GROUP BY rel.id_releve_contact, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.deleted, rel.meta_device_entry, rel.meta_create_date, rel.meta_update_date, rel.comment, rel.geom_4326, rel."precision";


CREATE OR REPLACE VIEW pr_contact.export_occtax_sinp AS 
SELECT cor_counting.unique_id_sinp AS "identifiantPermanent",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_observation_status) AS "statutObservation",
    occ.nom_cite AS "nomCite",
    rel.date_min AS "jourDateDebut",
    rel.date_max AS "jourDateFin",
    rel.hour_min AS "heureDateDebut",
    rel.hour_max AS "heureDateFin",
    rel.altitude_max AS "altitudeMax",
    rel.altitude_min AS "altitudeMin",
    occ.cd_nom AS "cdNom",
    taxonomie.find_cdref(occ.cd_nom) AS "cdRef",
    gn_meta.get_default_parameter('taxref_version'::text, NULL::integer) AS "versionTAXREF",
    rel.date_min AS "dateDetermination",
    occ.comment AS commentaire,
    'NSP'::text AS "dSPublique",
    datasets.unique_dataset_id AS "jddMetadonneeDEEId",
    NULL::text AS "sensible",
    NULL::text AS "sensiNiveau",
    'Te'::text AS "statutSource",
    'NSP'::text AS "codeIDCNPDispositif",
    'NSP'::text AS "dEEFloutage",
    'NSP'::text AS "diffusionNiveauPrecision",
    cor_counting.unique_id_sinp AS "identifiantOrigine",
    datasets.dataset_name AS "jddCode",
    datasets.unique_dataset_id AS "jddId",
    NULL::text AS "referenceBiblio",
    NULL::text AS "sensiDateAttribution",
    NULL::text AS "sensiReferentiel",
    NULL::text AS "sensiversionreferentiel",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth) AS "obsMethode",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition) AS "occEtatBiologique",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text) AS "occNaturalite",
    ref_nomenclatures.get_cd_nomenclature(cor_counting.id_nomenclature_sex) AS "occSexe",
    ref_nomenclatures.get_cd_nomenclature(cor_counting.id_nomenclature_life_stage) AS "occStadeDeVie",
    '0'::text AS "occStatutBioGeographique",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status), '0'::text ) AS "occStatutBiologique",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof), '0'::text) AS "preuveExistante",
    COALESCE(ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method, 'fr'), occ.determination_method_as_text::character varying) AS "occMethodeDetermination",
    occ.digital_proof AS "preuveNumerique",
    occ.non_digital_proof AS "preuveNonNumerique",
    rel.comment AS "obsContexte",
    rel.id_releve_contact AS "identifiantRegroupementPermanent",
    'NSP'::text AS "methodeRegroupement",
    'OBS'::text AS "typeRegroupement",
    cor_counting.count_max AS "denombrementMax",
    cor_counting.count_min AS "denombrementMin",
    ref_nomenclatures.get_cd_nomenclature(cor_counting.id_nomenclature_obj_count) AS "objetDenombrement",
    ref_nomenclatures.get_cd_nomenclature(cor_counting.id_nomenclature_type_count) AS "typeDenombrement",
    COALESCE(string_agg((role.nom_role::text || ' '::text) || role.prenom_role::text, ','::text), rel.observers_txt::text) AS "observateurIdentite",
    COALESCE(string_agg(role.organisme::text, ','::text), organisme.nom_organisme::text, 'NSP'::text) AS "observateurNomOrganisme",
    COALESCE(occ.determiner, COALESCE(string_agg((role.nom_role::text || ' '::text) || role.prenom_role::text, ','::text), rel.observers_txt::text)::character varying) AS "determinateurIdentite",
    'NSP'::text AS "determinateurNomOrganisme",
    'NSP'::text AS "validateurIdentite",
    'NSP'::text AS "validateurNomOrganisme",
    'NSP'::text AS "organismeGestionnaireDonnee",
    st_astext(rel.geom_4326) AS geometrie,
    'In'::text AS "natureObjetGeo"
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN pr_contact.cor_counting_contact cor_counting ON cor_counting.id_occurrence_contact = occ.id_occurrence_contact
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets datasets ON datasets.id_dataset = rel.id_dataset
     LEFT JOIN pr_contact.cor_role_releves_contact cor_role ON cor_role.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles role ON role.id_role = cor_role.id_role
     LEFT JOIN utilisateurs.bib_organismes organisme ON organisme.id_organisme = role.id_organisme
  GROUP BY cor_counting.unique_id_sinp, datasets.unique_dataset_id,occ.id_nomenclature_bio_condition, occ.id_nomenclature_naturalness, cor_counting.id_nomenclature_sex,cor_counting.id_nomenclature_life_stage,
  occ.id_nomenclature_bio_status,occ.id_nomenclature_exist_proof, occ.id_nomenclature_determination_method,
   cor_counting.id_nomenclature_sex, rel.id_releve_contact, datasets.id_nomenclature_source_status, occ.id_nomenclature_blurring, occ.id_nomenclature_diffusion_level, 'Pr'::text, occ.nom_cite, rel.date_min, rel.date_max, rel.hour_min, rel.hour_max, rel.altitude_max, rel.altitude_min, occ.cd_nom, occ.id_nomenclature_observation_status, (taxonomie.find_cdref(occ.cd_nom)), (gn_meta.get_default_parameter('taxref_version'::text, NULL::integer)),
    rel.comment, cor_counting.meta_update_date, 'Ac'::text, 
    rel.id_dataset, NULL::text, 'Te'::text, cor_counting.id_counting_contact, 
     datasets.dataset_name, occ.determiner,
     commentaire, "obsMethode","occEtatBiologique",
     "occNaturalite", "occSexe", "occStadeDeVie", "occStatutBioGeographique", "occStatutBiologique", "preuveExistante", "occMethodeDetermination",
     "preuveNumerique","preuveNonNumerique", "obsContexte", "identifiantRegroupementPermanent", "methodeRegroupement", "typeRegroupement", "denombrementMax",
     "denombrementMin", "objetDenombrement", "typeDenombrement", rel.observers_txt, 'NSP'::text, organisme.nom_organisme, "determinateurNomOrganisme",
     "validateurIdentite", "validateurNomOrganisme", "organismeGestionnaireDonnee", "geometrie", "natureObjetGeo"


