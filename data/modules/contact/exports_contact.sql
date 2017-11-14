SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE OR REPLACE VIEW pr_contact.export_occtax_sinp AS 
SELECT ccc.unique_id_sinp AS "identifiantPermanent",
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
    d.unique_dataset_id AS "jddMetadonneeDEEId",
    NULL::text AS "sensible",
    NULL::text AS "sensiNiveau",
    'Te'::text AS "statutSource",
    'NSP'::text AS "codeIDCNPDispositif",
    'NSP'::text AS "dEEFloutage",
    'NSP'::text AS "diffusionNiveauPrecision",
    ccc.unique_id_sinp AS "identifiantOrigine",
    d.dataset_name AS "jddCode",
    d.unique_dataset_id AS "jddId",
    NULL::text AS "referenceBiblio",
    NULL::text AS "sensiDateAttribution",
    NULL::text AS "sensiReferentiel",
    NULL::text AS "sensiversionreferentiel",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth) AS "obsMethode",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition) AS "occEtatBiologique",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text) AS "occNaturalite",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex) AS "occSexe",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage) AS "occStadeDeVie",
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
    ccc.count_max AS "denombrementMax",
    ccc.count_min AS "denombrementMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objetDenombrement",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typeDenombrement",
    COALESCE(string_agg((r.nom_r::text || ' '::text) || r.prenom_r::text, ','::text), rel.observers_txt::text) AS "observateurIdentite",
    COALESCE(string_agg(r.organisme::text, ','::text), o.nom_organisme::text, 'NSP'::text) AS "observateurNomOrganisme",
    COALESCE(occ.determiner, COALESCE(string_agg((r.nom_r::text || ' '::text) || r.prenom_r::text, ','::text), rel.observers_txt::text)::character varying) AS "determinateurIdentite",
    'NSP'::text AS "determinateurNomOrganisme",
    'NSP'::text AS "validateurIdentite",
    'NSP'::text AS "validateurNomOrganisme",
    'NSP'::text AS "organismeGestionnaireDonnee",
    public.st_astext(rel.geom_4326) AS geometrie,
    'In'::text AS "natureObjetGeo"
   FROM pr_contact.t_releves_contact rel
     LEFT JOIN pr_contact.t_occurrences_contact occ ON rel.id_releve_contact = occ.id_releve_contact
     LEFT JOIN pr_contact.ccc_contact ccc ON ccc.id_occurrence_contact = occ.id_occurrence_contact
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_contact.cor_role_releves_contact cr ON cr.id_releve_contact = rel.id_releve_contact
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
  GROUP BY ccc.unique_id_sinp, d.unique_dataset_id,occ.id_nomenclature_bio_condition, occ.id_nomenclature_naturalness, ccc.id_nomenclature_sex,ccc.id_nomenclature_life_stage,
  occ.id_nomenclature_bio_status,occ.id_nomenclature_exist_proof, occ.id_nomenclature_determination_method,
   ccc.id_nomenclature_sex, rel.id_releve_contact, d.id_nomenclature_source_status, occ.id_nomenclature_blurring, occ.id_nomenclature_diffusion_level, 'Pr'::text, occ.nom_cite, rel.date_min, rel.date_max, rel.hour_min, rel.hour_max, rel.altitude_max, rel.altitude_min, occ.cd_nom, occ.id_nomenclature_observation_status, (taxonomie.find_cdref(occ.cd_nom)), (gn_meta.get_default_parameter('taxref_version'::text, NULL::integer)),
    rel.comment, ccc.meta_update_date, 'Ac'::text, 
    rel.id_dataset, NULL::text, 'Te'::text, ccc.id_counting_contact, 
     d.dataset_name, occ.determiner,
     commentaire, "obsMethode","occEtatBiologique",
     "occNaturalite", "occSexe", "occStadeDeVie", "occStatutBioGeographique", "occStatutBiologique", "preuveExistante", "occMethodeDetermination",
     "preuveNumerique","preuveNonNumerique", "obsContexte", "identifiantRegroupementPermanent", "methodeRegroupement", "typeRegroupement", "denombrementMax",
     "denombrementMin", "objetDenombrement", "typeDenombrement", rel.observers_txt, 'NSP'::text, o.nom_organisme, "determinateurNomOrganisme",
     "validateurIdentite", "validateurNomOrganisme", "organismeGestionnaireDonnee", "geometrie", "natureObjetGeo"