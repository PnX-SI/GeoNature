SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA pr_occtax;


SET search_path = pr_occtax, pg_catalog;
SET default_with_oids = false;


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0, myregne character varying(20) DEFAULT '0', mygroup2inpn character varying(255) DEFAULT '0') RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
--Return -1 if nothing matche with given parameters
  DECLARE
    thenomenclatureid integer;
  BEGIN
      SELECT INTO thenomenclatureid id_nomenclature
      FROM pr_occtax.defaults_nomenclatures_value
      WHERE mnemonique_type = mytype
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

CREATE OR REPLACE FUNCTION pr_occtax.get_id_counting_from_id_releve(my_id_releve integer)
  RETURNS integer[] AS
$BODY$
-- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
DECLARE the_array_id_counting integer[];

BEGIN
SELECT INTO the_array_id_counting array_agg(counting.id_counting_occtax)
FROM pr_occtax.t_releves_occtax rel
JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
WHERE rel.id_releve_occtax = my_id_releve;
RETURN the_array_id_counting;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;
CREATE OR REPLACE FUNCTION pr_occtax.id_releve_from_id_counting(my_id_counting integer)
  RETURNS integer AS
$BODY$
-- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
DECLARE the_id_releve integer;

BEGIN
  SELECT INTO the_id_releve rel.id_releve_occtax
  FROM pr_occtax.t_releves_occtax rel
  JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
  JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
  WHERE counting.id_counting_occtax = my_id_counting;

  RETURN the_id_releve;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;



CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
  RETURNS integer[] AS
  $BODY$
DECLARE

new_count RECORD;
occurrence RECORD;
releve RECORD;
id_source integer;
validation RECORD;
cd_nomenclature_source_status character varying;
observers RECORD;
id_municipality character varying;
id_role_loop integer;

BEGIN

--recupération du counting à partir de son ID
SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;
-- Récupération de l'occurrence
SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;

-- Récupération du relevé

SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;

-- Récupération de la source
SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE lower(name_source) = 'occtax';

-- Récupération du status de validation du counting dans la table t_validation
SELECT INTO validation * FROM gn_commons.t_validations v WHERE uuid_attached_row = new_count.unique_id_sinp_occtax;

-- Récupération du status_source depuis le JDD
SELECT INTO cd_nomenclature_source_status ref_nomenclatures.get_cd_nomenclature(d.id_nomenclature_source_status) FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

-- Récupération de l'id_municipality par intersection avec ref_geo: pour les polygones on prend le centroid
SELECT INTO id_municipality m.insee_com
FROM ref_geo.li_municipalities m
JOIN ref_geo.l_areas a ON a.id_area = m.id_area
WHERE ST_INTERSECTS(ST_CENTROID(releve.geom_local), a.geom) AND a.id_type = 101;

--Récupération et formatage des observateurs
SELECT INTO observers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
array_agg(rol.id_role) AS observers_id
FROM pr_occtax.cor_role_releves_occtax cor
JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
JOIN pr_occtax.t_releves_occtax rel ON rel.id_releve_occtax = cor.id_releve_occtax
WHERE cor.id_releve_occtax = releve.id_releve_occtax;


-- insertion dans la synthese
INSERT INTO gn_synthese.synthese (
unique_id_sinp,
unique_id_sinp_grp,
id_source,
entity_source_pk_value,
id_dataset,
cd_nomenclature_geo_object_nature,
cd_nomenclature_grp_typ,
cd_nomenclature_obs_meth,
cd_nomenclature_obs_technique,
cd_nomenclature_bio_status,
cd_nomenclature_bio_condition,
cd_nomenclature_naturalness,
cd_nomenclature_exist_proof,
cd_nomenclature_valid_status,
cd_nomenclature_diffusion_level,
cd_nomenclature_life_stage,
cd_nomenclature_sex,
cd_nomenclature_obj_count,
cd_nomenclature_type_count,
cd_nomenclature_sensitivity,
cd_nomenclature_observation_status,
cd_nomenclature_blurring,
cd_nomenclature_source_status,
cd_nomenclature_info_geo_type,
id_municipality,
count_min,
count_max,
cd_nom,
nom_cite,
meta_v_taxref,
sample_number_proof,
digital_proof,
non_digital_proof,
altitude_min,
altitude_max,
the_geom_4326,
the_geom_point,
the_geom_local,
-- id_area, TODO
date_min,
date_max,
id_validator,
validation_comment,
observers,
determiner,
cd_nomenclature_determination_method,
comments,
last_action
)

