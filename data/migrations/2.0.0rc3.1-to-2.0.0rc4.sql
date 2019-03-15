

DROP VIEW pr_occtax.export_occtax_dlb;
DROP VIEW pr_occtax.export_occtax_sinp;


SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public;

-----------
--COMMONS--
-----------
-- Check actor is not a group
CREATE OR REPLACE FUNCTION gn_commons.role_is_group(myidrole integer)
  RETURNS boolean AS
$BODY$
DECLARE
	is_group boolean;
BEGIN
  SELECT INTO is_group groupe FROM utilisateurs.t_roles
	WHERE id_role = myidrole;
  RETURN is_group;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;
--USAGE
--SELECT gn_commons.role_is_group(1);

CREATE OR REPLACE FUNCTION gn_commons.get_id_module_bycode(mymodule text)
  RETURNS integer AS
$BODY$
DECLARE
	theidmodule integer;
BEGIN
  --Retrouver l'id du module par son nomcode.
  SELECT INTO theidmodule id_module FROM gn_commons.t_modules
	WHERE "module_code" ILIKE mymodule;
  RETURN theidmodule;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION gn_commons.fct_trg_update_synthese_validation_status()
    RETURNS trigger AS
$BODY$
-- This trigger function update validation informations in corresponding row in synthese table
BEGIN
  UPDATE gn_synthese.synthese 
  SET id_nomenclature_valid_status = NEW.id_nomenclature_valid_status,
  validation_comment = NEW.validation_comment,
  validator = (SELECT nom_role || ' ' || prenom_role FROM utilisateurs.t_roles WHERE id_role = NEW.id_validator)::text
  WHERE unique_id_sinp = NEW.uuid_attached_row;
RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TRIGGER tri_insert_synthese_update_validation_status
  AFTER INSERT
  ON gn_commons.t_validations
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_update_synthese_validation_status();

ALTER TABLE gn_commons.t_validations ADD COLUMN validation_auto boolean;
ALTER TABLE gn_commons.t_validations ALTER COLUMN validation_auto SET DEFAULT true;
COMMENT ON COLUMN gn_commons.t_validations.validation_auto IS 'Définir si la validation est manuelle ou automatique';
UPDATE gn_commons.t_validations SET validation_auto = true;
ALTER TABLE gn_commons.t_validations ALTER COLUMN validation_auto SET NOT NULL;


ALTER TABLE gn_commons.t_modules ADD COLUMN module_code character varying(50);

-- UPDATE colonne module_code
UPDATE gn_commons.t_modules SET module_code = 'OCCTAX' WHERE module_name ILIKE 'occtax'; 
UPDATE gn_commons.t_modules SET module_code = 'ADMIN' WHERE module_name ILIKE 'admin'; 
UPDATE gn_commons.t_modules SET module_code = 'EXPORTS' WHERE module_name ILIKE 'exports'; 
UPDATE gn_commons.t_modules SET module_code = 'VALIDATION' WHERE module_name ILIKE 'gn_module_validation'; 
UPDATE gn_commons.t_modules SET module_code = 'SFT' WHERE module_name ILIKE 'suivi_flore_territoire'; 
UPDATE gn_commons.t_modules SET module_code = 'SUIVI_OEDIC' WHERE module_name ILIKE 'suivi_oedic'; 
UPDATE gn_commons.t_modules SET module_code = 'SUIVI_CHIRO' WHERE module_name ILIKE 'suivi_chiro'; 
UPDATE gn_commons.t_modules SET module_code = 'SYNTHESE' WHERE module_name ILIKE 'synthese'; 

ALTER TABLE gn_commons.t_modules DROP COLUMN module_name;
ALTER TABLE gn_commons.t_modules DROP CONSTRAINT fk_t_modules_utilisateurs_t_applications;


CREATE SEQUENCE gn_commons.t_modules_id_module_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gn_commons.t_modules_id_module_seq OWNED BY gn_commons.t_modules.id_module;
ALTER TABLE ONLY gn_commons.t_modules ALTER COLUMN id_module SET DEFAULT nextval('gn_commons.t_modules_id_module_seq'::regclass);

SELECT pg_catalog.setval('gn_commons.t_modules_id_module_seq', (SELECT MAX(id_module + 1) FROM gn_commons.t_modules), TRUE);

ALTER TABLE gn_commons.t_modules ALTER COLUMN module_code SET NOT NULL;

