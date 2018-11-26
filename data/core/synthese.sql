SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

CREATE SCHEMA gn_synthese;

SET search_path = gn_synthese, public, pg_catalog;

SET default_with_oids = false;


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION get_default_nomenclature_value(myidtype character varying, myidorganism integer DEFAULT 0, myregne character varying(20) DEFAULT '0', mygroup2inpn character varying(255) DEFAULT '0')
RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
--Return -1 if nothing matche with given parameters
  DECLARE
    theidnomenclature integer;
  BEGIN
      SELECT INTO theidnomenclature id_nomenclature
      FROM gn_synthese.defaults_nomenclatures_value
      WHERE mnemonique_type = myidtype
      AND (id_organism = 0 OR id_organism = myidorganism)
      AND (regne = '0' OR regne = myregne)
      AND (group2_inpn = '0' OR group2_inpn = mygroup2inpn)
      ORDER BY group2_inpn DESC, regne DESC, id_organism DESC LIMIT 1;
    IF (theidnomenclature IS NOT NULL) THEN
      RETURN theidnomenclature;
    END IF;
    RETURN NULL;
  END;
$$;

CREATE OR REPLACE FUNCTION get_ids_synthese_for_user_action(myuser integer, myaction text)
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

CREATE OR REPLACE FUNCTION fct_trig_insert_in_cor_area_synthese()
  RETURNS trigger AS
  $BODY$
  DECLARE
  id_area_loop integer;
  geom_change boolean;
  BEGIN
  geom_change = false;
  IF(TG_OP = 'UPDATE') THEN
	SELECT INTO geom_change ST_EQUALS(OLD.geom_local, NEW.geom_local);
  END IF;

  IF (geom_change) THEN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;
  END IF;

  -- intersection avec toutes les areas et écriture dans cor_area_synthese
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NOT geom_change )) THEN
      INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
      SELECT s.id_synthese, a.id_area
      FROM ref_geo.l_areas a
      JOIN gn_synthese.synthese s ON ST_INTERSECTS(s.the_geom_local, a.geom)
      WHERE s.id_synthese = NEW.id_synthese;

    END IF;
  RETURN NEW;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION fct_tri_maj_observers_txt()
  RETURNS trigger AS
$BODY$
DECLARE
  theobservers text;
  theidsynthese integer;
BEGIN
  IF (TG_OP = 'UPDATE') OR (TG_OP = 'INSERT') THEN
    theidsynthese = NEW.id_synthese; 
  END IF;
  IF (TG_OP = 'DELETE') THEN
    theidsynthese = OLD.id_synthese;
  END IF;
  --Construire le texte pour le champ observers de la synthese
  SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ')
  FROM utilisateurs.t_roles r
  WHERE r.id_role IN(SELECT id_role FROM gn_synthese.cor_observer_synthese WHERE id_synthese = theidsynthese);
  --mise à jour du champ observers dans la table synthese
  UPDATE gn_synthese.synthese 
  SET observers = theobservers
  WHERE id_synthese =  theidsynthese;
RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

------------------------
--TABLES AND SEQUENCES--
------------------------
CREATE TABLE t_sources (
    id_source serial NOT NULL,
    name_source character varying(255) NOT NULL,
    desc_source text,
    entity_source_pk_field character varying(255),
    url_source character varying(255),
    validable boolean NOT NULL DEFAULT true,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);


