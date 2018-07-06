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



-- Modification de la table gn_commons.t_modules

ALTER TABLE gn_commons.t_modules
RENAME COLUMN active TO active_frontend;

ALTER TABLE gn_commons.t_modules
ADD COLUMN active_backend BOOLEAN;

UPDATE gn_commons.t_modules
SET active_backend = true WHERE module_name = 'occtax';


-- Modification de gn_meta.sinp_datatype_protocols
ALTER TABLE gn_meta.sinp_datatype_protocols ALTER COLUMN protocol_desc TYPE text;


--suppression du lien entre les nomenclatures ref_geo
ALTER TABLE ONLY ref_geo.bib_areas_types DROP CONSTRAINT fk_bib_areas_types_id_nomenclature_area_type;
ALTER TABLE ref_geo.bib_areas_types DROP CONSTRAINT check_bib_areas_types_area_type;
ALTER TABLE ONLY ref_geo.bib_areas_types DROP COLUMN id_nomenclature_area_type;



-- Modification monitoring : rajout trigger de calcul des intersections avec ref_geo

CREATE FUNCTION gn_monitoring.fct_trg_cor_site_area()
  RETURNS trigger AS
$BODY$
BEGIN

	DELETE FROM gn_monitoring.cor_site_area WHERE id_base_site = NEW.id_base_site;
	INSERT INTO gn_monitoring.cor_site_area
	SELECT NEW.id_base_site, (ref_geo.fct_get_area_intersection(NEW.geom)).id_area;

  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;


CREATE TRIGGER trg_cor_site_area
  AFTER INSERT OR UPDATE OF geom ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE gn_monitoring.fct_trg_cor_site_area();


-- Modification lié au changement sur les nomenclatures

-- schéma ref_nomenclatures

-- functions


CREATE OR REPLACE FUNCTION ref_nomenclatures.get_id_nomenclature(
    mytype character varying,
    mycdnomenclature character varying)
  RETURNS integer AS
$BODY$
--Function which return the id_nomenclature from an mnemonique_type and an cd_nomenclature
DECLARE theidnomenclature integer;
  BEGIN
SELECT INTO theidnomenclature id_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type(mytype) AND mycdnomenclature = n.cd_nomenclature;
return theidnomenclature;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0) RETURNS integer
IMMUTABLE
LANGUAGE plpgsql AS
$$
--Function that return the default nomenclature id with wanteds nomenclature type (mnemonique), organism id
--Return -1 if nothing matche with given parameters
  DECLARE
    thenomenclatureid integer;
  BEGIN
      SELECT INTO thenomenclatureid id_nomenclature
      FROM ref_nomenclatures.defaults_nomenclatures_value
      WHERE mnemonique_type = mytype
      AND (id_organism = myidorganism OR id_organism = 0)
      ORDER BY id_organism DESC LIMIT 1;
    IF (thenomenclatureid IS NOT NULL) THEN
      RETURN thenomenclatureid;
    END IF;
    RETURN -1;
  END;
$$;