-- Insertion du module parent: GEONATURE
INSERT INTO gn_commons.t_modules(id_module, module_code, module_label, module_picto, module_desc, module_path, module_target, module_comment, active_frontend, active_backend) 
SELECT id_application, 'GEONATURE', 'GeoNature', '', 'Module parent de tous les modules sur lequel on peut associer un CRUVED. NB: mettre active_frontend et active_backend à false pour qu''il ne s''affiche pas dans la barre latérale des modules', '/geonature', '', '', FALSE, FALSE
FROM utilisateurs.t_applications
WHERE code_application = 'GN'
;


--------
--META--
--------

DO $$
BEGIN
  ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
      ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));

  ALTER TABLE ONLY gn_meta.cor_dataset_actor
      ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));
      
  
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE ' Vous avez ajouter des roles qui sont des groupes dans gn_meta.cor_acquisition_framework_actor ou gn_meta.cor_dataset_actor
    , ce qui est désormais interdit.

    Veuillez remplacer les groupes par des utilisateurs ou des organismes dans ces deux tables puis relancer
    les commandes suivantes:

    ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
        ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));

    ALTER TABLE ONLY gn_meta.cor_dataset_actor
        ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));
    ';
  END;
$$;

------------
--SYNTHESE--
------------
ALTER TABLE gn_synthese.synthese
  ADD COLUMN id_module integer;

COMMENT ON COLUMN gn_synthese.synthese.id_module
  IS 'Permet d''identifier le module qui a permis la création de l''enregistrement. Ce champ est en lien avec utilisateurs.t_applications et permet de gérer le CRUVED grace à la table utilisateurs.cor_app_privileges';

COMMENT ON COLUMN gn_synthese.synthese.id_source
  IS 'Permet d''identifier la localisation de l''enregistrement correspondant dans les schémas et tables de la base';

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE;

UPDATE gn_synthese.synthese 
SET id_module = (SELECT gn_commons.get_id_module_bycode('OCCTAX'))
WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source = 'Occtax' LIMIT 1);
--Si vous avez insérer des données provenant d'une autre source que occtax, 
--vous devez gérer vous même le champ id_module des enregistrements correspondants.

ALTER TABLE gn_synthese.t_sources ADD COLUMN validable boolean;
ALTER TABLE gn_synthese.t_sources ALTER COLUMN validable SET DEFAULT true;
COMMENT ON COLUMN gn_synthese.t_sources.validable IS 'Définir si la validation des données d''une source est possile ou non';
UPDATE gn_synthese.t_sources SET validable = true;
ALTER TABLE gn_synthese.t_sources ALTER COLUMN validable SET NOT NULL;

CREATE OR REPLACE FUNCTION gn_synthese.get_ids_synthese_for_user_action(myuser integer, myaction text)
  RETURNS integer[] AS
$BODY$
-- The fonction return a array of id_synthese for the given id_role and CRUVED action
-- USAGE : SELECT gn_synthese.get_ids_synthese_for_user_action(1,'U');
DECLARE
  idssynthese integer[];
BEGIN
WITH apps_avalaible AS(
	SELECT id_application, max(tag_object_code) AS portee FROM (
	  SELECT a.id_application, v.tag_object_code
	  FROM utilisateurs.t_applications a
	  JOIN utilisateurs.v_usersaction_forall_gn_modules v ON a.id_parent = v.id_application
	  WHERE id_role = myuser
	  AND tag_action_code = myaction
	  UNION
	  SELECT id_application, tag_object_code
	  FROM utilisateurs.v_usersaction_forall_gn_modules
	  WHERE id_role = myuser
	  AND tag_action_code = myaction
	) a
	GROUP BY id_application
)
SELECT INTO idssynthese array_agg(DISTINCT s.id_synthese)
FROM gn_synthese.synthese s
LEFT JOIN gn_synthese.cor_observer_synthese cos ON cos.id_synthese = s.id_synthese
LEFT JOIN gn_meta.cor_dataset_actor cda ON cda.id_dataset = s.id_dataset
--JOIN apps_avalaible a ON a.id_application = s.id_module
WHERE s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 3::text)
OR (cda.id_organism = (SELECT id_organisme FROM utilisateurs.t_roles WHERE id_role = myuser) AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 2::text))
OR (s.id_digitiser = myuser AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 1::text))
OR (cos.id_role = myuser AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 1::text))
OR (cda.id_role = myuser AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 1::text))
;

