SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public;

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