CREATE TABLE synthese (
    id_synthese integer NOT NULL,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    id_source integer,
    id_module integer,
    entity_source_pk_value character varying,
    id_dataset integer,
    id_nomenclature_geo_object_nature integer DEFAULT get_default_nomenclature_value('NAT_OBJ_GEO'),
    id_nomenclature_grp_typ integer DEFAULT get_default_nomenclature_value('TYP_GRP'),
    id_nomenclature_obs_meth integer DEFAULT get_default_nomenclature_value('METH_OBS'),
    id_nomenclature_obs_technique integer DEFAULT get_default_nomenclature_value('TECHNIQUE_OBS'),
    id_nomenclature_bio_status integer DEFAULT get_default_nomenclature_value('STATUT_BIO'),
    id_nomenclature_bio_condition integer DEFAULT get_default_nomenclature_value('ETA_BIO'),
    id_nomenclature_naturalness integer DEFAULT get_default_nomenclature_value('NATURALITE'),
    id_nomenclature_exist_proof integer DEFAULT get_default_nomenclature_value('PREUVE_EXIST'),
    id_nomenclature_valid_status integer DEFAULT get_default_nomenclature_value('STATUT_VALID'),
    id_nomenclature_diffusion_level integer DEFAULT get_default_nomenclature_value('NIV_PRECIS'),
    id_nomenclature_life_stage integer DEFAULT get_default_nomenclature_value('STADE_VIE'),
    id_nomenclature_sex integer DEFAULT get_default_nomenclature_value('SEXE'),
    id_nomenclature_obj_count integer DEFAULT get_default_nomenclature_value('OBJ_DENBR'),
    id_nomenclature_type_count integer DEFAULT get_default_nomenclature_value('TYP_DENBR'),
    id_nomenclature_sensitivity integer DEFAULT get_default_nomenclature_value('SENSIBILITE'),
    id_nomenclature_observation_status integer DEFAULT get_default_nomenclature_value('STATUT_OBS'),
    id_nomenclature_blurring integer DEFAULT get_default_nomenclature_value('DEE_FLOU'),
    id_nomenclature_source_status integer DEFAULT get_default_nomenclature_value('STATUT_SOURCE'),
    id_nomenclature_info_geo_type integer DEFAULT get_default_nomenclature_value('TYP_INF_GEO'),
    count_min integer,
    count_max integer,
    cd_nom integer,
    nom_cite character varying(1000) NOT NULL,
    meta_v_taxref character varying(50) DEFAULT gn_commons.get_default_parameter('taxref_version',NULL),
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    altitude_min integer,
    altitude_max integer,
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Point,4326),
    the_geom_local public.geometry(Geometry,MYLOCALSRID),
    date_min timestamp without time zone NOT NULL,
    date_max timestamp without time zone NOT NULL,
    validator character varying(1000),
    validation_comment text,
    observers character varying(1000),
    determiner character varying(1000),
    id_digitiser integer,
    id_nomenclature_determination_method integer DEFAULT gn_synthese.get_default_nomenclature_value('METH_DETERMIN'),
    comments text,
    meta_validation_date timestamp without time zone,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    last_action character(1),
    CONSTRAINT enforce_dims_the_geom_4326 CHECK ((public.st_ndims(the_geom_4326) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_point CHECK ((public.st_ndims(the_geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(the_geom_point) = 'POINT'::text) OR (the_geom_point IS NULL))),
    CONSTRAINT enforce_srid_the_geom_4326 CHECK ((public.st_srid(the_geom_4326) = 4326)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 4326))
);
COMMENT ON TABLE synthese IS 'Table de synthèse destinée à recevoir les données de tous les protocoles. Pour consultation uniquement';
COMMENT ON COLUMN gn_synthese.synthese.id_source
  IS 'Permet d''identifier la localisation de l''enregistrement correspondant dans les schémas et tables de la base';
COMMENT ON COLUMN gn_synthese.synthese.id_module
  IS 'Permet d''identifier le module qui a permis la création de l''enregistrement. Ce champ est en lien avec utilisateurs.t_applications et permet de gérer le CRUVED grace à la table utilisateurs.cor_app_privileges';

CREATE SEQUENCE synthese_id_synthese_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE synthese_id_synthese_seq OWNED BY synthese.id_synthese;
ALTER TABLE ONLY synthese ALTER COLUMN id_synthese SET DEFAULT nextval('synthese_id_synthese_seq'::regclass);

CREATE TABLE cor_area_synthese (
    id_synthese integer,
    id_area integer
);

CREATE TABLE cor_observer_synthese
(
  id_synthese integer NOT NULL,
  id_role integer NOT NULL
);