VALUES(
  new_count.unique_id_sinp_occtax,
  releve.unique_id_sinp_grp,
  id_source,
  new_count.id_counting_occtax,
  releve.id_dataset,
  --nature de l'objet geo: cd_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - a ajouter dans default_nomenclature du schema occtax
  'In',
  ref_nomenclatures.get_cd_nomenclature(releve.id_nomenclature_grp_typ),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_obs_meth),
  ref_nomenclatures.get_cd_nomenclature(releve.id_nomenclature_obs_technique),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_bio_status),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_bio_condition),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_naturalness),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_exist_proof),
  -- statut de validation récupérer à partir de gn_commons.t_validations
  ref_nomenclatures.get_cd_nomenclature(validation.id_nomenclature_valid_status),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_diffusion_level),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_life_stage),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_sex),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_obj_count),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_type_count),
  -- cd_nomenclature_sensitivity le trigger qui calcule la sensibilité doit remplir le champs niveau de sensibilité, qui n'est pas présent dans occtax ??
  '0',
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_observation_status),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_blurring),
  -- status_source récupéré depuis le JDD
  cd_nomenclature_source_status,
  -- cd_nomenclature_info_geo_type: type de rattachement = géoréferencement
  '1'	,
  id_municipality,
  new_count.count_min,
  new_count.count_max,
  occurrence.cd_nom,
  occurrence.nom_cite,
  occurrence.meta_v_taxref,
  occurrence.sample_number_proof,
  occurrence.digital_proof,
  occurrence.non_digital_proof,
  releve.altitude_min,
  releve.altitude_max,
  releve.geom_4326,
  ST_CENTROID(releve.geom_4326),
  releve.geom_local,
  (to_char(releve.date_min, 'DD/MM/YYYY') || ' ' || to_char(releve.date_min, 'hh:mm:ss'))::timestamp,
  (to_char(releve.date_max, 'DD/MM/YYYY') || ' ' || to_char(releve.date_max, 'hh:mm:ss'))::timestamp,
  validation.id_validator,
  validation.validation_comment,
  COALESCE (observers.observers_name, releve.observers_txt),
  occurrence.determiner,
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_determination_method),
  CONCAT('Relevé : ',releve.comment, 'Occurrence: ', occurrence.comment),
  'I'
  );

  RETURN observers.observers_id ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_releves_occtax (
    id_releve_occtax bigint NOT NULL,
    unique_id_sinp_grp uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    id_dataset integer NOT NULL,
    id_digitiser integer,
    observers_txt varchar(500),
    id_nomenclature_obs_technique integer NOT NULL,
    id_nomenclature_grp_typ integer NOT NULL,
    date_min timestamp without time zone DEFAULT now() NOT NULL,
    date_max timestamp without time zone DEFAULT now() NOT NULL,
    hour_min time,
    hour_max time,
    altitude_min integer,
    altitude_max integer,
    meta_device_entry character varying(20),
    comment text,
    geom_local public.geometry(Geometry,MYLOCALSRID),
    geom_4326 public.geometry(Geometry,4326),
    precision integer DEFAULT 100,
    CONSTRAINT enforce_dims_geom_4326 CHECK ((public.st_ndims(geom_4326) = 2)),
    CONSTRAINT enforce_dims_geom_local CHECK ((public.st_ndims(geom_local) = 2)),
    CONSTRAINT enforce_srid_geom_4326 CHECK ((public.st_srid(geom_4326) = 4326)),
    CONSTRAINT enforce_srid_geom_local CHECK ((public.st_srid(geom_local) = MYLOCALSRID))
);
COMMENT ON COLUMN t_releves_occtax.id_nomenclature_obs_technique IS 'Correspondance nomenclature CAMPANULE = technique_obs';
COMMENT ON COLUMN t_releves_occtax.id_nomenclature_grp_typ IS 'Correspondance nomenclature INPN = Type de regroupement';

CREATE SEQUENCE t_releves_occtax_id_releve_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_releves_occtax_id_releve_occtax_seq OWNED BY t_releves_occtax.id_releve_occtax;
ALTER TABLE ONLY t_releves_occtax ALTER COLUMN id_releve_occtax SET DEFAULT nextval('t_releves_occtax_id_releve_occtax_seq'::regclass);
SELECT pg_catalog.setval('t_releves_occtax_id_releve_occtax_seq', 1, false);


