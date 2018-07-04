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


CREATE OR REPLACE FUNCTION ref_nomenclatures.get_id_nomenclature_type(mytype character varying) RETURNS integer
IMMUTABLE
LANGUAGE plpgsql AS
$$
--Function which return the id_type from the mnemonique of a nomenclature type
DECLARE theidtype character varying;
  BEGIN
SELECT INTO theidtype id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = mytype;
return theidtype;
  END;
$$;

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

CREATE OR REPLACE FUNCTION ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(mycdnomenclature character varying , mytype character varying) RETURNS boolean
IMMUTABLE
LANGUAGE plpgsql AS 
$$
--Function that checks if an id_nomenclature matches with wanted nomenclature type (use mnemonique type)
  BEGIN
    IF (mycdnomenclature IN (SELECT cd_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(mytype))
        OR mycdnomenclature IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : cd_nomenclature and nomenclature type didn''t match. Use cd_nomenclature in corresponding type (mnemonique field). See ref_nomenclatures.t_nomenclatures.id_type and ref_nomenclatures.bib_nomenclatures_types.mnemonique';
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


-- SYNTHESE

-------------
--FUNCTIONS--
-------------


CREATE OR REPLACE FUNCTION gn_synthese.get_default_cd_nomenclature_value(myidtype character varying, myidorganism integer DEFAULT 0, myregne character varying(20) DEFAULT '0', mygroup2inpn character varying(255) DEFAULT '0') RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
--Return -1 if nothing matche with given parameters
  DECLARE
    thecdnomenclatureid integer;
  BEGIN
      SELECT INTO thecdnomenclatureid cd_nomenclature
      FROM gn_synthese.defaults_nomenclatures_value
      WHERE mnemonique_type = myidtype
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

-------------
----TABLE----
-------------

DROP TABLE gn_synthese.cor_area_synthese;
DROP TABLE gn_synthese.synthese;
DROP TABLE gn_synthese.defaults_nomenclatures_value;

CREATE TABLE gn_synthese.defaults_nomenclatures_value (
    mnemonique_type character varying(50) NOT NULL,
    id_organism integer NOT NULL DEFAULT 0,
    regne character varying(20) NOT NULL DEFAULT '0',
    group2_inpn character varying(255) NOT NULL DEFAULT '0',
    cd_nomenclature character varying(20) NOT NULL
);

CREATE TABLE gn_synthese.synthese (
    id_synthese integer NOT NULL,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    id_source integer,
    entity_source_pk_value integer,
    id_dataset integer,
    cd_nomenclature_geo_object_nature character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('NAT_OBJ_GEO'),
    cd_nomenclature_grp_typ character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('TYP_GRP'),
    cd_nomenclature_obs_meth character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('METH_OBS'),
    cd_nomenclature_obs_technique character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('TECHNIQUE_OBS'),
    cd_nomenclature_bio_status character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('STATUT_BIO'),
    cd_nomenclature_bio_condition character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('ETA_BIO'),
    cd_nomenclature_naturalness character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('NATURALITE'),
    cd_nomenclature_exist_proof character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('PREUVE_EXIST'),
    cd_nomenclature_valid_status character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('SENSIBILITE'),
    cd_nomenclature_diffusion_level character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('NIV_PRECIS'),
    cd_nomenclature_life_stage character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('STADE_VIE'),
    cd_nomenclature_sex character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('SEXE'),
    cd_nomenclature_obj_count character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('OBJ_DENBR'),
    cd_nomenclature_type_count character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('TYP_DENBR'),
    cd_nomenclature_sensitivity character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('SENSIBILITE'),
    cd_nomenclature_observation_status character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('STATUT_OBS'),
    cd_nomenclature_blurring character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('DEE_FLOU'),
    cd_nomenclature_source_status character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('STATUT_SOURCE'),
    cd_nomenclature_info_geo_type character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('TYP_INF_GEO'),
    id_municipality character varying(25),
    count_min integer,
    count_max integer,
    cd_nom integer,
    nom_cite character varying(255) NOT NULL,
    meta_v_taxref character varying(50) DEFAULT 'SELECT gn_commons.get_default_parameter(''taxref_version'',NULL)',
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    altitude_min integer,
    altitude_max integer,
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Point,4326),
    the_geom_local public.geometry(Geometry,2154),
    id_area integer,
    date_min date NOT NULL,
    date_max date NOT NULL,
    id_validator integer,
    validation_comment text,
    observers character varying(255),
    determiner character varying(255),
    cd_nomenclature_determination_method character varying(20) DEFAULT gn_synthese.get_default_cd_nomenclature_value('METH_DETERMIN'),
    comments text,
    meta_validation_date timestamp without time zone DEFAULT now(),
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    last_action character(1),
    CONSTRAINT enforce_dims_the_geom_4326 CHECK ((public.st_ndims(the_geom_4326) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_point CHECK ((public.st_ndims(the_geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(the_geom_point) = 'POINT'::text) OR (the_geom_point IS NULL))),
    CONSTRAINT enforce_srid_the_geom_4326 CHECK ((public.st_srid(the_geom_4326) = 4326)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = 2154)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 4326))
);
COMMENT ON TABLE gn_synthese.synthese IS 'Table de synthèse destinée à recevoir les données de tous les protocoles. Pour consultation uniquement';