CREATE TABLE defaults_nomenclatures_value (
    mnemonique_type character varying(50) NOT NULL,
    id_organism integer NOT NULL DEFAULT 0,
    regne character varying(20) NOT NULL DEFAULT '0',
    group2_inpn character varying(255) NOT NULL DEFAULT '0',
    id_nomenclature integer NOT NULL
);

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
        concat(t_1.lb_nom, ' =  <i> ', t_1.nom_valide, '</i>' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1

  UNION
  SELECT t_1.cd_nom,
        t_1.cd_ref,
        concat(t_1.nom_vern, ' =  <i> ', t_1.nom_valide, '</i>' ) AS search_name,
        t_1.nom_valide,
        t_1.lb_nom,
        t_1.regne,
        t_1.group2_inpn
  FROM taxonomie.taxref t_1
  WHERE t_1.nom_vern IS NOT NULL AND t_1.cd_nom = t_1.cd_ref
) t
  WHERE t.cd_nom IN (SELECT DISTINCT cd_nom FROM gn_synthese.synthese);

  COMMENT ON TABLE taxons_synthese_autocomplete
     IS 'Table construite à partir d''une requete sur la base et mise à jour via le trigger trg_refresh_taxons_forautocomplete de la table gn_synthese';

---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_sources ADD CONSTRAINT pk_t_sources PRIMARY KEY (id_source);

ALTER TABLE ONLY synthese ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);

ALTER TABLE ONLY cor_area_synthese ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area);

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT pk_gn_synthese_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);

ALTER TABLE ONLY cor_observer_synthese ADD CONSTRAINT pk_cor_observer_synthese PRIMARY KEY (id_synthese, id_role);

ALTER TABLE ONLY taxons_synthese_autocomplete ADD CONSTRAINT pk_taxons_synthese_autocomplete PRIMARY KEY (cd_nom, search_name);



---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_source FOREIGN KEY (id_source) REFERENCES t_sources(id_source) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_module FOREIGN KEY (id_module) REFERENCES utilisateurs.t_applications(id_application) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_id_nomenclature_grp_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_obs_meth FOREIGN KEY (id_nomenclature_obs_meth) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_bio_status FOREIGN KEY (id_nomenclature_bio_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_bio_condition FOREIGN KEY (id_nomenclature_bio_condition) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_exist_proof FOREIGN KEY (id_nomenclature_exist_proof) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_valid_status FOREIGN KEY (id_nomenclature_valid_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_diffusion_level FOREIGN KEY (id_nomenclature_diffusion_level) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_life_stage FOREIGN KEY (id_nomenclature_life_stage) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_sex FOREIGN KEY (id_nomenclature_sex) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_obj_count FOREIGN KEY (id_nomenclature_obj_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_type_count FOREIGN KEY (id_nomenclature_type_count) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_sensitivity FOREIGN KEY (id_nomenclature_sensitivity) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_observation_status FOREIGN KEY (id_nomenclature_observation_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_blurring FOREIGN KEY (id_nomenclature_blurring) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_source_status FOREIGN KEY (id_nomenclature_source_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_info_geo_type FOREIGN KEY (id_nomenclature_info_geo_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_determination_method FOREIGN KEY (id_nomenclature_determination_method) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles (id_role) ON UPDATE CASCADE;


ALTER TABLE ONLY cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_synthese FOREIGN KEY (id_synthese) REFERENCES synthese(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_observer_synthese
    ADD CONSTRAINT fk_gn_synthese_id_synthese FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_observer_synthese
    ADD CONSTRAINT fk_gn_synthese_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY taxons_synthese_autocomplete
    ADD CONSTRAINT fk_taxons_synthese_autocomplete FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

--------------
--CONSTRAINS--
--------------
ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_date_max CHECK (date_max >= date_min);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_count_max CHECK (count_max >= count_min);

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_meth,'METH_OBS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geo_object_nature,'NAT_OBJ_GEO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_typ_grp CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ,'TYP_GRP')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique,'TECHNIQUE_OBS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_status,'STATUT_BIO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_condition,'ETA_BIO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_naturalness,'NATURALITE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exist_proof,'PREUVE_EXIST')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_valid_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_valid_status,'STATUT_VALID')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_diffusion_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_diffusion_level,'NIV_PRECIS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_life_stage,'STADE_VIE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_sex CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sex,'SEXE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obj_count,'OBJ_DENBR')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_count,'TYP_DENBR')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity,'SENSIBILITE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_observation_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_observation_status,'STATUT_OBS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_blurring,'DEE_FLOU')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status,'STATUT_SOURCE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_info_geo_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_info_geo_type,'TYP_INF_GEO')) NOT VALID;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type)) NOT VALID;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isgroup2inpn CHECK (taxonomie.check_is_group2inpn(group2_inpn::text) OR group2_inpn::text = '0'::text) NOT VALID;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_isregne CHECK (taxonomie.check_is_regne(regne::text) OR regne::text = '0'::text) NOT VALID;