CREATE TABLE t_occurrences_occtax (
    id_occurrence_occtax bigint NOT NULL,
    unique_id_occurence_occtax uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    id_releve_occtax bigint NOT NULL,
    id_nomenclature_obs_meth integer NOT NULL,
    id_nomenclature_bio_condition integer NOT NULL,
    id_nomenclature_bio_status integer,
    id_nomenclature_naturalness integer,
    id_nomenclature_exist_proof integer,
    id_nomenclature_diffusion_level integer,
    id_nomenclature_observation_status integer,
    id_nomenclature_blurring integer,
    id_nomenclature_source_status integer,
    determiner character varying(255),
    id_nomenclature_determination_method integer,
    cd_nom integer,
    nom_cite character varying(255),
    meta_v_taxref character varying(50) DEFAULT 'SELECT gn_commons.get_default_parameter(''taxref_version'')',
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    comment character varying
);
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_obs_meth IS 'Correspondance nomenclature INPN = methode_obs';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_bio_condition IS 'Correspondance nomenclature INPN = etat_bio';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_bio_status IS 'Correspondance nomenclature INPN = statut_bio';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_naturalness IS 'Correspondance nomenclature INPN = naturalite';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_exist_proof IS 'Correspondance nomenclature INPN = preuve_exist';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_diffusion_level IS 'Correspondance nomenclature INPN = niv_precis';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_observation_status IS 'Correspondance nomenclature INPN = statut_obs';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_blurring IS 'Correspondance nomenclature INPN = dee_flou';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_determination_method IS 'Correspondance nomenclature GEONATURE = meth_determin';
COMMENT ON COLUMN t_occurrences_occtax.id_nomenclature_source_status IS 'Correspondance nomenclature INPN = statut_source: id = 19';

CREATE SEQUENCE t_occurrences_occtax_id_occurrence_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_occurrences_occtax_id_occurrence_occtax_seq OWNED BY t_occurrences_occtax.id_occurrence_occtax;
ALTER TABLE ONLY t_occurrences_occtax ALTER COLUMN id_occurrence_occtax SET DEFAULT nextval('t_occurrences_occtax_id_occurrence_occtax_seq'::regclass);
SELECT pg_catalog.setval('t_occurrences_occtax_id_occurrence_occtax_seq', 1, false);


CREATE TABLE cor_counting_occtax (
    id_counting_occtax bigint NOT NULL,
    unique_id_sinp_occtax uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    id_occurrence_occtax bigint NOT NULL,
    id_nomenclature_life_stage integer NOT NULL,
    id_nomenclature_sex integer NOT NULL,
    id_nomenclature_obj_count integer NOT NULL,
    id_nomenclature_type_count integer,
    count_min integer,
    count_max integer
);
COMMENT ON COLUMN cor_counting_occtax.id_nomenclature_life_stage IS 'Correspondance nomenclature INPN = stade_vie (10)';
COMMENT ON COLUMN cor_counting_occtax.id_nomenclature_sex IS 'Correspondance nomenclature INPN = sexe (9)';
COMMENT ON COLUMN cor_counting_occtax.id_nomenclature_obj_count IS 'Correspondance nomenclature INPN = obj_denbr (6)';
COMMENT ON COLUMN cor_counting_occtax.id_nomenclature_type_count IS 'Correspondance nomenclature INPN = typ_denbr (21)';


CREATE SEQUENCE cor_counting_occtax_id_counting_occtax_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE cor_counting_occtax_id_counting_occtax_seq OWNED BY t_occurrences_occtax.id_occurrence_occtax;
ALTER TABLE ONLY cor_counting_occtax ALTER COLUMN id_counting_occtax SET DEFAULT nextval('cor_counting_occtax_id_counting_occtax_seq'::regclass);
SELECT pg_catalog.setval('cor_counting_occtax_id_counting_occtax_seq', 1, false);


CREATE TABLE cor_role_releves_occtax (
    unique_id_cor_role_releve uuid NOT NULL DEFAULT public.uuid_generate_v4(),
    id_releve_occtax bigint NOT NULL,
    id_role integer NOT NULL
);


CREATE TABLE defaults_nomenclatures_value (
    mnemonique_type character varying(255) NOT NULL,
    id_organism integer NOT NULL DEFAULT 0,
    regne character varying(20) NOT NULL DEFAULT '0',
    group2_inpn character varying(255) NOT NULL DEFAULT '0',
    id_nomenclature integer NOT NULL
);


---------------
--PRIMARY KEY--
---------------
ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT pk_t_occurrences_occtax PRIMARY KEY (id_occurrence_occtax);

ALTER TABLE ONLY t_releves_occtax
    ADD CONSTRAINT pk_t_releves_occtax PRIMARY KEY (id_releve_occtax);

ALTER TABLE ONLY cor_counting_occtax
    ADD CONSTRAINT pk_cor_counting_occtax_occtax PRIMARY KEY (id_counting_occtax);

