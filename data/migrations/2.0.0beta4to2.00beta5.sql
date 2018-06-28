CREATE TABLE gn_commons.t_parameters (
    id_parameter integer NOT NULL,
    id_organism integer,
    parameter_name character varying(100) NOT NULL,
    parameter_desc text,
    parameter_value text NOT NULL,
    parameter_extra_value character varying(255)
);
COMMENT ON TABLE gn_commons.t_parameters IS 'Allow to manage content configuration depending on organism or not (CRUD depending on privileges).';

ALTER TABLE ONLY gn_commons.t_parameters
    ADD CONSTRAINT pk_t_parameters PRIMARY KEY (id_parameter);


CREATE OR REPLACE FUNCTION gn_commons.get_default_parameter(myparamname text, myidorganisme integer DEFAULT 0)
  RETURNS text AS
$BODY$
    DECLARE
        theparamvalue text;
-- Function that allows to get value of a parameter depending on his name and organism
-- USAGE : SELECT gn_commons.get_default_parameter('taxref_version');
-- OR      SELECT gn_commons.get_default_parameter('uuid_url_value', 2);
  BEGIN
    IF myidorganisme IS NOT NULL THEN
      SELECT INTO theparamvalue parameter_value FROM gn_commons.t_parameters WHERE parameter_name = myparamname AND id_organism = myidorganisme LIMIT 1;
    ELSE
      SELECT INTO theparamvalue parameter_value FROM gn_commons.t_parameters WHERE parameter_name = myparamname LIMIT 1;
    END IF;
    RETURN theparamvalue;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


INSERT INTO gn_commons.t_parameters (id_parameter, id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value)
SELECT * FROM gn_meta.t_parameters;


CREATE OR REPLACE FUNCTION ref_geo.fct_get_area_intersection(
  IN mygeom public.geometry,
  IN myidtype integer DEFAULT NULL::integer)
RETURNS TABLE(id_area integer, id_type integer, area_code character varying, area_name character varying) AS
$BODY$
DECLARE
  isrid int;
BEGIN
  SELECT gn_commons.get_default_parameter('local_srid', NULL) INTO isrid;
  RETURN QUERY
  WITH d  as (
      SELECT st_transform(myGeom,isrid) geom_trans
  )
  SELECT a.id_area, a.id_type, a.area_code, a.area_name
  FROM ref_geo.l_areas a, d
  WHERE st_intersects(geom_trans, a.geom)
    AND (myIdType IS NULL OR a.id_type = myIdType)
    AND enable=true;

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100
ROWS 1000;


CREATE OR REPLACE FUNCTION ref_geo.fct_get_altitude_intersection(IN mygeom public.geometry)
  RETURNS TABLE(altitude_min integer, altitude_max integer) AS
$BODY$
DECLARE
    isrid int;
BEGIN
    SELECT gn_commons.get_default_parameter('local_srid', NULL) INTO isrid;
    RETURN QUERY
    WITH d  as (
        SELECT st_transform(myGeom,isrid) a
     )
    SELECT min(val)::int as altitude_min, max(val)::int as altitude_max
    FROM ref_geo.dem_vector, d
    WHERE st_intersects(a,geom);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;


ALTER TABLE gn_synthese.synthese
ALTER COLUMN meta_v_taxref SET DEFAULT 'SELECT gn_commons.get_default_parameter(''taxref_version'',NULL)'::character varying;


CREATE OR REPLACE VIEW pr_occtax.export_occtax_sinp AS
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
    gn_commons.get_default_parameter('taxref_version'::text, NULL::integer) AS "versionTAXREF",
    rel.date_min AS datedet,
    occ.comment,
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
    rel.unique_id_sinp_grp AS "permIdGrp",
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
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
  GROUP BY ccc.unique_id_sinp_occtax, d.unique_dataset_id, occ.id_nomenclature_bio_condition, occ.id_nomenclature_naturalness, ccc.id_nomenclature_sex, ccc.id_nomenclature_life_stage, occ.id_nomenclature_bio_status, occ.id_nomenclature_exist_proof, occ.id_nomenclature_determination_method, rel.unique_id_sinp_grp, d.id_nomenclature_source_status, occ.id_nomenclature_blurring, occ.id_nomenclature_diffusion_level, 'Pr'::text, occ.nom_cite, rel.date_min, rel.date_max, rel.hour_min, rel.hour_max, rel.altitude_max, rel.altitude_min, occ.cd_nom, occ.id_nomenclature_observation_status, (taxonomie.find_cdref(occ.cd_nom)), (gn_commons.get_default_parameter('taxref_version'::text, NULL::integer)), rel.comment, 'Ac'::text, rel.id_dataset, NULL::text, ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status), ccc.id_counting_occtax, d.dataset_name, occ.determiner, occ.comment, (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth)), (ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition)), (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text::character varying)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage)), '0'::text, (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status), '0'::text::character varying)), (COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof), '0'::text::character varying)), ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method, 'fr'::character varying), occ.digital_proof, occ.non_digital_proof, 'Relevé'::text, 'OBS'::text, ccc.count_max, ccc.count_min, (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count)), (ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count)), rel.observers_txt, 'NSP'::text, o.nom_organisme, 'NSP'::text, 'NSP'::text, (st_astext(rel.geom_4326)), 'In'::text;