----------------------
--MATERIALIZED VIEWS--
----------------------
--DROP MATERIALIZED VIEW gn_vm_min_max_for_taxons;
CREATE MATERIALIZED VIEW vm_min_max_for_taxons AS
WITH
s as (
  SELECT synt.cd_nom, t.cd_ref, the_geom_local, date_min, date_max, altitude_min, altitude_max
  FROM gn_synthese.synthese synt
  LEFT JOIN taxonomie.taxref t ON t.cd_nom = synt.cd_nom
  WHERE id_nomenclature_valid_status IN('1','2')
)
,loc AS (
  SELECT cd_ref,
	count(*) AS nbobs,
	ST_Transform(ST_SetSRID(box2d(st_extent(s.the_geom_local))::geometry,MYLOCALSRID), 4326) AS bbox4326
  FROM  s
  GROUP BY cd_ref
)
,dat AS (
  SELECT cd_ref,
	min(TO_CHAR(date_min, 'DDD')::int) AS daymin,
	max(TO_CHAR(date_max, 'DDD')::int) AS daymax
  FROM s
  GROUP BY cd_ref
)
,alt AS (
  SELECT cd_ref,
	min(altitude_min) AS altitudemin,
	max(altitude_max) AS altitudemax
  FROM s
  GROUP BY cd_ref
)
SELECT loc.cd_ref, nbobs,  daymin, daymax, altitudemin, altitudemax, bbox4326
FROM loc
LEFT JOIN alt ON alt.cd_ref = loc.cd_ref
LEFT JOIN dat ON dat.cd_ref = loc.cd_ref
ORDER BY loc.cd_ref;



-----------
--INDEXES--
-----------
CREATE INDEX i_synthese_t_sources ON synthese USING btree (id_source);

CREATE INDEX i_synthese_cd_nom ON synthese USING btree (cd_nom);

CREATE INDEX i_synthese_date_min ON synthese USING btree (date_min DESC);

CREATE INDEX i_synthese_date_max ON synthese USING btree (date_max DESC);

CREATE INDEX i_synthese_altitude_min ON synthese USING btree (altitude_min);

CREATE INDEX i_synthese_altitude_max ON synthese USING btree (altitude_max);

CREATE INDEX i_synthese_id_dataset ON synthese USING btree (id_dataset);

CREATE INDEX i_synthese_the_geom_local ON synthese USING gist (the_geom_local);

CREATE INDEX i_synthese_the_geom_4326 ON synthese USING gist (the_geom_4326);

CREATE INDEX i_synthese_the_geom_point ON synthese USING gist (the_geom_point);

CREATE UNIQUE INDEX i_unique_cd_ref_vm_min_max_for_taxons ON gn_synthese.vm_min_max_for_taxons USING btree (cd_ref);
--REFRESH MATERIALIZED VIEW CONCURRENTLY gn_synthese.vm_min_max_for_taxons;

-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION gn_synthese.fct_calculate_min_max_for_taxon(mycdnom integer)
  RETURNS TABLE(cd_ref int, nbobs bigint,  daymin int, daymax int, altitudemin int, altitudemax int, bbox4326 geometry) AS