ALTER TABLE ONLY cor_role_releves_occtax
    ADD CONSTRAINT pk_cor_role_releves_occtax PRIMARY KEY (unique_id_cor_role_releve);

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT pk_pr_occtax_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_t_datasets FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_t_roles FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_releves_occtax
    ADD CONSTRAINT fk_t_releves_occtax_regroupement_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;



ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_t_releves_occtax FOREIGN KEY (id_releve_occtax) REFERENCES t_releves_occtax(id_releve_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_taxref FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_obs_meth FOREIGN KEY (id_nomenclature_obs_meth) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_bio_condition FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_bio_status FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_naturalness FOREIGN KEY (id_nomenclature_naturalness) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_exist_proof FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_diffusion_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_observation_status FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_blurring FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;
ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT fk_t_occurrences_occtax_determination_method FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_counting_occtax
    ADD CONSTRAINT fk_cor_stage_number_id_taxon FOREIGN KEY (id_occurrence_occtax) REFERENCES t_occurrences_occtax(id_occurrence_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_sexe FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_life_stage FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_obj_count FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_counting_occtax
    ADD CONSTRAINT fk_cor_counting_occtax_typ_count FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_role_releves_occtax
    ADD CONSTRAINT fk_cor_role_releves_occtax_t_releves_occtax FOREIGN KEY (id_releve_occtax) REFERENCES t_releves_occtax(id_releve_occtax) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_role_releves_occtax
    ADD CONSTRAINT fk_cor_role_releves_occtax_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY t_releves_occtax
    ADD CONSTRAINT check_t_releves_occtax_date_max CHECK (date_max >= date_min);

ALTER TABLE t_releves_occtax
  ADD CONSTRAINT check_t_releves_occtax_hour_max CHECK (hour_min <= hour_max OR date_min < date_max);

ALTER TABLE t_releves_occtax
  ADD CONSTRAINT check_t_releves_occtax_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique,'TECHNIQUE_OBS')) NOT VALID;

ALTER TABLE t_releves_occtax
  ADD CONSTRAINT check_t_releves_occtax_regroupement_typ CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ,'TYP_GRP')) NOT VALID;


ALTER TABLE ONLY t_occurrences_occtax
    ADD CONSTRAINT check_t_occurrences_occtax_cd_nom_isinbib_noms CHECK (taxonomie.check_is_inbibnoms(cd_nom)) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_meth,'METH_OBS')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_condition,'ETA_BIO')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_status,'STATUT_BIO')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_naturalness,'NATURALITE')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exist_proof,'PREUVE_EXIST')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_accur_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_diffusion_level,'NIV_PRECIS')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_obs_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_observation_status,'STATUT_OBS')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_blurring,'DEE_FLOU')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status,'STATUT_SOURCE')) NOT VALID;

ALTER TABLE t_occurrences_occtax
  ADD CONSTRAINT check_t_occurrences_occtax_determination_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_method,'METH_DETERMIN')) NOT VALID;


ALTER TABLE cor_counting_occtax
  ADD CONSTRAINT check_cor_counting_occtax_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_life_stage,'STADE_VIE')) NOT VALID;

ALTER TABLE cor_counting_occtax
  ADD CONSTRAINT check_cor_counting_occtax_sexe CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sex,'SEXE')) NOT VALID;

ALTER TABLE cor_counting_occtax
  ADD CONSTRAINT check_cor_counting_occtax_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obj_count,'OBJ_DENBR')) NOT VALID;

ALTER TABLE cor_counting_occtax
  ADD CONSTRAINT check_cor_counting_occtax_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_count,'TYP_DENBR')) NOT VALID;

ALTER TABLE cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_count_min CHECK (count_min > 0);

ALTER TABLE cor_counting_occtax
    ADD CONSTRAINT check_cor_counting_occtax_count_max CHECK (count_max >= count_min AND count_max > 0);


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type)) NOT VALID;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isgroup2inpn CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = '0'::text) NOT VALID;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isregne CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = '0'::text) NOT VALID;


----------------------
--FUNCTIONS TRIGGERS--
----------------------
-- Calcul de la sensibilité à affiner

-- CREATE OR REPLACE FUNCTION insert_occurrences_occtax()
--   RETURNS trigger AS
-- $BODY$
-- DECLARE
--     idsensitivity integer;
-- BEGIN
--     --Calculate sensitivity value
--     SELECT INTO idsensitivity ref_nomenclatures.calculate_sensitivity(new.cd_nom,new.id_nomenclature_obs_meth);
--     new.id_nomenclature_diffusion_level = idsensitivity;
--     RETURN NEW;
-- END;
-- $BODY$
--   LANGUAGE plpgsql VOLATILE
--   COST 100;