RETURN idssynthese;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


-----------
--REF_GEO--
-----------
-- Change the storage type to improve performance
ALTER TABLE ref_geo.l_areas ALTER COLUMN geom SET STORAGE EXTERNAL;
-- Force the column to rewrite = 5s
UPDATE ref_geo.l_areas SET geom = ST_SetSRID(geom, 2154);
-- Minimize table size (with pgAdmin, use this sql commande separately)
-- VACUUM FULL ref_geo.l_areas;


----------
--OCCTAX--
----------

CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
  RETURNS integer[] AS
$BODY$
DECLARE
new_count RECORD;
occurrence RECORD;
releve RECORD;
id_source integer;
id_module integer;
validation RECORD;
id_nomenclature_source_status integer;
myobservers RECORD;
id_role_loop integer;

BEGIN
--recupération du counting à partir de son ID
SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;

-- Récupération de l'occurrence
SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;

-- Récupération du relevé
SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;

-- Récupération de la source
SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source ILIKE 'occtax';

-- Récupération de l'id_module
SELECT INTO id_module gn_commons.get_id_module_bycode('OCCTAX');

-- Récupération du status de validation du counting dans la table t_validation
SELECT INTO validation v.*, CONCAT(r.nom_role, r.prenom_role) as validator_full_name
FROM gn_commons.t_validations v
LEFT JOIN utilisateurs.t_roles r ON v.id_validator = r.id_role
WHERE uuid_attached_row = new_count.unique_id_sinp_occtax;

-- Récupération du status_source depuis le JDD
SELECT INTO id_nomenclature_source_status d.id_nomenclature_source_status FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

--Récupération et formatage des observateurs
SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
array_agg(rol.id_role) AS observers_id
FROM pr_occtax.cor_role_releves_occtax cor
JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
WHERE cor.id_releve_occtax = releve.id_releve_occtax;

-- insertion dans la synthese
INSERT INTO gn_synthese.synthese (
unique_id_sinp,
unique_id_sinp_grp,
id_source,
entity_source_pk_value,
id_dataset,
id_module,
id_nomenclature_geo_object_nature,
id_nomenclature_grp_typ,
id_nomenclature_obs_meth,
id_nomenclature_obs_technique,
id_nomenclature_bio_status,
id_nomenclature_bio_condition,
id_nomenclature_naturalness,
id_nomenclature_exist_proof,
id_nomenclature_valid_status,
id_nomenclature_diffusion_level,
id_nomenclature_life_stage,
id_nomenclature_sex,
id_nomenclature_obj_count,
id_nomenclature_type_count,
id_nomenclature_observation_status,
id_nomenclature_blurring,
id_nomenclature_source_status,
id_nomenclature_info_geo_type,
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
date_min,
date_max,
validator,
validation_comment,
observers,
determiner,
id_digitiser,
id_nomenclature_determination_method,
comments,
last_action
)
VALUES(
  new_count.unique_id_sinp_occtax,
  releve.unique_id_sinp_grp,
  id_source,
  new_count.id_counting_occtax,
  releve.id_dataset,
  id_module,
  --nature de l'objet geo: id_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - NSP par défault
  pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'),
  releve.id_nomenclature_grp_typ,
  occurrence.id_nomenclature_obs_meth,
  releve.id_nomenclature_obs_technique,
  occurrence.id_nomenclature_bio_status,
  occurrence.id_nomenclature_bio_condition,
  occurrence.id_nomenclature_naturalness,
  occurrence.id_nomenclature_exist_proof,
    -- statut de validation récupérer à partir de gn_commons.t_validations
  validation.id_nomenclature_valid_status,
  occurrence.id_nomenclature_diffusion_level,
  new_count.id_nomenclature_life_stage,
  new_count.id_nomenclature_sex,
  new_count.id_nomenclature_obj_count,
  new_count.id_nomenclature_type_count,
  occurrence.id_nomenclature_observation_status,
  occurrence.id_nomenclature_blurring,
  -- status_source récupéré depuis le JDD
  id_nomenclature_source_status,
  -- id_nomenclature_info_geo_type: type de rattachement = géoréferencement
  ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')	,
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
  (to_char(releve.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_min, 'HH24:MI:SS'),'00:00:00'))::timestamp,
  (to_char(releve.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_max, 'HH24:MI:SS'),'00:00:00'))::timestamp,
  validation.validator_full_name,
  validation.validation_comment,
  COALESCE (myobservers.observers_name, releve.observers_txt),
  occurrence.determiner,
  releve.id_digitiser,
  occurrence.id_nomenclature_determination_method,
  CONCAT(COALESCE('Relevé : '||releve.comment || ' / ', NULL ), COALESCE('Occurrence : '||occurrence.comment, NULL)),
  'I'
);

  RETURN myobservers.observers_id ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


         
         
