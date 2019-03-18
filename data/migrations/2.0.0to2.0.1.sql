-- Recréation de la vue qui avait été supprimé lors de la monté de version RC3 to RC4

DROP VIEW pr_occtax.export_occtax_sinp;
CREATE OR REPLACE VIEW pr_occtax.export_occtax_sinp AS 
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
    gn_commons.get_default_parameter('taxref_version'::text, NULL::integer) AS "vTAXREF",
    'NSP'::text AS "dSPublique",
    d.unique_dataset_id AS "jddMetaId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status) AS "statSource",
    '0'::text AS "difNivPrec",
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
    occ.comment AS "obsDescr",
    rel.unique_id_sinp_grp AS "permIdGrp",
    'Relevé'::text AS "methGrp",
    'OBS'::text AS "typGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
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
  GROUP BY ccc.unique_id_sinp_occtax, d.unique_dataset_id, occ.id_occurrence_occtax, occ.id_nomenclature_bio_condition, occ.id_nomenclature_naturalness, ccc.id_nomenclature_sex, ccc.id_nomenclature_life_stage, occ.id_nomenclature_bio_status, occ.id_nomenclature_exist_proof, occ.id_nomenclature_determination_method, rel.unique_id_sinp_grp, d.id_nomenclature_source_status, occ.id_nomenclature_blurring, occ.id_nomenclature_diffusion_level, occ.nom_cite, rel.id_releve_occtax, rel.date_min, rel.date_max, rel.hour_min, rel.hour_max, rel.altitude_max, rel.altitude_min, rel.id_digitiser, occ.cd_nom, occ.id_nomenclature_observation_status, (taxonomie.find_cdref(occ.cd_nom)), (gn_commons.get_default_parameter('taxref_version'::text, NULL::integer)), rel.comment, rel.id_dataset, (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status)), ccc.id_counting_occtax, d.dataset_name, occ.determiner, occ.comment, (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth)), (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition)), (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage)), (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status)), (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof)), (ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method)), occ.digital_proof, occ.non_digital_proof, ccc.count_max, ccc.count_min, (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count)), rel.observers_txt, rel.geom_4326;


UPDATE gn_commons.t_modules 
SET module_picto = 'fa-map-marker' WHERE module_code = 'OCCTAX';



DROP TABLE gn_synthese.taxons_synthese_autocomplete;

CREATE TABLE gn_synthese.taxons_synthese_autocomplete AS
SELECT t.cd_nom,
  t.cd_ref,
  t.search_name,
  t.nom_valide,
  t.lb_nom,
  t.regne,
  t.group2_inpn
FROM (
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.lb_nom, ' =  <i> ', t_1.nom_valide, '</i>', ' - [', t_1.id_rang, ' - ', t_1.cd_nom , ']' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1

  UNION
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.nom_vern, ' =  <i> ', t_1.nom_valide, '</i>', ' - [', t_1.id_rang, ' - ', t_1.cd_nom , ']' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1
  WHERE t_1.nom_vern IS NOT NULL AND t_1.cd_nom = t_1.cd_ref
) t
  WHERE t.cd_nom IN (SELECT DISTINCT cd_nom FROM gn_synthese.synthese);

  COMMENT ON TABLE gn_synthese.taxons_synthese_autocomplete
     IS 'Table construite à partir d''une requete sur la base et mise à jour via le trigger trg_refresh_taxons_forautocomplete de la table gn_synthese';


-- correction sequence pas alloué à la bonne colonne
ALTER SEQUENCE pr_occtax.cor_counting_occtax_id_counting_occtax_seq OWNED BY pr_occtax.cor_counting_occtax.id_counting_occtax;


-- correction de la fonction trigger de calcul de la geom local

CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_geom_local()
  RETURNS trigger AS
-- trigger qui reprojete une geom a partir d'une geom source fournie
-- en prenant le parametre local_srid de la table t_parameters
-- 1er param: nom de la colonne source
-- 2eme param: nom de la colonne a reprojeter
-- utiliser pour calculer les geom_local à partir des geom_4326
$BODY$
DECLARE
	the4326geomcol text := quote_ident(TG_ARGV[0]);
	thelocalgeomcol text := quote_ident(TG_ARGV[1]);
        thelocalsrid int;
        thegeomlocalvalue public.geometry;
        thegeomchange boolean;
BEGIN
	-- si c'est un insert ou que c'est un UPDATE ET que le geom_4326 a été modifié
	IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NOT ST_EQUALS(hstore(OLD)-> the4326geomcol, hstore(NEW)-> the4326geomcol)  )) THEN
		--récupérer le srid local
		SELECT INTO thelocalsrid parameter_value::int FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid';
		EXECUTE FORMAT ('SELECT ST_TRANSFORM($1.%I, $2)',the4326geomcol) INTO thegeomlocalvalue USING NEW, thelocalsrid;
                -- insertion dans le NEW de la geom transformée
		NEW := NEW#= hstore(thelocalgeomcol, thegeomlocalvalue);
	END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- correction vue occtax (pas de distinct nom_valide)
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
    (((string_agg(t.nom_valide::text, ','::text) || '<br/>'::text) || rel.date_min::date) || '<br/>'::text) || COALESCE(string_agg(DISTINCT(obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS leaflet_popup,
    COALESCE(string_agg(DISTINCT(obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS observateurs
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
     LEFT JOIN pr_occtax.cor_role_releves_occtax cor_role ON cor_role.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
     LEFT JOIN gn_meta.t_datasets dataset ON dataset.id_dataset = rel.id_dataset
  GROUP BY dataset.dataset_name, rel.id_releve_occtax, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.meta_device_entry;


UPDATE gn_synthese.defaults_nomenclatures_value d 
SET id_nomenclature = (
  SELECT id_nomenclature
  FROM ref_nomenclatures.t_nomenclatures nom
  JOIN ref_nomenclatures.bib_nomenclatures_types bib ON bib.id_type = nom.id_type
  WHERE bib.mnemonique = 'STATUT_OBS' AND nom.cd_nomenclature = 'Pr'
)
WHERE mnemonique_type = 'STATUT_OBS';