-- CREATE OR REPLACE FUNCTION update_occurrences_occtax()
--   RETURNS trigger AS
-- $BODY$
-- DECLARE
--     idsensitivity integer;
-- BEGIN
--     --Calculate sensitivity value
--     SELECT INTO idsensitivity ref_nomenclatures.calculate_sensitivity(new.cd_nom,new.id_nomenclature_obs_meth);
--     new.id_nomenclature_diffusion_level = idsensitivity;
--     RETURN NEW;
-- END;
-- $BODY$
--   LANGUAGE plpgsql VOLATILE
--   COST 100;

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_insert_counting()
  RETURNS trigger AS
  $BODY$
DECLARE
  observers integer[];
  the_id_synthese integer;
  the_id_releve integer;
  id_role_loop integer;

BEGIN

  -- recupération de l'id_releve_occtax
  SELECT INTO the_id_releve pr_occtax.id_releve_from_id_counting(NEW.id_counting_occtax::integer);
  -- recupération des observateurs
  SELECT INTO observers array_agg(id_role)
  FROM pr_occtax.cor_role_releves_occtax
  WHERE id_releve_occtax = the_id_releve;

  -- insertion en synthese du counting + occ + releve
  PERFORM pr_occtax.insert_in_synthese(NEW.id_counting_occtax::integer);

  -- recupération de l'id_synthese nouvelement créé
  SELECT INTO the_id_synthese id_synthese FROM gn_synthese.synthese WHERE unique_id_sinp = NEW.unique_id_sinp_occtax;

-- INSERTION DANS COR_ROLE_SYNTHESE
IF observers IS NOT NULL THEN
  FOREACH id_role_loop IN ARRAY observers
    LOOP
      INSERT INTO gn_synthese.cor_role_synthese (id_synthese, id_role) VALUES (the_id_synthese, id_role_loop);
    END LOOP;
  END IF;

  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- CREATE OR REPLACE FUNCTION pr_occtax.id_releve_from_id_counting(my_id_counting integer)
--   RETURNS integer AS
-- $BODY$
-- -- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
-- DECLARE the_id_releve integer[];

-- BEGIN
-- SELECT INTO the_id_releve rel.id_releve
-- FROM pr_occtax.t_releves_occtax rel
-- JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
-- JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
-- WHERE counting.cor_counting_occtax = my_id_counting;
-- RETURN the_id_releve;
-- END;
-- $BODY$
--   LANGUAGE plpgsql IMMUTABLE
--   COST 100;