$BODY$
  BEGIN
    --USAGE (getting all fields): SELECT * FROM gn_synthese.fct_calculate_min_max_for_taxon(351);
    --USAGE (getting one or more field) : SELECT cd_ref, bbox4326 FROM gn_synthese.fct_calculate_min_max_for_taxon(351)
    --See field names and types in TABLE declaration above
    --RETURN one row for the supplied cd_ref or cd_nom
    --This function can be use in a FROM clause, like a table or a view
	RETURN QUERY SELECT * FROM gn_synthese.vm_min_max_for_taxons WHERE cd_ref = taxonomie.find_cdref(mycdnom);
  END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-- A CREUSER : CAUSE A SYNTAXE ERROR

CREATE OR REPLACE FUNCTION fct_tri_refresh_vm_min_max_for_taxons()
  RETURNS trigger AS
$BODY$
BEGIN
      EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY gn_synthese.vm_min_max_for_taxons;';
      RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


----------------------
--FUNCTIONS TRIGGERS--
----------------------
CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  id_area_loop integer;
  geom_change boolean;
  BEGIN
  geom_change = false;
  IF(TG_OP = 'UPDATE') THEN
	SELECT INTO geom_change NOT ST_EQUALS(OLD.the_geom_local, NEW.the_geom_local);
  END IF;

  IF (geom_change) THEN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;
  END IF;

  -- intersection avec toutes les areas et écriture dans cor_area_synthese
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND geom_change )) THEN
      INSERT INTO gn_synthese.cor_area_synthese SELECT
	      s.id_synthese,
        a.id_area
        FROM ref_geo.l_areas a
        JOIN gn_synthese.synthese s ON ST_INTERSECTS(s.the_geom_local, a.geom)
        WHERE s.id_synthese = NEW.id_synthese;
    END IF;
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION gn_synthese.fct_trg_refresh_taxons_forautocomplete()
  RETURNS trigger AS
$BODY$
 DECLARE
  BEGIN

    IF TG_OP in ('DELETE', 'TRUNCATE', 'UPDATE') AND OLD.cd_nom NOT IN (SELECT DISTINCT cd_nom FROM gn_synthese.synthese) THEN
        DELETE FROM gn_synthese.taxons_synthese_autocomplete auto
        WHERE auto.cd_nom = OLD.cd_nom;
    END IF;

    IF TG_OP in ('INSERT', 'UPDATE') AND NEW.cd_nom NOT IN (SELECT DISTINCT cd_nom FROM gn_synthese.taxons_synthese_autocomplete) THEN
      INSERT INTO gn_synthese.taxons_synthese_autocomplete
      SELECT t.cd_nom,
              t.cd_ref,
          concat(t.lb_nom, ' = <i>', t.nom_valide, '</i>') AS search_name,
          t.nom_valide,
          t.lb_nom,
          t.regne,
          t.group2_inpn
      FROM taxonomie.taxref t  WHERE cd_nom = NEW.cd_nom;
      INSERT INTO gn_synthese.taxons_synthese_autocomplete
      SELECT t.cd_nom,
        t.cd_ref,
        concat(t.nom_vern, ' =  <i> ', t.nom_valide, '</i>' ) AS search_name,
        t.nom_valide,
        t.lb_nom,
        t.regne,
        t.group2_inpn
      FROM taxonomie.taxref t  WHERE t.nom_vern IS NOT NULL AND cd_nom = NEW.cd_nom;
    END IF;
  RETURN NULL;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

---------
--VIEWS--
---------