-- recreation de la vue export_sinp
         
 CREATE OR REPLACE VIEW pr_occtax.export_occtax_sinp AS 
 SELECT ccc.unique_id_sinp_occtax AS "permId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_observation_status) AS "statObs",
    occ.nom_cite AS "nomCite",
    rel.date_min::date AS "dateDebut",
    rel.date_max::date AS "dateFin",
    rel.hour_min AS "heureDebut",
    rel.hour_max AS "heureFin",
    rel.altitude_max AS "altMax",
    rel.altitude_min AS "altMin",
    occ.cd_nom AS "cdNom",
    taxonomie.find_cdref(occ.cd_nom) AS "cdRef",
    gn_commons.get_default_parameter('taxref_version'::text, NULL::integer) AS "versionTAXREF",
    rel.date_min AS datedet,
    'NSP'::text AS "dSPublique",
    d.unique_dataset_id AS "jddMetadonneeDEEId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status) AS "statSource",
    '0'::text AS "diffusionNiveauPrecision",
    ccc.unique_id_sinp_occtax AS "idOrigine",
    d.dataset_name AS "jddCode",
    d.unique_dataset_id AS "jddId",
    NULL::text AS "refBiblio",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth) AS "obsMeth",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition) AS "ocEtatBio",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text::character varying) AS "ocNat",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex) AS "ocSex",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage) AS "ocStade",
    '0'::text AS "ocBiogeo",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status), '0'::text::character varying) AS "ocStatBio",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof), '0'::text::character varying) AS "preuveOui",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method, 'fr'::character varying) AS "ocMethDet",
    occ.digital_proof AS "preuvNum",
    occ.non_digital_proof AS "preuvNoNum",
    rel.comment AS "obsCtx",
    occ.comment as "obsDescr",
    rel.unique_id_sinp_grp AS "permIdGrp",
    'Relevé'::text AS "methGrp",
    'OBS'::text AS "typGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text || r.prenom_role::text), ','::text), rel.observers_txt::text) AS "obsId",
    COALESCE(string_agg(DISTINCT o.nom_organisme::text, ','::text), 'NSP'::text) AS "obsNomOrg",
    COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
    'NSP'::text AS "detNomOrg",
    'NSP'::text AS "orgGestDat",
    st_astext(rel.geom_4326) AS "WKT",
    'In'::text AS "natObjGeo",
    rel.date_min,
    rel.date_max,
    rel.id_dataset,
    rel.id_releve_occtax,
    occ.id_occurrence_occtax,
    rel.id_digitiser,
    rel.geom_4326
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
  GROUP BY 
    ccc.unique_id_sinp_occtax
    , d.unique_dataset_id
    , occ.id_occurrence_occtax
    , occ.id_nomenclature_bio_condition
    , occ.id_nomenclature_naturalness
    , ccc.id_nomenclature_sex
    , ccc.id_nomenclature_life_stage
    , occ.id_nomenclature_bio_status
    , occ.id_nomenclature_exist_proof
    , occ.id_nomenclature_determination_method
    , rel.unique_id_sinp_grp
    , d.id_nomenclature_source_status
    , occ.id_nomenclature_blurring
    , occ.id_nomenclature_diffusion_level
    , occ.nom_cite
    , rel.id_releve_occtax
    , rel.date_min
    , rel.date_max
    , rel.hour_min
    , rel.hour_max
    , rel.altitude_max
    , rel.altitude_min
    , rel.id_digitiser
    , occ.cd_nom
    , occ.id_nomenclature_observation_status
    , taxonomie.find_cdref(occ.cd_nom)
    , gn_commons.get_default_parameter('taxref_version'::text, NULL::integer)
    , rel.comment
    , rel.id_dataset
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status)
    , ccc.id_counting_occtax
    , d.dataset_name
    , occ.determiner
    , occ.comment
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof)
    , ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method)
    , occ.digital_proof
    , occ.non_digital_proof
    , ccc.count_max
    , ccc.count_min
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count)
    , rel.observers_txt
    , rel.geom_4326;
   