CREATE OR REPLACE FUNCTION ref_nomenclatures.check_nomenclature_type_by_mnemonique(id integer , mytype character varying) RETURNS boolean
IMMUTABLE
LANGUAGE plpgsql AS
$$
--Function that checks if an id_nomenclature matches with wanted nomenclature type (use mnemonique type)
  BEGIN
    IF (id IN (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(mytype))
        OR id IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : id_nomenclature and nomenclature type didn''t match. Use id_nomenclature in corresponding type (mnemonique field). See ref_nomenclatures.t_nomenclatures.id_type.';
    END IF;
    RETURN false;
  END;
$$;

CREATE OR REPLACE FUNCTION ref_nomenclature.check_nomenclature_type_by_cd_nomenclature(mycdnomenclature character varying , mytype character varying) RETURNS boolean
IMMUTABLE
LANGUAGE plpgsql AS
$$
--Function that checks if an id_nomenclature matches with wanted nomenclature type (use mnemonique type)
  BEGIN
    IF (mycdnomenclature IN (SELECT cd_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(mytype))
        OR mycdnomenclature IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : cd_nomenclature --> % and nomenclature type --> % didn''t match.', mycdnomenclature, mytype
	    USING HINT = 'Use cd_nomenclature in corresponding type (mnemonique field). See ref_nomenclatures.t_nomenclatures.id_type and ref_nomenclatures.bib_nomenclatures_types.mnemonique';
    END IF;
    RETURN false;
  END;
$$;

CREATE OR REPLACE FUNCTION ref_nomenclatures.check_nomenclature_type_by_id(id integer, myidtype integer) RETURNS boolean
  IMMUTABLE
LANGUAGE plpgsql AS
$$
--Function that checks if an id_nomenclature matches with wanted nomenclature type (use id_type)
  BEGIN
    IF (id IN (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = myidtype )
        OR id IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : id_nomenclature and id_type didn''t match. Use nomenclature with corresponding type (id_type). See ref_nomenclatures.t_nomenclatures.id_type and ref_nomenclatures.bib_nomenclatures_types.id_type.';
    END IF;
    RETURN false;
  END;
$$;

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




ALTER TABLE ref_nomenclatures.bib_nomenclatures_types
  ADD CONSTRAINT unique_bib_nomenclatures_types_mnemonique UNIQUE (mnemonique);

-- Modification de defauts dans gn_meta

ALTER TABLE ONLY gn_meta.t_acquisition_frameworks
  ALTER COLUMN id_nomenclature_territorial_level SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('NIVEAU_TERRITORIAL');

ALTER TABLE ONLY gn_meta.t_acquisition_frameworks
  ALTER COLUMN id_nomenclature_financing_type SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('TYPE_FINANCEMENT');

ALTER TABLE ONLY gn_meta.t_datasets
  ALTER COLUMN id_nomenclature_data_type SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('DATA_TYP');

ALTER TABLE ONLY gn_meta.t_datasets
  ALTER COLUMN id_nomenclature_dataset_objectif SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('SAMPLING_PLAN_TYP');

ALTER TABLE ONLY gn_meta.t_datasets
  ALTER COLUMN id_nomenclature_collecting_method SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('METHO_RECUEIL');

ALTER TABLE ONLY gn_meta.t_datasets
  ALTER COLUMN id_nomenclature_data_origin SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('DS_PUBLIQUE');

ALTER TABLE ONLY gn_meta.t_datasets
  ALTER COLUMN id_nomenclature_source_status SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('STATUT_SOURCE');

ALTER TABLE ONLY gn_meta.t_datasets
  ALTER COLUMN id_nomenclature_resource_type SET DEFAULT ref_nomenclatures.get_default_nomenclature_value('RESOURCE_TYP');


-- ref_nomenclature.defaults_nomenclatures_value

-- TABLE

DROP TABLE ref_nomenclatures.defaults_nomenclatures_value;

CREATE TABLE ref_nomenclatures.defaults_nomenclatures_value
(
  mnemonique_type character varying(50) NOT NULL,
  id_organism integer NOT NULL DEFAULT 0,
  id_nomenclature integer NOT NULL,
  CONSTRAINT pk_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism),
  CONSTRAINT fk_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature)
      REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism)
      REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type)
      REFERENCES ref_nomenclatures.bib_nomenclatures_types (mnemonique) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT check_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type))
)
WITH (
  OIDS=FALSE
);

--Datas