CREATE OR REPLACE VIEW gn_synthese.v_tree_taxons_synthese AS
WITH cd_synthese AS
	(SELECT DISTINCT cd_nom FROM gn_synthese.synthese)
	,taxon AS (
         SELECT n.id_nom,
            t_1.cd_ref,
            t_1.lb_nom AS nom_latin,
                CASE
                    WHEN n.nom_francais IS NULL THEN t_1.lb_nom
                    WHEN n.nom_francais = '' THEN t_1.lb_nom
                    ELSE n.nom_francais
                END AS nom_francais,
            t_1.cd_nom,
            t_1.id_rang,
            t_1.regne,
            t_1.phylum,
            t_1.classe,
            t_1.ordre,
            t_1.famille,
            t_1.lb_nom
           FROM taxonomie.taxref t_1
	    JOIN cd_synthese s ON s.cd_nom = t_1.cd_nom
            LEFT JOIN taxonomie.bib_noms n ON n.cd_nom = s.cd_nom


        ), cd_regne AS (
         SELECT DISTINCT taxref.cd_nom,
            taxref.regne
           FROM taxonomie.taxref
          WHERE taxref.id_rang::text = 'KD'::text AND taxref.cd_nom = taxref.cd_ref

        )
 SELECT t.id_nom,
    t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref') AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref') AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref') AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref') AS nom_ordre,
    COALESCE(t.id_famille, t.id_ordre) AS id_famille,
    COALESCE(t.nom_famille, ' Sans famille dans taxref') AS nom_famille
   FROM ( SELECT DISTINCT t_1.id_nom,
            t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT DISTINCT r.cd_nom
                   FROM cd_regne r
                  WHERE r.regne = t_1.regne) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre,
            f.cd_nom AS id_famille,
            t_1.famille AS nom_famille
           FROM taxon t_1
             LEFT JOIN taxonomie.taxref ph ON ph.id_rang = 'PH' AND ph.cd_nom = ph.cd_ref AND ph.lb_nom = t_1.phylum AND NOT t_1.phylum IS NULL
             LEFT JOIN taxonomie.taxref cl ON cl.id_rang = 'CL' AND cl.cd_nom = cl.cd_ref AND cl.lb_nom = t_1.classe AND NOT t_1.classe IS NULL
             LEFT JOIN taxonomie.taxref ord ON ord.id_rang = 'OR' AND ord.cd_nom = ord.cd_ref AND ord.lb_nom = t_1.ordre AND NOT t_1.ordre IS NULL
             LEFT JOIN taxonomie.taxref f ON f.id_rang = 'FM' AND f.cd_nom = f.cd_ref AND f.lb_nom = t_1.famille AND f.phylum = t_1.phylum AND NOT t_1.famille IS NULL) t
ORDER BY id_regne, id_embranchement, id_classe, id_ordre, id_famille;




CREATE OR REPLACE VIEW gn_synthese.v_synthese_decode_nomenclatures AS
SELECT
s.id_synthese,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_geo_object_nature) AS nat_obj_geo,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_grp_typ) AS grp_typ,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_obs_meth) AS obs_method,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_obs_technique) AS obs_technique,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_bio_status) AS bio_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_bio_condition) AS bio_condition,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_naturalness) AS naturalness,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_exist_proof) AS exist_proof ,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_valid_status) AS valid_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_diffusion_level) AS diffusion_level,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_life_stage) AS life_stage,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_sex) AS sex,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_obj_count) AS obj_count,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_type_count) AS type_count,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_sensitivity) AS sensitivity,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_observation_status) AS observation_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_blurring) AS blurring,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_source_status) AS source_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_info_geo_type) AS info_geo_type,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_determination_method) AS determination_method
FROM gn_synthese.synthese s;

CREATE VIEW gn_synthese.v_synthese_for_web_app AS
   SELECT
    s.id_synthese,
    unique_id_sinp,
    unique_id_sinp_grp,
    s.id_source ,
    entity_source_pk_value ,
    count_min ,
    count_max ,
    nom_cite ,
    meta_v_taxref ,
    sample_number_proof ,
    digital_proof ,
    non_digital_proof ,
    altitude_min ,
    altitude_max ,
    the_geom_4326,
    date_min,
    date_max,
    validator ,
    validation_comment ,
    observers ,
    id_digitiser,
    determiner ,
    comments ,
    meta_validation_date,
    s.meta_create_date,
    s.meta_update_date,
    last_action,
    d.id_dataset,
    d.dataset_name,
    d.id_acquisition_framework,
    id_nomenclature_geo_object_nature,
    id_nomenclature_info_geo_type,
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
    id_nomenclature_sensitivity,
    id_nomenclature_observation_status,
    id_nomenclature_blurring,
    s.id_nomenclature_source_status,
    sources.name_source,
    sources.url_source,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern
  FROM gn_synthese.synthese s
  JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
  JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
  JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
  ;