-- DELETE counting
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_counting()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  the_id_synthese integer;
  nb_counting integer;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  SELECT INTO the_id_synthese id_synthese
  FROM gn_synthese.synthese
  WHERE id_source = the_id_source AND entity_source_pk_value = to_char(OLD.id_counting_occtax, 'FM9999');
  -- suppression de l'obs dans le schéma gn_synthese
  DELETE FROM gn_synthese.cor_role_synthese WHERE id_synthese = the_id_synthese;
  DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = the_id_synthese;
  DELETE FROM gn_synthese.synthese WHERE id_synthese = the_id_synthese;
  -- suppression de l'occurrence s'il n'y a plus de dénomenbrement
  SELECT INTO nb_counting count(*) FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax;
  IF nb_counting < 1 THEN
    DELETE FROM pr_occtax.t_occurrences_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax;
  END IF;

  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

  -- UPDATE counting
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_counting()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
BEGIN

  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  -- update dans la synthese
  UPDATE gn_synthese.synthese
  SET
  cd_nomenclature_life_stage = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_life_stage),
  cd_nomenclature_sex = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_sex),
  cd_nomenclature_obj_count = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_obj_count),
  cd_nomenclature_type_count = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_type_count),
  count_min = NEW.count_min,
  count_max = NEW.count_max
  WHERE id_source = the_id_source AND entity_source_pk_value = NEW.id_counting_occtax::text;
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- UPDATE Occurrence
-- TODO: SENSIBILITE NON GEREE
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  nb_counting integer;
  releve RECORD;
  counting RECORD;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  -- récupération du releve pour le commentaire à concatener
  SELECT INTO releve * FROM pr_occtax.t_releves_occtax WHERE id_releve_occtax = NEW.id_releve_occtax;

  FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = NEW.id_occurrence_occtax LOOP
    UPDATE gn_synthese.synthese SET
    cd_nomenclature_obs_meth = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_obs_meth),
    cd_nomenclature_bio_condition = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_bio_condition),
    cd_nomenclature_bio_status = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_bio_status),
    cd_nomenclature_naturalness = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_naturalness),
    cd_nomenclature_exist_proof = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_exist_proof),
    cd_nomenclature_diffusion_level = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_diffusion_level),
    cd_nomenclature_observation_status = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_observation_status),
    cd_nomenclature_blurring = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_blurring),
    cd_nomenclature_source_status = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_source_status),
    determiner = determiner,
    cd_nomenclature_determination_method = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_determination_method),
    cd_nom = NEW.cd_nom,
    nom_cite = NEW.nom_cite,
    meta_v_taxref = NEW.meta_v_taxref,
    sample_number_proof = NEW.sample_number_proof,
    digital_proof = NEW.digital_proof,
    non_digital_proof = NEW.non_digital_proof,
    comments  = CONCAT('Relevé : ',COALESCE(releve.comment, "-" ), ' Occurrence: ', COALESCE(NEW.comment, "-" ))
    WHERE id_source = the_id_source AND entity_source_pk_value = counting.id_counting_occtax::text;
  END LOOP;

  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- DELETE OCCURRENCE
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_occ()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  the_id_synthese integer;
  nb_occ integer;
  nb_counting integer;
  counting RECORD;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  -- suppression dans la synthese
  FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax LOOP
    SELECT INTO the_id_synthese id_synthese
    FROM gn_synthese.id_synthese
    WHERE id_source = the_id_source AND entity_source_pk_value = to_char(counting.id_counting_occtax, 'FM9999');
     -- suppression de l'obs dans le schéma gn_synthese
    DELETE FROM gn_synthese.cor_role_synthese WHERE id_synthese = the_id_synthese;
    DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = the_id_synthese;
    DELETE FROM gn_synthese.synthese WHERE id_synthese = the_id_synthese;  END LOOP;
  -- suppression de l'occurrence s'il n'y a plus de dénomenbrement
  SELECT INTO nb_counting count(*) FROM pr_occtax.t_occurrences_occtax WHERE id_occurrence_occtax = OLD.id_releve_occtax;
  IF nb_counting < 1 THEN
    DELETE FROM pr_occtax.t_releves_occtax WHERE id_releve_occtax = OLD.id_releve_occtax;
  END IF;

  RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- UPDATE Releve
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  occurrence RECORD;
  counting RECORD;
  role RECORD;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  FOR occurrence IN SELECT * FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = NEW.id_releve_occtax LOOP
    FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = occurrence.id_occurrence_occtax LOOP
      UPDATE gn_synthese.synthese SET
      id_dataset = NEW.id_dataset,
      observers = NEW.observers_txt,
      cd_nomenclature_obs_technique = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_obs_technique),
      cd_nomenclature_grp_typ = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_grp_typ),
      date_min = (to_char(NEW.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_min, 'hh:mm:ss'), '00:00:00'))::timestamp,
      date_max = (to_char(NEW.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_max, 'hh:mm:ss'), '00:00:00'))::timestamp,
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      comments = CONCAT('Relevé : ',NEW.comment, 'Occurrence: ', occurrence.comment),
      the_geom_local = NEW.geom_local,
      the_geom_4326 = NEW.geom_4326,
      the_geom_point = ST_CENTROID(NEW.geom_4326)
      WHERE id_source = the_id_source AND entity_source_pk_value = counting.id_counting_occtax::text;
    END LOOP;
  END LOOP;
  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- suppression d'un relevé
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  the_id_synthese integer;
  occurrence RECORD;
  counting RECORD;
BEGIN
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
    FOR occurrence IN SELECT * FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = OLD.id_releve_occtax LOOP
      FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = occurrence.id_occurrence_occtax LOOP
        SELECT INTO the_id_synthese id_synthese
        FROM gn_synthese.id_synthese
        WHERE id_source = the_id_source AND entity_source_pk_value = to_char(counting.id_counting_occtax, 'FM9999');
     -- suppression de l'obs dans le schéma gn_synthese
        DELETE FROM gn_synthese.cor_role_synthese WHERE id_synthese = the_id_synthese;
        DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = the_id_synthese;
        DELETE FROM gn_synthese.synthese WHERE id_synthese = the_id_synthese;
      END LOOP;
    END LOOP;
  RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- trigger insertion cor_role_releve_occtax
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_countings  integer[];
  the_id_counting integer;
  the_id_synthese integer;
  the_id_source integer;

BEGIN
-- recupération de l'id_source
  SELECT INTO the_id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source = 'occtax';
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_id_countings pr_occtax.get_id_counting_from_id_releve(NEW.id_releve_occtax::integer);

  IF the_id_countings IS NOT NULL THEN
    FOREACH the_id_counting IN ARRAY the_id_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE id_source = the_id_source AND entity_source_pk_value = the_id_counting::text;
      -- insertion dans cor_role_synthese pour chaque counting
      INSERT INTO gn_synthese.cor_role_synthese(id_synthese, id_role) VALUES(
        the_id_synthese,
        NEW.id_role
      );
    END LOOP;
  END IF;
RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-- trigger update cor_role_releve_occtax
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_countings  integer[];
  the_id_counting integer;
  the_id_synthese integer;
  the_id_source integer;

BEGIN

-- recupération de l'id_source
  SELECT INTO the_id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source = 'occtax';
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_id_countings pr_occtax.get_id_counting_from_id_releve(NEW.id_releve_occtax::integer);
  IF the_id_countings IS NOT NULL THEN
    FOREACH the_id_counting IN ARRAY the_id_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE id_source = the_id_source AND entity_source_pk_value = the_id_counting::text;
      -- update dans cor_role_synthese pour chaque counting
      UPDATE gn_synthese.cor_role_synthese SET
        id_synthese = the_id_synthese,
        id_role = NEW.id_role
        WHERE id_synthese = the_id_synthese AND id_role = OLD.id_role;
    END LOOP;
  END IF;
RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_countings  integer[];
  the_id_counting integer;
  the_id_synthese integer;
  the_id_source integer;

BEGIN
-- recupération de l'id_source
  SELECT INTO the_id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source = 'occtax';
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_id_countings pr_occtax.get_id_counting_from_id_releve(OLD.id_releve_occtax::integer);
  IF the_id_countings IS NOT NULL THEN
  FOREACH the_id_counting IN ARRAY the_id_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE id_source = the_id_source AND entity_source_pk_value = the_id_counting::text;
      -- suppression dans cor_role_synthese pour chaque counting
      DELETE FROM gn_synthese.cor_role_synthese
      WHERE id_synthese = the_id_synthese AND id_role = OLD.id_role;
    END LOOP;
  END IF;
RETURN NULL;
END;

$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


------------
--TRIGGERS--
------------
-- Trigger d'insertion automatique du niveau de sensibilité à partir de la fonction
-- calculate_sensitivity

-- CREATE TRIGGER tri_insert_occurrences_occtax
--   BEFORE INSERT
--   ON t_occurrences_occtax
--   FOR EACH ROW
--   EXECUTE PROCEDURE insert_occurrences_occtax();

-- CREATE TRIGGER tri_update_occurrences_occtax
--   BEFORE INSERT
--   ON t_occurrences_occtax
--   FOR EACH ROW
--   EXECUTE PROCEDURE update_occurrences_occtax();

CREATE TRIGGER tri_insert_default_validation_status
  AFTER INSERT
  ON cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_add_default_validation_status();

CREATE TRIGGER tri_log_changes_cor_counting_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_t_occurrences_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_t_releves_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_cor_role_releves_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_calculate_geom_local
  BEFORE INSERT OR UPDATE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

  -- triggers vers la synthese

CREATE TRIGGER tri_insert_synthese_cor_counting_occtax
    AFTER INSERT
    ON pr_occtax.cor_counting_occtax
    FOR EACH ROW
    EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_insert_counting();

CREATE TRIGGER tri_update_synthese_cor_counting_occtax
  AFTER UPDATE
  ON pr_occtax.cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_counting();

CREATE TRIGGER tri_delete_synthese_cor_counting_occtax
  AFTER DELETE
  ON pr_occtax.cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_counting();

CREATE TRIGGER tri_update_synthese_t_occurrence_occtax
  AFTER UPDATE
  ON pr_occtax.t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_occ();

CREATE TRIGGER tri_delete_synthese_t_occurrence_occtax
  AFTER DELETE
  ON pr_occtax.t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_occ();

CREATE TRIGGER tri_update_synthese_t_releve_occtax
  AFTER UPDATE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_releve();

CREATE TRIGGER tri_delete_synthese_t_releve_occtax
  AFTER DELETE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_releve();

CREATE TRIGGER tri_insert_synthese_cor_role_releves_occtax
  AFTER INSERT
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_insert_cor_role_releve();

CREATE TRIGGER tri_update_synthese_cor_role_releves_occtax
  AFTER UPDATE
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_cor_role_releve();

CREATE TRIGGER tri_delete_synthese_cor_role_releves_occtax
  AFTER DELETE
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_cor_role_releve();