CREATE TABLE gn_synthese.cor_area_synthese (
    id_synthese integer,
    id_area integer
);

---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY gn_synthese.synthese ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);

ALTER TABLE ONLY gn_synthese.cor_area_synthese ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area);

ALTER TABLE ONLY gn_synthese.defaults_nomenclatures_value
    ADD CONSTRAINT pk_gn_synthese_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);

---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_source FOREIGN KEY (id_source) REFERENCES gn_synthese.t_sources(id_source) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_validator FOREIGN KEY (id_validator) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_synthese.defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT check_synthese_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT check_synthese_date_max CHECK (date_max >= date_min);

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT check_synthese_count_max CHECK (count_max >= count_min);

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_obs_technique,'METH_OBS')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_geo_object_nature,'NAT_OBJ_GEO')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_typ_grp CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_grp_typ,'TYP_GRP')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_obs_technique,'TECHNIQUE_OBS')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_bio_status,'STATUT_BIO')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_bio_condition,'ETA_BIO')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_naturalness,'NATURALITE')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_exist_proof,'PREUVE_EXIST')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_valid_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_valid_status,'STATUT_VALID')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_diffusion_level CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_diffusion_level,'NIV_PRECIS')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_life_stage,'STADE_VIE')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_sex CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_sex,'SEXE')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_obj_count,'OBJ_DENBR')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_type_count,'TYP_DENBR')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_sensitivity,'SENSIBILITE')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_observation_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_observation_status,'STATUT_OBS')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_blurring,'DEE_FLOU')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_source_status,'STATUT_SOURCE')) NOT VALID;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_info_geo_type CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_info_geo_type,'TYP_INF_GEO')) NOT VALID;

ALTER TABLE ONLY gn_synthese.defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature, mnemonique_type)) NOT VALID;

ALTER TABLE ONLY gn_synthese.defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isgroup2inpn CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = '0'::text) NOT VALID;

ALTER TABLE ONLY gn_synthese.defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isregne CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = '0'::text) NOT VALID;


-- recréation des vues:

CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app AS
WITH nomenclatures AS (
  SELECT
    s.id_synthese, 
    n3.label_default AS nat_obj_geo,
    n24.label_default AS grp_typ,
    n14.label_default AS obs_meth,
    n100.label_default AS obs_technique,
    n13.label_default AS bio_status,
    n7.label_default AS bio_condition,
    n8.label_default AS naturalness,
    n15.label_default AS exist_proof,
    n101.label_default AS valid_status,
    n5.label_default AS diffusion_level,
    n10.label_default AS life_stage,
    n9.label_default AS sex,
    n6.label_default AS obj_count,
    n21.label_default AS type_count,
    n16.label_default AS sensitivity,
    n18.label_default AS observation_status,
    n4.label_default AS blurring,
    n19.label_default AS source_status,
    n20.label_default AS determination_method
FROM gn_synthese.synthese s
JOIN ref_nomenclatures.t_nomenclatures n3 ON n3.cd_nomenclature = s.cd_nomenclature_geo_object_nature
JOIN ref_nomenclatures.t_nomenclatures n24 ON n24.cd_nomenclature = s.cd_nomenclature_grp_typ
JOIN ref_nomenclatures.t_nomenclatures n14 ON n14.cd_nomenclature = s.cd_nomenclature_obs_meth
JOIN ref_nomenclatures.t_nomenclatures n100 ON n100.cd_nomenclature = s.cd_nomenclature_obs_technique
JOIN ref_nomenclatures.t_nomenclatures n13 ON n13.cd_nomenclature = s.cd_nomenclature_bio_status
JOIN ref_nomenclatures.t_nomenclatures n7 ON n7.cd_nomenclature = s.cd_nomenclature_bio_condition
JOIN ref_nomenclatures.t_nomenclatures n8 ON n8.cd_nomenclature = s.cd_nomenclature_naturalness
JOIN ref_nomenclatures.t_nomenclatures n15 ON n15.cd_nomenclature = s.cd_nomenclature_exist_proof
JOIN ref_nomenclatures.t_nomenclatures n101 ON n101.cd_nomenclature = s.cd_nomenclature_valid_status
JOIN ref_nomenclatures.t_nomenclatures n5 ON n5.cd_nomenclature = s.cd_nomenclature_diffusion_level
JOIN ref_nomenclatures.t_nomenclatures n10 ON n10.cd_nomenclature = s.cd_nomenclature_life_stage
JOIN ref_nomenclatures.t_nomenclatures n9 ON n9.cd_nomenclature = s.cd_nomenclature_sex
JOIN ref_nomenclatures.t_nomenclatures n6 ON n6.cd_nomenclature = s.cd_nomenclature_obj_count
JOIN ref_nomenclatures.t_nomenclatures n21 ON n21.cd_nomenclature = s.cd_nomenclature_type_count
JOIN ref_nomenclatures.t_nomenclatures n16 ON n16.cd_nomenclature = s.cd_nomenclature_sensitivity
JOIN ref_nomenclatures.t_nomenclatures n18 ON n18.cd_nomenclature = s.cd_nomenclature_observation_status
JOIN ref_nomenclatures.t_nomenclatures n4 ON n4.cd_nomenclature = s.cd_nomenclature_blurring
JOIN ref_nomenclatures.t_nomenclatures n19 ON n19.cd_nomenclature = s.cd_nomenclature_source_status
JOIN ref_nomenclatures.t_nomenclatures n20 ON n19.cd_nomenclature = s.cd_nomenclature_determination_method
)
SELECT 
  s.id_synthese, 
  s.id_source, 
  so.name_source,
  so.entity_source_pk_field,
  s.entity_source_pk_value,
  d.dataset_name,
  n.nat_obj_geo,
  n.grp_typ,
  n.obs_meth,
  n.obs_technique,
  n.bio_status,
  n.bio_condition,
  n.naturalness,
  n.exist_proof,
  n.valid_status,
  n.diffusion_level,
  n.life_stage,
  n.sex,
  n.obj_count,
  n.type_count,
  n.sensitivity,
  n.observation_status,
  n.blurring,
  n.source_status,
  m.insee_com, --TODO attention changer le JOIN en prod
  m.nom_com,
  s.count_min,
  s.count_max,
  s.cd_nom,
  t.nom_complet,
  COALESCE(t.nom_vern, 'Null'::character varying(255)) AS nom_vern,
  s.nom_cite,
  s.meta_v_taxref AS taxref_version,
  s.sample_number_proof,
  s.digital_proof,
  s.non_digital_proof,
  s.altitude_min,
  s.altitude_max,
  s.the_geom_point,
  s.the_geom_4326,
  s.date_min,
  s.date_max,
  v.prenom_role || ' ' || v.nom_role AS validateur,
  s.validation_comment,
  s.meta_validation_date AS validation_date,
  s.observers,
  s.determiner,
  n.determination_method,
  s.comments