-- Creation de GN_PERMISSIONS

CREATE SCHEMA gn_permissions;

---------------
-- FUNCTION -- 
---------------

CREATE OR REPLACE FUNCTION gn_permissions.does_user_have_scope_permission
(
 myuser integer,
 mycodemodule character varying,
 myactioncode character varying,
 myscope integer
)
 RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module with its scope level
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_persmissions.does_user_have_scope_permission(requested_userid,requested_actionid,requested_module_code,requested_scope);
-- SAMPLE : SELECT gn_permissions.does_user_have_scope_permission(2,'OCCTAX','R',3);
BEGIN
    IF myactioncode IN (
  SELECT code_action
    FROM gn_permissions.v_users_permissions
    WHERE id_role = myuser AND module_code = mycodemodule AND code_action = myactioncode AND value_filter::int >= myscope AND code_filter_type = 'SCOPE') THEN
    RETURN true;
END
IF;
 RETURN false;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;


CREATE OR REPLACE FUNCTION gn_permissions.user_max_accessible_data_level_in_module
(
 myuser integer,
 myactioncode character varying,
 mymodulecode character varying)
 RETURNS integer AS
$BODY$
DECLARE
 themaxscopelevel integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_permissions.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE :SELECT gn_permissions.user_max_accessible_data_level_in_module(2,'U','GEONATURE');
BEGIN
    SELECT max(value_filter::int)
    INTO themaxscopelevel
    FROM gn_permissions.v_users_permissions
    WHERE id_role = myuser AND module_code = mymodulecode AND code_action = myactioncode;
    RETURN themaxscopelevel;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;

CREATE OR REPLACE FUNCTION gn_permissions.cruved_for_user_in_module
(
 myuser integer,
 mymodulecode character varying
)
 RETURNS json AS
$BODY$
-- the function return user's CRUVED in the requested module
-- warning: the function not return the parent CRUVED but only the module cruved - no heritage
-- USAGE : SELECT gn_permissions..cruved_for_user_in_module(requested_userid,requested_moduleid);
-- SAMPLE : SELECT gn_permissions..cruved_for_user_in_module(2,3);
DECLARE
 thecruved json;
BEGIN
    SELECT array_to_json(array_agg(row))
    INTO thecruved
    FROM (
  SELECT code_action AS action, max(value_filter::int) AS level
        FROM gn_permissions.v_users_permissions
        WHERE id_role = myuser AND module_code = mymodulecode AND code_filter_type = 'SCOPE'
        GROUP BY code_action) row;
    RETURN thecruved;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;


CREATE OR REPLACE FUNCTION gn_permissions.get_id_object (mycodeobject character varying)
  RETURNS int AS
$BODY$
BEGIN
RETURN (SELECT id_object
FROM gn_permissions.t_objects
WHERE code_object = mycodeobject);
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;

CREATE OR REPLACE FUNCTION gn_permissions.fct_tri_does_user_have_already_scope_filter()
  RETURNS trigger AS
$BODY$
-- Check if a role has already a SCOPE permission for an action/module/object
-- use in constraint to force not set multiple scope permission on the same action/module/object
DECLARE 
the_code_filter_type character varying;
the_nb_permission integer;
BEGIN
 SELECT INTO the_code_filter_type bib.code_filter_type
 FROM gn_permissions.t_filters f
 JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type
 WHERE f.id_filter = NEW.id_filter
;
-- if the filter type is NOT SCOPE, its OK to set multiple permissions
IF the_code_filter_type != 'SCOPE' THEN 
RETURN NEW;
-- if the new filter is 'SCOPE TYPE', check if there is not already a permission for this
-- action/module/object/role
ELSE
    SELECT INTO the_nb_permission count(perm.id_permission)
    FROM gn_permissions.cor_role_action_filter_module_object perm
    JOIN gn_permissions.t_filters f ON f.id_filter = perm.id_filter
    JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type AND bib.code_filter_type = 'SCOPE' 
    WHERE id_role=NEW.id_role AND id_action=NEW.id_action AND id_module=NEW.id_module AND id_object=NEW.id_object;

 -- if its an insert 0 row must be present, if its an update 1 row must be present
  IF(TG_OP = 'INSERT' AND the_nb_permission = 0) OR (TG_OP = 'UPDATE' AND the_nb_permission = 1) THEN
        RETURN NEW;
    END IF;
    BEGIN
        RAISE EXCEPTION 'ATTENTION: il existe déjà un enregistrement de type SCOPE pour le role % l''action % sur le module % et l''objet % . Il est interdit de définit plusieurs portées à un role pour le même action sur un module et un objet', NEW.id_role, NEW.id_action, NEW.id_module, NEW.id_object ;
    END;
  