CREATE VIEW gn_synthese.v_synthese_for_export AS
   SELECT
    s.id_synthese,
    unique_id_sinp,
    unique_id_sinp_grp,
    s.id_source ,
    entity_source_pk_value ,
    count_min ,
    count_max ,
    nom_cite ,
    meta_v_taxref ,
    sample_number_proof ,
    digital_proof ,
    non_digital_proof ,
    altitude_min ,
    altitude_max ,
    the_geom_4326,
    the_geom_point,
    the_geom_local,
    st_astext(the_geom_4326) AS wkt,
    date_min,
    date_max,
    validator ,
    validation_comment ,
    observers ,
    id_digitiser,
    determiner ,
    comments ,
    meta_validation_date,
    s.meta_create_date,
    s.meta_update_date,
    last_action,
    d.id_dataset,
    d.dataset_name,
    d.id_acquisition_framework,
    deco.nat_obj_geo,
    deco.grp_typ,
    deco.obs_method,
    deco.obs_technique,
    deco.bio_status,
    deco.bio_condition,
    deco.naturalness,
    deco.exist_proof,
    deco.valid_status,
    deco.diffusion_level,
    deco.life_stage,
    deco.sex,
    deco.obj_count,
    deco.type_count,
    deco.sensitivity,
    deco.observation_status,
    deco.blurring,
    deco.source_status,
    sources.name_source,
    sources.url_source,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.nom_vern
  FROM gn_synthese.synthese s
  JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
  JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
  JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
  JOIN gn_synthese.v_synthese_decode_nomenclatures deco ON deco.id_synthese = s.id_synthese
  ;
------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_synthese
  BEFORE INSERT OR UPDATE
  ON synthese
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER tri_meta_dates_t_sources
  BEFORE INSERT OR UPDATE
  ON t_sources
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();

CREATE TRIGGER trg_maj_synthese_observers_txt
AFTER INSERT OR UPDATE OR DELETE
ON cor_observer_synthese
FOR EACH ROW
EXECUTE PROCEDURE gn_synthese.fct_tri_maj_observers_txt();


-- A RAJOUTER QUAND LA FONCTION TRIGGER SERA FONCTIONELLE
-- CREATE TRIGGER tri_refresh_vm_min_max_for_taxons
--   AFTER INSERT OR UPDATE OR DELETE
--   ON synthese
--   FOR EACH ROW
--   EXECUTE PROCEDURE fct_tri_refresh_vm_min_max_for_taxons();

CREATE TRIGGER tri_insert_cor_area_synthese
  AFTER INSERT OR UPDATE OF the_geom_local
  ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_trig_insert_in_cor_area_synthese();

CREATE TRIGGER trg_refresh_taxons_forautocomplete
  AFTER INSERT OR UPDATE OF cd_nom OR DELETE
  ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_trg_refresh_taxons_forautocomplete();

--------
--DATA--
--------

-- insertion dans utilisateurs.t_applications et gn_commons.t_modules
INSERT INTO utilisateurs.t_applications (nom_application, desc_application, id_parent)
SELECT 'synthese', 'Application synthese de GeoNature', id_application
FROM utilisateurs.t_applications WHERE nom_application = 'GeoNature';

INSERT INTO gn_commons.t_modules (id_module, module_name, module_label, module_picto, module_desc, module_path, module_target, module_comment, active_frontend, active_backend)
SELECT id_application ,'synthese', 'Synthese', 'fa-search', 'Application synthese', 'synthese', '_self', '', 'true', 'true'
FROM utilisateurs.t_applications WHERE nom_application = 'synthese';

