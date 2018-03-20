SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE OR REPLACE VIEW pr_contact.export_occtax_sinp AS 
 SELECT ccc.unique_id_sinp_occtax AS "permId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_observation_status) AS "statObs",
    occ.nom_cite AS "nomCite",
    rel.date_min AS "dateDebut",
    rel.date_max AS "dateFin",
    rel.hour_min AS "heureDebut",
    rel.hour_max AS "heureFin",
    rel.altitude_max AS "altMax",
    rel.altitude_min AS "altMin",
    occ.cd_nom AS "cdNom",
    taxonomie.find_cdref(occ.cd_nom) AS "cdRef",
    gn_meta.get_default_parameter('taxref_version'::text, NULL::integer) AS "versionTAXREF",
    rel.date_min AS datedet,
    occ.comment,
    'NSP'::text AS "dSPublique",
    d.unique_dataset_id AS "jddMetadonneeDEEId",
    'Te'::text AS "statSource",
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
    COALESCE(ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method, 'fr'::character varying), occ.determination_method_as_text::character varying) AS "ocMethDet",
    occ.digital_proof AS "preuvNum",
    occ.non_digital_proof AS "preuvNoNum",
    rel.comment AS "obsCtx",
    rel.id_releve_contact AS "permIdGrp",
    'Relevé'::text AS "methGrp",
    'OBS'::text AS "typGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg((r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
    COALESCE(string_agg(r.organisme::text, ','::text), o.nom_organisme::text, 'NSP'::text) AS "obsNomOrg",
    COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
    'NSP'::text AS "detNomOrg",
    'NSP'::text AS "orgGestDat",
    st_astext(rel.geom_4326) AS "WKT",
    'In'::text AS "natObjGeo"
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN pr_contact.cor_counting_contact ccc ON ccc.id_occurrence_contact = occ.id_occurrence_contact
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_contact.cor_role_releves_contact cr ON cr.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
  GROUP BY ccc.unique_id_sinp_occtax, d.unique_dataset_id, occ.id_nomenclature_bio_condition, occ.id_nomenclature_naturalness, ccc.id_nomenclature_sex, ccc.id_nomenclature_life_stage, occ.id_nomenclature_bio_status, occ.id_nomenclature_exist_proof, occ.id_nomenclature_determination_method, rel.id_releve_contact, d.id_nomenclature_source_status, occ.id_nomenclature_blurring, occ.id_nomenclature_diffusion_level, 'Pr'::text, occ.nom_cite, rel.date_min, rel.date_max, rel.hour_min, rel.hour_max, rel.altitude_max, rel.altitude_min, occ.cd_nom, occ.id_nomenclature_observation_status, (taxonomie.find_cdref(occ.cd_nom)), (gn_meta.get_default_parameter('taxref_version'::text, NULL::integer)), rel.comment, ccc.meta_update_date, 'Ac'::text, rel.id_dataset, NULL::text, 'Te'::text, ccc.id_counting_contact, d.dataset_name, occ.determiner, occ.comment, (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth)), (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition)), (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text::character varying)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage)), '0'::text, (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status), '0'::text::character varying)), (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof), '0'::text::character varying)), (COALESCE(ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method, 'fr'::character varying), occ.determination_method_as_text::character varying)), occ.digital_proof, occ.non_digital_proof, 'Relevé'::text, 'OBS'::text, ccc.count_max, ccc.count_min, (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count)), rel.observers_txt, 'NSP'::text, o.nom_organisme, 'NSP'::text, 'NSP'::text, (st_astext(rel.geom_4326)), 'In'::text;

CREATE OR REPLACE VIEW pr_contact.export_occtax_dlb AS 
 SELECT ccc.unique_id_sinp_occtax AS "permId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_observation_status) AS "statObs",
    occ.nom_cite AS "nomCite",
    to_char(rel.date_min, 'DD/MM/YYYY'::text) AS "dateDebut",
    to_char(rel.date_max, 'DD/MM/YYYY'::text) AS "dateFin",
    rel.hour_min AS "heureDebut",
    rel.hour_max AS "heureFin",
    rel.altitude_max AS "altMax",
    rel.altitude_min AS "altMin",
    occ.cd_nom AS "cdNom",
    taxonomie.find_cdref(occ.cd_nom) AS "cdRef",
    to_char(rel.date_min, 'DD/MM/YYYY'::text) AS "dateDet",
    occ.comment,
    'NSP'::text AS "dSPublique",
    'Te'::text AS "statSource",
    ccc.unique_id_sinp_occtax AS "idOrigine",
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
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_determination_method), occ.determination_method_as_text::character varying) AS "ocMethDet",
    occ.digital_proof AS "preuvNum",
    occ.non_digital_proof AS "preuvNoNum",
    rel.comment AS "obsCtx",
    rel.id_releve_contact AS "permIdGrp",
    'Relevé'::text AS "methGrp",
    'OBS'::text AS "typGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg((r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
    COALESCE(string_agg(r.organisme::text, ','::text), o.nom_organisme::text, 'NSP'::text) AS "obsNomOrg",
    COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
    'NSP'::text AS "detNomOrg",
    'NSP'::text AS "orgGestDat",
    st_astext(rel.geom_4326) AS "WKT",
    'In'::text AS "natObjGeo"
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN pr_contact.cor_counting_contact ccc ON ccc.id_occurrence_contact = occ.id_occurrence_contact
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_contact.cor_role_releves_contact cr ON cr.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
  GROUP BY ccc.unique_id_sinp_occtax, d.unique_dataset_id, occ.id_nomenclature_bio_condition, occ.id_nomenclature_naturalness, ccc.id_nomenclature_sex, ccc.id_nomenclature_life_stage, occ.id_nomenclature_bio_status, occ.id_nomenclature_exist_proof, occ.id_nomenclature_determination_method, rel.id_releve_contact, d.id_nomenclature_source_status, occ.id_nomenclature_blurring, occ.id_nomenclature_diffusion_level, 'Pr'::text, occ.nom_cite, rel.date_min, rel.date_max, rel.hour_min, rel.hour_max, rel.altitude_max, rel.altitude_min, occ.cd_nom, occ.id_nomenclature_observation_status, (taxonomie.find_cdref(occ.cd_nom)), rel.comment, ccc.meta_update_date, 'Ac'::text, rel.id_dataset, NULL::text, 'Te'::text, ccc.id_counting_contact, d.dataset_name, occ.determiner, occ.comment, (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth)), (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition)), (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text::character varying)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage)), '0'::text, (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status), '0'::text::character varying)), (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof), '0'::text::character varying)), (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_determination_method), occ.determination_method_as_text::character varying)), occ.digital_proof, occ.non_digital_proof, 'Relevé'::text, 'OBS'::text, ccc.count_max, ccc.count_min, (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count)), rel.observers_txt, 'NSP'::text, o.nom_organisme, (st_astext(rel.geom_4326)), 'In'::text;