INSERT INTO ref_nomenclatures.defaults_nomenclatures_value (mnemonique_type, id_organism, id_nomenclature) VALUES
('DS_PUBLIQUE',0,ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'))
,('STATUT_SOURCE',0,ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'))
,('STATUT_VALID',0,ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '0'))
,('RESOURCE_TYP',0,ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'))
,('DATA_TYP',0,ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'))
,('JDD_OBJECTIFS',0,ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '1.1'))
,('METHO_RECUEIL',0,ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'))
,('NIVEAU_TERRITORIAL',0,ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '3'))
,('TYPE_FINANCEMENT',0,ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'))
,('METH_DETERMIN',0,ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '1'))
;



--- Modification des contraintes pour qu'elles soient dans la section postdata
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature DROP CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn;
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn CHECK ((taxonomie.check_is_group2inpn((group2_inpn)::text) OR ((group2_inpn)::text = 'all'::text))) NOT VALID;
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature DROP CONSTRAINT check_cor_taxref_nomenclature_isregne;
ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature ADD CONSTRAINT check_cor_taxref_nomenclature_isregne CHECK ((taxonomie.check_is_regne((regne)::text) OR ((regne)::text = 'all'::text))) NOT VALID;
ALTER TABLE ref_nomenclatures.cor_taxref_sensitivity DROP CONSTRAINT check_cor_taxref_sensitivity_niv_precis;
ALTER TABLE ref_nomenclatures.cor_taxref_sensitivity ADD CONSTRAINT check_cor_taxref_sensitivity_niv_precis CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_niv_precis, 'NIV_PRECIS')) NOT VALID;
ALTER TABLE ref_nomenclatures.defaults_nomenclatures_value DROP CONSTRAINT check_defaults_nomenclatures_value_is_nomenclature_in_type;
ALTER TABLE ref_nomenclatures.defaults_nomenclatures_value ADD CONSTRAINT check_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type)) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_resource_type;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_resource_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_resource_type, 'RESOURCE_TYP')) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_data_type;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_data_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_type, 'DATA_TYP')) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_objectif;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_objectif CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_dataset_objectif, 'JDD_OBJECTIFS')) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_collecting_method;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_collecting_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_collecting_method, 'METHO_RECUEIL')) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_data_origin;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_data_origin CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_origin, 'DS_PUBLIQUE')) NOT VALID;
ALTER TABLE gn_meta.t_datasets DROP CONSTRAINT check_t_datasets_source_status;
ALTER TABLE gn_meta.t_datasets ADD CONSTRAINT check_t_datasets_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status, 'STATUT_SOURCE')) NOT VALID;
ALTER TABLE gn_meta.t_acquisition_frameworks DROP CONSTRAINT check_t_acquisition_frameworks_territorial_level;
ALTER TABLE gn_meta.t_acquisition_frameworks ADD CONSTRAINT check_t_acquisition_frameworks_territorial_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territorial_level, 'NIVEAU_TERRITORIAL')) NOT VALID;
ALTER TABLE gn_meta.t_acquisition_frameworks DROP CONSTRAINT check_t_acquisition_financing_type;
ALTER TABLE gn_meta.t_acquisition_frameworks ADD CONSTRAINT check_t_acquisition_financing_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_financing_type, 'TYPE_FINANCEMENT')) NOT VALID;
ALTER TABLE gn_meta.cor_acquisition_framework_voletsinp DROP CONSTRAINT check_cor_acquisition_framework_voletsinp;
ALTER TABLE gn_meta.cor_acquisition_framework_voletsinp ADD CONSTRAINT check_cor_acquisition_framework_voletsinp CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_voletsinp, 'VOLET_SINP')) NOT VALID;
ALTER TABLE gn_meta.cor_acquisition_framework_objectif DROP CONSTRAINT check_cor_acquisition_framework_objectif;
ALTER TABLE gn_meta.cor_acquisition_framework_objectif ADD CONSTRAINT check_cor_acquisition_framework_objectif CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_objectif, 'CA_OBJECTIFS')) NOT VALID;
ALTER TABLE gn_meta.cor_acquisition_framework_actor DROP CONSTRAINT check_cor_acquisition_framework_actor;
ALTER TABLE gn_meta.cor_acquisition_framework_actor ADD CONSTRAINT check_cor_acquisition_framework_actor CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_actor_role, 'ROLE_ACTEUR')) NOT VALID;
ALTER TABLE gn_meta.sinp_datatype_protocols DROP CONSTRAINT check_sinp_datatype_protocol_type;
ALTER TABLE gn_meta.sinp_datatype_protocols ADD CONSTRAINT check_sinp_datatype_protocol_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_protocol_type, 'TYPE_PROTOCOLE')) NOT VALID;
ALTER TABLE gn_meta.cor_dataset_actor DROP CONSTRAINT check_cor_dataset_actor;
ALTER TABLE gn_meta.cor_dataset_actor ADD CONSTRAINT check_cor_dataset_actor CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_actor_role, 'ROLE_ACTEUR')) NOT VALID;
ALTER TABLE gn_meta.cor_dataset_territory DROP CONSTRAINT check_cor_dataset_territory;
ALTER TABLE gn_meta.cor_dataset_territory ADD CONSTRAINT check_cor_dataset_territory CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory, 'TERRITOIRE')) NOT VALID;
ALTER TABLE gn_commons.t_medias DROP CONSTRAINT check_t_medias_media_type;
ALTER TABLE gn_commons.t_medias ADD CONSTRAINT check_t_medias_media_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_media_type, 'TYPE_MEDIA')) NOT VALID;
ALTER TABLE gn_commons.t_validations DROP CONSTRAINT check_t_validations_valid_status;
ALTER TABLE gn_commons.t_validations ADD CONSTRAINT check_t_validations_valid_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_valid_status, 'STATUT_VALID')) NOT VALID;

ALTER TABLE gn_monitoring.t_base_sites DROP CONSTRAINT check_t_base_sites_type_site;
ALTER TABLE gn_monitoring.t_base_sites ADD CONSTRAINT check_t_base_sites_type_site CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_site, 'TYPE_SITE')) NOT VALID;

-- SUPPRESSION DU SCHEMA SYNTHESE

DROP SCHEMA gn_synthese CASCADE;

-- Triger gn_commons
CREATE OR REPLACE FUNCTION gn_commons.fct_trg_add_default_validation_status()
  RETURNS trigger AS
$BODY$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theidtablelocation int;
	theuuidfieldname character varying(50);
	theuuid uuid;
  thecomment text := 'auto = default value';
BEGIN
	--retrouver l'id de la table source stockant l'enregistrement en cours de validation
	SELECT INTO theidtablelocation gn_commons.get_table_location_id(theschema,thetable);
  --retouver le nom du champ stockant l'uuid de l'enregistrement en cours de validation
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
  --récupérer l'uuid de l'enregistrement en cours de validation
	EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
  --insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_validations (id_table_location,uuid_attached_row,id_nomenclature_valid_status,id_validator,validation_comment,validation_date)
  VALUES(
    theidtablelocation,
    theuuid,
    ref_nomenclatures.get_default_nomenclature_value('STATUT_VALID'), --comme la fonction est générique, cette valeur par défaut doit exister et est la même pour tous les modules
    null,
    thecomment,
    NOW()
  );
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Suppression des tables et fonctions obselètes
DROP FUNCTION ref_nomenclatures.get_default_nomenclature_value(integer, integer);
DROP FUNCTION ref_nomenclatures.get_id_nomenclature(integer, character varying);

DROP FUNCTION gn_synthese.get_default_nomenclature_value(integer, integer, character varying, character varying);


DROP TABLE gn_meta.t_parameters;

DROP FUNCTION gn_meta.get_default_parameter(text, integer);