END IF;

END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


---------
--TABLE--
---------


CREATE TABLE gn_permissions.t_actions(
    id_action serial NOT NULL,
    code_action character varying(50) NOT NULL,
    description_action text
);

CREATE TABLE gn_permissions.bib_filters_type(
    id_filter_type serial NOT NULL,
    code_filter_type character varying(50) NOT NULL,
    label_filter_type character varying(255) NOT NULL,
    description_filter_type text
);

CREATE TABLE gn_permissions.t_filters(
    id_filter serial NOT NULL,
    label_filter character varying(255) NOT NULL,
    value_filter text NOT NULL,
    description_filter text,
    id_filter_type integer NOT NULL
);

CREATE TABLE gn_permissions.t_objects(
    id_object serial NOT NULL,
    code_object character varying(50) NOT NULL,
    description_object text
);

-- un objet peut être utilisé dans plusieurs modules
-- ex: TDataset en lecture dans occtax, admin ...
CREATE TABLE gn_permissions.cor_object_module(
    id_cor_object_module serial NOT NULL,
    id_object integer NOT NULL,
    id_module integer NOT NULL
);

CREATE TABLE gn_permissions.cor_role_action_filter_module_object
(
    id_permission serial NOT NULL,
    id_role integer NOT NULL,
    id_action integer NOT NULL,
    id_filter integer NOT NULL,
    id_module integer NOT NULL,
    id_object integer NOT NULL DEFAULT gn_permissions.get_id_object('ALL')
);


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY gn_permissions.t_actions
    ADD CONSTRAINT pk_t_actions PRIMARY KEY (id_action);

ALTER TABLE ONLY gn_permissions.t_filters
    ADD CONSTRAINT pk_t_filters PRIMARY KEY (id_filter);

ALTER TABLE ONLY gn_permissions.bib_filters_type
    ADD CONSTRAINT pk_bib_filters_type PRIMARY KEY (id_filter_type);

ALTER TABLE ONLY gn_permissions.t_objects
    ADD CONSTRAINT pk_t_objects PRIMARY KEY (id_object);

ALTER TABLE ONLY gn_permissions.cor_object_module
    ADD CONSTRAINT pk_cor_object_module PRIMARY KEY (id_cor_object_module);

ALTER TABLE ONLY gn_permissions.cor_role_action_filter_module_object
ADD CONSTRAINT pk_cor_r_a_f_m_o PRIMARY KEY
(id_permission);
---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY gn_permissions.t_filters
  ADD CONSTRAINT  fk_t_filters_id_filter_type FOREIGN KEY (id_filter_type) REFERENCES gn_permissions.bib_filters_type(id_filter_type) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_permissions.cor_object_module
  ADD CONSTRAINT  fk_cor_object_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.cor_object_module
  ADD CONSTRAINT  fk_cor_object_module_id_object FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_action FOREIGN KEY (id_action) REFERENCES gn_permissions.t_actions(id_action) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_permissions.cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_filter FOREIGN KEY (id_filter) REFERENCES gn_permissions.t_filters(id_filter) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_permissions.cor_role_action_filter_module_object
  ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_object FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE;

-- migration utilisateurs vers gn_permissions:

-- Vue permettant de retourner les utilisateurs et leur CRUVED pour chaque modules GeoNature
CREATE OR REPLACE VIEW gn_permissions.v_roles_permissions AS
WITH
    p_user_permission
    AS
    (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            u.groupe,
            u.id_organisme,
            c_1.id_action,
            c_1.id_filter,
            c_1.id_module,
            c_1.id_object,
            c_1.id_permission
        FROM utilisateurs.t_roles u
            JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = u.id_role
        WHERE u.groupe = false
    ),
    p_groupe_permission
    AS
    (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            u.groupe,
            u.id_organisme,
            c_1.id_action,
            c_1.id_filter,
            c_1.id_module,
            c_1.id_object,
            c_1.id_permission
        FROM utilisateurs.t_roles u
            JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role OR g.id_role_groupe = u.id_role
            JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = g.id_role_groupe
        WHERE (g.id_role_groupe IN ( SELECT DISTINCT cor_roles.id_role_groupe
        FROM utilisateurs.cor_roles))
    ),
    all_user_permission
    AS
    (
                    SELECT p_user_permission.id_role,
                p_user_permission.nom_role,
                p_user_permission.prenom_role,
                p_user_permission.groupe,
                p_user_permission.id_organisme,
                p_user_permission.id_action,
                p_user_permission.id_filter,
                p_user_permission.id_module,
                p_user_permission.id_object,
                p_user_permission.id_permission
            FROM p_user_permission
        UNION
            SELECT p_groupe_permission.id_role,
                p_groupe_permission.nom_role,
                p_groupe_permission.prenom_role,
                p_groupe_permission.groupe,
                p_groupe_permission.id_organisme,
                p_groupe_permission.id_action,
                p_groupe_permission.id_filter,
                p_groupe_permission.id_module,
                p_groupe_permission.id_object,
                p_groupe_permission.id_permission
            FROM p_groupe_permission
    )
SELECT v.id_role,
    v.nom_role,
    v.prenom_role,
    v.id_organisme,
    v.id_module,
    modules.module_code,
    obj.code_object,
    v.id_action,
    v.id_filter,
    actions.code_action,
    actions.description_action,
    filters.value_filter,
    filters.label_filter,
    filter_type.code_filter_type,
    filter_type.id_filter_type,
    v.id_permission
FROM all_user_permission v
    JOIN gn_permissions.t_actions actions ON actions.id_action = v.id_action
    JOIN gn_permissions.t_filters filters ON filters.id_filter = v.id_filter
    JOIN gn_permissions.t_objects obj ON obj.id_object = v.id_object
    JOIN gn_permissions.bib_filters_type filter_type ON filters.id_filter_type = filter_type.id_filter_type
    JOIN gn_commons.t_modules modules ON modules.id_module = v.id_module;



----------
-- DATA --
----------


INSERT INTO gn_permissions.t_actions(code_action, description_action) VALUES
    ('C', 'Action de créer'),
    ('R', 'Action de lire'),
    ('U', 'Action de mettre à jour'),
    ('V', 'Action de valider'),
    ('E', 'Action d''exporter'),
    ('D', 'Action de supprimer')
;

INSERT INTO gn_permissions.bib_filters_type(code_filter_type, label_filter_type, description_filter_type) VALUES
    ('SCOPE', 'Filtre de type portée','Filtre de type portée'),
    ('SENSITIVITY', 'Filtre de type sensibilité', 'Filtre de type sensibilité'),
    ('GEOGRAPHIC', 'Filtre de type géographique', 'Filtre de type géographique')
;

INSERT INTO gn_permissions.t_filters (value_filter, label_filter, description_filter, id_filter_type)
SELECT '0', 'Aucune donnée', 'Aucune donnée', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO gn_permissions.t_filters (value_filter, label_filter, description_filter, id_filter_type)
SELECT '1', 'Mes données','Mes données', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO gn_permissions.t_filters (value_filter, label_filter, description_filter, id_filter_type)
SELECT '2', 'Les données de mon organisme', 'Les données de mon organisme', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO gn_permissions.t_filters (value_filter, label_filter, description_filter, id_filter_type)
SELECT '3', 'Toutes les données', 'Toutes les données', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO gn_permissions.t_objects
    (code_object, description_object)
VALUES
    ('ALL', 'Représente tous les objets d''un module'),
    ('METADATA', 'Gestion du backoffice des métadonnées'),
    ('PERMISSIONS', 'Gestion du backoffice des permissions'),
    ('NOMENCLATURES', 'Gestion du backoffice des nomenclature')
;

-- objets du module ADMIN
INSERT INTO gn_permissions.cor_object_module
    (id_object, id_module)
SELECT 2, id_module
FROM gn_commons.t_modules
WHERE module_code ILIKE 'ADMIN';

INSERT INTO gn_permissions.cor_object_module
    (id_object, id_module)
SELECT 3, id_module
FROM gn_commons.t_modules
WHERE module_code ILIKE 'ADMIN';

INSERT INTO gn_permissions.cor_object_module
    (id_object, id_module)
SELECT 4, id_module
FROM gn_commons.t_modules
WHERE module_code ILIKE 'ADMIN';