------------
--VIEWS--
------------
--Vue représentant l'ensemble des observations du protocole occtax pour la représentation du module carte liste
DROP VIEW IF EXISTS v_releve_occtax;
CREATE OR REPLACE VIEW pr_occtax.v_releve_occtax AS
 SELECT rel.id_releve_occtax,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.meta_device_entry,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    occ.id_occurrence_occtax,
    occ.cd_nom,
    occ.nom_cite,
    t.lb_nom,
    t.nom_valide,
    t.nom_vern,
    (((t.nom_complet_html::text || ' '::text) || rel.date_min::date) || '<br/>'::text) || string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text) AS leaflet_popup,
    COALESCE ( string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text),rel.observers_txt) AS observateurs
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_occtax.cor_role_releves_occtax cor_role ON cor_role.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
  GROUP BY rel.id_releve_occtax, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.meta_device_entry, rel.comment, rel.geom_4326, rel."precision", t.cd_nom, occ.nom_cite, occ.id_occurrence_occtax, t.lb_nom, t.nom_valide, t.nom_complet_html, t.nom_vern;



--Vue représentant l'ensemble des relevés du protocole occtax pour la représentation du module carte liste
CREATE OR REPLACE VIEW pr_occtax.v_releve_list AS
 SELECT rel.id_releve_occtax,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.meta_device_entry,
    rel.comment,
    rel.geom_4326,
    rel."precision",
   dataset.dataset_name,
    string_agg(t.nom_valide::text, ','::text) AS taxons,
    (((string_agg(t.nom_valide::text, ','::text) || '<br/>'::text) || rel.date_min::date) || '<br/>'::text) || COALESCE(string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS leaflet_popup,
    COALESCE(string_agg((obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS observateurs
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_occtax.cor_role_releves_occtax cor_role ON cor_role.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
     LEFT JOIN gn_meta.t_datasets dataset ON dataset.id_dataset = rel.id_dataset
  GROUP BY dataset.dataset_name, rel.id_releve_occtax, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.meta_device_entry;

--------------------
-- ASSOCIATED DATA--
--------------------
-- Liste et structure des tables dont le contenu est tracé dans t_history_actions
-- On ne défini pas d'id pour la PK car au moment de la création du module on ne sais pas où en est la séquence
INSERT INTO gn_commons.bib_tables_location (table_desc, schema_name, table_name, pk_field, uuid_field_name) VALUES
('Dénombrement d''une occurence de taxon du module occtax', 'pr_occtax', 'cor_counting_occtax', 'id_counting_occtax', 'unique_id_sinp_occtax')
,('occurence de taxon du module occtax', 'pr_occtax', 't_occurrences_occtax', 'id_occurrence_occtax', 'unique_id_occurence_occtax')
,('Relevé correspondant à un regroupement d''occurence de taxon du module occtax', 'pr_occtax', 't_releves_occtax', 'id_releve_occtax', 'unique_id_sinp_grp')
,('Observateurs des relevés du module occtax', 'pr_occtax', 'cor_role_releves_occtax', 'unique_id_cor_role_releve', 'unique_id_cor_role_releve')
;

INSERT INTO pr_occtax.defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, id_nomenclature) VALUES
('METH_OBS',0,0,0, ref_nomenclatures.get_id_nomenclature('METH_OBS', '0'))
,('ETA_BIO',0,0,0, ref_nomenclatures.get_id_nomenclature('ETA_BIO', '2'))
,('STATUT_BIO',0,0,0, ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1'))
,('NATURALITE',0,0,0, ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'))
,('PREUVE_EXIST',0,0,0, ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'))
,('STATUT_VALID',0,0,0, ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '0'))
,('NIV_PRECIS',0,0,0, ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '5'))
,('METH_DETERMIN',0,0,0, ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '1'))
,('STADE_VIE',0,0,0, ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0'))
,('SEXE',0,0,0, ref_nomenclatures.get_id_nomenclature('SEXE', '6'))
,('OBJ_DENBR',0,0,0, ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'))
,('TYP_DENBR',0,0,0, ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'))
,('STATUT_OBS',0,0,0, ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'))
,('DEE_FLOU',0,0,0, ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'))
,('TYP_GRP',0,0,0, ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'NSP'))
,('TECHNIQUE_OBS',0,0,0, ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'))
,('STATUT_SOURCE',0, 0, 0,  ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'))
;


INSERT INTO utilisateurs.t_menus (nom_menu, desc_menu, id_application) VALUES
('Occtax observateur', 'Liste des observateurs du module Occtax de GeoNature', 14 )
;

INSERT INTO gn_synthese.t_sources (id_source, name_source, desc_source, entity_source_pk_field, url_source, target, picto_source, groupe_source, active) VALUES (1, 'Occtax', 'Données issus du module Occtax)', 'pr_occtax.cor_counting_occtax.id_counting_occtax', 'occtax/form/' , NULL, NULL, 'NONE', true);