FROM gn_synthese.synthese s
JOIN gn_synthese.t_sources so ON so.id_source = s.id_source
JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
JOIN nomenclatures n ON n.id_synthese = s.id_synthese
LEFT JOIN ref_geo.li_municipalities m ON m.insee_com = s.id_municipality --TODO attention changer le JOIN en prod
LEFT JOIN utilisateurs.t_roles v ON v.id_role = s.id_validator
JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_decode_nomenclatures AS 
 SELECT s.id_synthese,
    n3.label_default AS nat_obj_geo,
    n24.label_default AS grp_typ,
    n14.label_default AS obs_meth,
    n100.label_default AS obs_technique,
    n13.label_default AS bio_status,
    n7.label_default AS bio_condition,
    n8.label_default AS naturalness,
    n15.label_default AS exist_proof,
    n101.label_default AS valid_status,
    n5.label_default AS diffusion_level,
    n10.label_default AS life_stage,
    n9.label_default AS sex,
    n6.label_default AS obj_count,
    n21.label_default AS type_count,
    n16.label_default AS sensitivity,
    n18.label_default AS observation_status,
    n4.label_default AS blurring,
    n19.label_default AS source_status,
    n20.label_default AS determination_method
   FROM gn_synthese.synthese s
     JOIN ref_nomenclatures.t_nomenclatures n3 ON n3.cd_nomenclature = s.cd_nomenclature_geo_object_nature
     JOIN ref_nomenclatures.t_nomenclatures n24 ON n24.cd_nomenclature = s.cd_nomenclature_grp_typ
     JOIN ref_nomenclatures.t_nomenclatures n14 ON n14.cd_nomenclature = s.cd_nomenclature_obs_meth
     JOIN ref_nomenclatures.t_nomenclatures n100 ON n100.cd_nomenclature = s.cd_nomenclature_obs_technique
     JOIN ref_nomenclatures.t_nomenclatures n13 ON n13.cd_nomenclature = s.cd_nomenclature_bio_status
     JOIN ref_nomenclatures.t_nomenclatures n7 ON n7.cd_nomenclature = s.cd_nomenclature_bio_condition
     JOIN ref_nomenclatures.t_nomenclatures n8 ON n8.cd_nomenclature = s.cd_nomenclature_naturalness
     JOIN ref_nomenclatures.t_nomenclatures n15 ON n15.cd_nomenclature = s.cd_nomenclature_exist_proof
     JOIN ref_nomenclatures.t_nomenclatures n101 ON n101.cd_nomenclature = s.cd_nomenclature_valid_status
     JOIN ref_nomenclatures.t_nomenclatures n5 ON n5.cd_nomenclature = s.cd_nomenclature_diffusion_level
     JOIN ref_nomenclatures.t_nomenclatures n10 ON n10.cd_nomenclature = s.cd_nomenclature_life_stage
     JOIN ref_nomenclatures.t_nomenclatures n9 ON n9.cd_nomenclature = s.cd_nomenclature_sex
     JOIN ref_nomenclatures.t_nomenclatures n6 ON n6.cd_nomenclature = s.cd_nomenclature_obj_count
     JOIN ref_nomenclatures.t_nomenclatures n21 ON n21.cd_nomenclature = s.cd_nomenclature_type_count
     JOIN ref_nomenclatures.t_nomenclatures n16 ON n16.cd_nomenclature = s.cd_nomenclature_sensitivity
     JOIN ref_nomenclatures.t_nomenclatures n18 ON n18.cd_nomenclature = s.cd_nomenclature_observation_status
     JOIN ref_nomenclatures.t_nomenclatures n4 ON n4.cd_nomenclature = s.cd_nomenclature_blurring
     JOIN ref_nomenclatures.t_nomenclatures n19 ON n19.cd_nomenclature = s.cd_nomenclature_source_status
     JOIN ref_nomenclatures.t_nomenclatures n20 ON n19.cd_nomenclature = s.cd_nomenclature_determination_method
     ;

-- modif nom de champ

INSERT INTO gn_synthese.defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, cd_nomenclature) VALUES
('TYP_INF_GEO',0,0,0,'1')
,('NAT_OBJ_GEO',0,0,0,'NSP')
,('METH_OBS',0,0,0,'21')
,('ETA_BIO',0,0,0,'1')
,('STATUT_BIO',0,0,0,'1')
,('NATURALITE',0,0,0,'0')
,('PREUVE_EXIST',0,0,0,'0')
,('STATUT_VALID',0,0,0,'2')
,('NIV_PRECIS',0,0,0,'5')
,('STADE_VIE',0,0,0,'0')
,('SEXE',0,0,0,'6')
,('OBJ_DENBR',0,0,0,'NSP')
,('TYP_DENBR',0,0,0,'NSP')
,('STATUT_OBS',0,0,0,'NSP')
,('DEE_FLOU',0,0,0,'NON')
,('TYP_GRP',0,0,0,'NSP')
,('TECHNIQUE_OBS',0,0,0,'133')
,('SENSIBILITE',0,0,0,'0')
,('STATUT_SOURCE',0,0,0,'NSP')
,('METH_DETERMIN',0,0,0,'1') 
;


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


-- Suppression des fonction obselètes
DROP FUNCTION ref_nomenclatures.get_default_nomenclature_value(integer, integer);
DROP FUNCTION ref_nomenclatures.get_id_nomenclature(integer, character varying);

DROP FUNCTION gn_synthese.get_default_nomenclature_value(integer, integer, character varying, character varying);