-- Utilisateurs.cor_app_privileges vers gn_persmissions.cor_role_action_filter_module_object
INSERT INTO gn_permissions.cor_role_action_filter_module_object (id_role, id_action, id_filter, id_module, id_object)
    SELECT 
    id_role,
    CASE 
    WHEN id_tag_action =  11 THEN 1
    WHEN id_tag_action =  12 THEN 2
    WHEN id_tag_action =  13 THEN 3
    WHEN id_tag_action =  14 THEN 4
    WHEN id_tag_action =  15 THEN 5
    WHEN id_tag_action =  16 THEN 6
    END AS id_action
    ,
    CASE 
    WHEN id_tag_object = 20 THEN 1
    WHEN id_tag_object = 21 THEN 2
    WHEN id_tag_object = 22 THEN 3
    WHEN id_tag_object = 23 THEN 4
    END AS id_filter,
    cor.id_application,
    1
    FROM save.cor_app_privileges cor
    JOIN utilisateurs.t_applications app ON app.id_application = cor.id_application
    WHERE nom_application ilike 'geonature' OR nom_application ilike 'application geonature' OR nom_application ILIKE 'occtax'
;



-- Prévention des doublons
DELETE 
FROM utilisateurs.cor_role_app_profil cor WHERE id_application = (
SELECT id_application FROM utilisateurs.t_applications WHERE nom_application ilike 'geonature' OR nom_application ilike 'application geonature'
);


DO
$$
BEGIN
-- insertion des utilisateurs qui avaient des droits dans cor_app_privilege dans cor_role_app_profil
INSERT INTO utilisateurs.cor_role_app_profil
SELECT DISTINCT id_role, app.id_application, 1
FROM save.cor_app_privileges cor
JOIN utilisateurs.t_applications app ON app.id_application = cor.id_application
WHERE nom_application ILIKE 'geonature' OR nom_application = 'application geonature';
END
$$;




-- GROUPE ADMIN acceder à l'admin
INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 1, 4, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 2, 4, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 3, 4, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 4, 4, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 5, 4, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 6, 4, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';


-- GROUPE ADMIN peut gérer les permissions du backoffice
INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 1, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'PERMISSIONS';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 2, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'PERMISSIONS';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 3, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'PERMISSIONS';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 4, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'PERMISSIONS';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 5, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'PERMISSIONS';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 6, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'PERMISSIONS';


-- GROUPE ADMIN peut gérer les métadonnées du backoffice
INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 1, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 2, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 3, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 4, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 5, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 6, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'METADATA';


-- GROUPE ADMIN peut gérer les nomenclatures
INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 1, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'NOMENCLATURES';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 2, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'NOMENCLATURES';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 3, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'NOMENCLATURES';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 4, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'NOMENCLATURES';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 5, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'NOMENCLATURES';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 9, 6, 4, id_module, id_object
FROM gn_commons.t_modules, gn_permissions.t_objects
WHERE module_code = 'ADMIN' AND code_object = 'NOMENCLATURES';


-- Groupe en poste, n'a pas accès à l'admin
INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 7, 1, 1, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 7, 2, 1, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 7, 3, 1, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 7, 4, 1, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 7, 5, 1, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module, id_object)
SELECT 7, 6, 1, id_module, 1
FROM gn_commons.t_modules
WHERE module_code = 'ADMIN';

-- 
-- suppression des modules GeoNature de la table t_applications
DELETE
FROM utilisateurs.t_applications
WHERE id_parent = (
    SELECT id_application FROM utilisateurs.t_applications
    WHERE nom_application ILIKE 'geonature' or nom_application ilike 'application geonature'
);


---------------
-- TRIGGERS ---
---------------

DROP TRIGGER IF EXISTS tri_check_no_multiple_scope_perm ON gn_permissions.cor_role_action_filter_module_object;
CREATE TRIGGER tri_check_no_multiple_scope_perm
  BEFORE INSERT OR UPDATE
  ON gn_permissions.cor_role_action_filter_module_object
  FOR EACH ROW
  EXECUTE PROCEDURE gn_permissions.fct_tri_does_user_have_already_scope_filter();



-- Mise en place du trigrammes

CREATE INDEX i_taxons_synthese_autocomplete_cd_nom
  ON gn_synthese.taxons_synthese_autocomplete (cd_nom ASC NULLS LAST);

CREATE INDEX i_tri_taxons_synthese_autocomplete_search_name 
  ON gn_synthese.taxons_synthese_autocomplete USING GIST (search_name gist_trgm_ops);
