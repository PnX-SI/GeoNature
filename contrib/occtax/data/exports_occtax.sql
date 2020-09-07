SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = public;

CREATE OR REPLACE VIEW pr_occtax.export_occtax AS 
 SELECT 
    rel.unique_id_sinp_grp as "idSINPRegroupement",
    ref_nomenclatures.get_cd_nomenclature(rel.id_nomenclature_grp_typ) AS "typGrp",
    rel.grp_method AS "methGrp",
    ccc.unique_id_sinp_occtax AS "permId",
    ccc.id_counting_occtax AS "idOrigine",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_observation_status) AS "statObs",
    occ.nom_cite AS "nomCite",
    to_char(rel.date_min, 'YYYY-MM-DD'::text) AS "dateDebut",
    to_char(rel.date_max, 'YYYY-MM-DD'::text) AS "dateFin",
    rel.hour_min AS "heureDebut",
    rel.hour_max AS "heureFin",
    rel.altitude_max AS "altMax",
    rel.altitude_min AS "altMin",
    rel.depth_min AS "profMin",
    rel.depth_max AS "profMax",
    occ.cd_nom AS "cdNom",
    tax.cd_ref AS "cdRef",
    ref_nomenclatures.get_nomenclature_label(d.id_nomenclature_data_origin) AS "dSPublique",
    d.unique_dataset_id AS "jddMetaId",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_source_status) AS "statSource",
    d.dataset_name AS "jddCode",
    d.unique_dataset_id AS "jddId",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_obs_technique) AS "obsTech",
    ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_tech_collect_campanule) AS "techCollect",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_condition) AS "ocEtatBio",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_naturalness) AS "ocNat",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_sex) AS "ocSex",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_life_stage) AS "ocStade",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_bio_status) AS "ocStatBio",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_exist_proof) AS "preuveOui",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method) AS "ocMethDet",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_behaviour) AS "occComp",
    occ.digital_proof AS "preuvNum",
    occ.non_digital_proof AS "preuvNoNum",
    rel.comment AS "obsCtx",
    occ.comment AS "obsDescr",
    rel.unique_id_sinp_grp AS "permIdGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_nomenclature_label(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
    COALESCE(string_agg(DISTINCT o.nom_organisme::text, ','::text), 'NSP'::text) AS "obsNomOrg",
    COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
    ref_nomenclatures.get_nomenclature_label(rel.id_nomenclature_geo_object_nature) AS "natObjGeo",
    st_astext(rel.geom_4326) AS "WKT",
    -- 'In'::text AS "natObjGeo",
    tax.lb_nom AS "nomScienti",
    tax.nom_vern AS "nomVern",
    hab.lb_code AS "codeHab",
    hab.lb_hab_fr AS "nomHab",
    hab.cd_hab,
    rel.date_min,
    rel.date_max,
    rel.id_dataset,
    rel.id_releve_occtax,
    occ.id_occurrence_occtax,
    rel.id_digitiser,
    rel.geom_4326,
    rel.place_name AS "nomLieu",
    rel.precision
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
     LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = rel.cd_hab
   GROUP BY ccc.id_counting_occtax,occ.id_occurrence_occtax,rel.id_releve_occtax,d.id_dataset 
   ,tax.cd_ref , tax.lb_nom, tax.nom_vern , hab.cd_hab, hab.lb_code, hab.lb_hab_fr 
   ;



