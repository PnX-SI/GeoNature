

DROP VIEW pr_occtax.export_occtax_dlb;
DROP VIEW pr_occtax.export_occtax_sinp;


SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public;

----------
--OCCTAX--
----------
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
    rel.geom_4326,
    st_astext(rel.geom_4326) AS "WKT",
    'In'::text AS "natObjGeo"
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
    ,d.unique_dataset_id
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
    , rel.date_min
    , rel.date_max
    , rel.hour_min
    , rel.hour_max
    , rel.altitude_max
    , rel.altitude_min
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

CREATE OR REPLACE FUNCTION gn_commons.get_id_module_byname(mymodule text)
  RETURNS integer AS
$BODY$
DECLARE
	theidmodule integer;
BEGIN
  --Retrouver l'id du module par son nom. L'id_module est le même que l'id_application correspondant dans utilisateurs.t_applications
  SELECT INTO theidmodule id_module FROM gn_commons.t_modules
	WHERE "module_name" ILIKE mymodule;
  RETURN theidmodule;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


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
    ADD CONSTRAINT fk_synthese_id_module FOREIGN KEY (id_module) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;

UPDATE gn_synthese.synthese 
SET id_module = (SELECT gn_commons.get_id_module_byname('occtax'))
WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source = 'Occtax');
--Si vous avez insérer des données provenant d'une autre source que occtax, 
--vous devez gérer vous même le champ id_module des enregistrements correspondants.


--------
--META--
--------
ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));

ALTER TABLE ONLY gn_meta.cor_dataset_actor
    ADD CONSTRAINT check_id_role_not_group CHECK (NOT gn_commons.role_is_group(id_role));