DROP TABLE gn_meta.t_parameters;

DROP FUNCTION gn_meta.get_default_parameter(text, integer);



-- Modification de la table gn_commons.t_modules

ALTER TABLE gn_commons.t_modules
RENAME COLUMN active TO active_frontend;

ALTER TABLE gn_commons.t_modules
ADD COLUMN active_backend BOOLEAN;


-- Modification de gn_meta.sinp_datatype_protocols
ALTER TABLE gn_meta.sinp_datatype_protocols ALTER COLUMN protocol_desc TYPE text;


--suppression du lien entre les nomenclatures ref_geo
ALTER TABLE ONLY ref_geo.l_areas DROP COLUMN id_nomenclature_area_type;
ALTER TABLE ONLY ref_geo.bib_areas_types DROP CONSTRAINT fk_bib_areas_types_id_nomenclature_area_type;
ALTER TABLE ref_geo.bib_areas_types DROP CONSTRAINT check_bib_areas_types_area_type;

--Correction de type de la table synthese
ALTER TABLE gn_synthese.synthese ALTER COLUMN id_municipality TYPE character varying(25);


--- Modification des contraintes pour qu'elles soient dans la section postdata
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature DROP CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn;
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn CHECK ((taxonomie.check_is_group2inpn((group2_inpn)::text) OR ((group2_inpn)::text = 'all'::text))) NOT VALID;
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature DROP CONSTRAINT check_cor_taxref_nomenclature_isregne;
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature ADD CONSTRAINT check_cor_taxref_nomenclature_isregne CHECK ((taxonomie.check_is_regne((regne)::text) OR ((regne)::text = 'all'::text))) NOT VALID;
ALTER TABLE ref_nomenclatures.cor_taxref_sensitivity DROP CONSTRAINT check_cor_taxref_sensitivity_niv_precis;
ALTER TABLE ref_nomenclatures.cor_taxref_sensitivity ADD CONSTRAINT check_cor_taxref_sensitivity_niv_precis CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_niv_precis, 5)) NOT VALID;
ALTER TABLE ref_nomenclatures.defaults_nomenclatures_value DROP CONSTRAINT check_defaults_nomenclatures_value_is_nomenclature_in_type;
ALTER TABLE ref_nomenclatures.defaults_nomenclatures_value ADD CONSTRAINT check_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature, id_type)) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_resource_type;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_resource_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_resource_type, 102)) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_data_type;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_data_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_data_type, 103)) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_objectif;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_objectif CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_dataset_objectif, 114)) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_collecting_method;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_collecting_method CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_collecting_method, 115)) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_data_origin;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_data_origin CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_data_origin, 2)) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_source_status;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_source_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_source_status, 19)) NOT VALID;
ALTER TABLE gn_meta.t_acquisition_frameworks DROP CONSTRAINT check_t_acquisition_frameworks_territorial_level;
ALTER TABLE gn_meta.t_acquisition_frameworks ADD CONSTRAINT check_t_acquisition_frameworks_territorial_level CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_territorial_level, 107)) NOT VALID;
ALTER TABLE gn_meta.t_acquisition_frameworks DROP CONSTRAINT check_t_acquisition_financing_type;
ALTER TABLE gn_meta.t_acquisition_frameworks ADD CONSTRAINT check_t_acquisition_financing_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_financing_type, 111)) NOT VALID;
ALTER TABLE gn_meta.cor_acquisition_framework_voletsinp DROP CONSTRAINT check_cor_acquisition_framework_voletsinp;
ALTER TABLE gn_meta.cor_acquisition_framework_voletsinp ADD CONSTRAINT check_cor_acquisition_framework_voletsinp CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_voletsinp, 113)) NOT VALID;
ALTER TABLE gn_meta.cor_acquisition_framework_objectif DROP CONSTRAINT check_cor_acquisition_framework_objectif;
ALTER TABLE gn_meta.cor_acquisition_framework_objectif ADD CONSTRAINT check_cor_acquisition_framework_objectif CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_objectif, 108)) NOT VALID;
ALTER TABLE gn_meta.cor_acquisition_framework_actor DROP CONSTRAINT check_cor_acquisition_framework_actor;
ALTER TABLE gn_meta.cor_acquisition_framework_actor ADD CONSTRAINT check_cor_acquisition_framework_actor CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_actor_role, 109)) NOT VALID;
ALTER TABLE gn_meta.sinp_datatype_protocols DROP CONSTRAINT check_sinp_datatype_protocol_type;
ALTER TABLE gn_meta.sinp_datatype_protocols ADD CONSTRAINT check_sinp_datatype_protocol_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_protocol_type, 112)) NOT VALID;
ALTER TABLE gn_meta.cor_dataset_actor DROP CONSTRAINT check_cor_dataset_actor;
ALTER TABLE gn_meta.cor_dataset_actor ADD CONSTRAINT check_cor_dataset_actor CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_actor_role, 109)) NOT VALID;
ALTER TABLE gn_meta.cor_dataset_territory DROP CONSTRAINT check_cor_dataset_territory;
ALTER TABLE gn_meta.cor_dataset_territory ADD CONSTRAINT check_cor_dataset_territory CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_territory, 110)) NOT VALID;
ALTER TABLE gn_commons.t_medias DROP CONSTRAINT check_t_medias_media_type;
ALTER TABLE gn_commons.t_medias ADD CONSTRAINT check_t_medias_media_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_media_type, 117)) NOT VALID;
ALTER TABLE gn_commons.t_validations DROP CONSTRAINT check_t_validations_valid_status;
ALTER TABLE gn_commons.t_validations ADD CONSTRAINT check_t_validations_valid_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_valid_status, 101)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_obs_meth;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_meth, 14)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_geo_object_nature;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_geo_object_nature, 3)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_typ_grp;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_typ_grp CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_grp_typ, 24)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_obs_technique;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obs_technique, 100)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_bio_status;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_bio_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_status, 13)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_bio_condition;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_bio_condition, 7)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_naturalness;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_naturalness CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_naturalness, 8)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_exist_proof;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_exist_proof, 15)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_valid_status;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_valid_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_valid_status, 101)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_diffusion_level;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_diffusion_level CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_diffusion_level, 5)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_life_stage;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_life_stage CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_life_stage, 10)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_sex;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_sex CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sex, 9)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_obj_count;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_obj_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_obj_count, 6)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_type_count;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_type_count CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_type_count, 21)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_sensitivity;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_sensitivity, 16)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_observation_status;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_observation_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_observation_status, 18)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_blurring;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_blurring CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_blurring, 4)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_source_status;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_source_status CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_source_status, 19)) NOT VALID;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_info_geo_type;
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT check_synthese_info_geo_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_info_geo_type, 23)) NOT VALID;
ALTER TABLE gn_synthese.defaults_nomenclatures_value DROP CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_is_nomenclature_;
ALTER TABLE gn_synthese.defaults_nomenclatures_value ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_is_nomenclature_ CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature, id_type)) NOT VALID;
ALTER TABLE gn_synthese.defaults_nomenclatures_value DROP CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isgroup2inpn;
ALTER TABLE gn_synthese.defaults_nomenclatures_value ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isgroup2inpn CHECK ((taxonomie.check_is_group2inpn((group2_inpn)::text) OR ((group2_inpn)::text = '0'::text))) NOT VALID;
ALTER TABLE gn_synthese.defaults_nomenclatures_value DROP CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isregne;
ALTER TABLE gn_synthese.defaults_nomenclatures_value ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isregne CHECK ((taxonomie.check_is_regne((regne)::text) OR ((regne)::text = '0'::text))) NOT VALID;
ALTER TABLE gn_monitoring.t_base_sites DROP CONSTRAINT check_t_base_sites_type_site;
ALTER TABLE gn_monitoring.t_base_sites ADD CONSTRAINT check_t_base_sites_type_site CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_type_site, 116)) NOT VALID;
