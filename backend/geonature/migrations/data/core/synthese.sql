-- Création du schéma "gn_synthese" en version 2.7.5
-- A partir de la version 2.8.0, les évolutions de la BDD sont gérées dans des migrations Alembic

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


------------------------
--TABLES AND SEQUENCES--
------------------------

CREATE TABLE t_sources (
    id_source serial NOT NULL,
    name_source character varying(255) NOT NULL,
    desc_source text,
    entity_source_pk_field character varying(255),
    url_source character varying(255),
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
    grp_method character varying(255),
    id_nomenclature_obs_technique integer DEFAULT get_default_nomenclature_value('METH_OBS'),
    id_nomenclature_bio_status integer DEFAULT get_default_nomenclature_value('STATUT_BIO'),
    id_nomenclature_bio_condition integer DEFAULT get_default_nomenclature_value('ETA_BIO'),
    id_nomenclature_naturalness integer DEFAULT get_default_nomenclature_value('NATURALITE'),
    id_nomenclature_exist_proof integer DEFAULT get_default_nomenclature_value('PREUVE_EXIST'),
    id_nomenclature_valid_status integer DEFAULT get_default_nomenclature_value('STATUT_VALID'),
    id_nomenclature_diffusion_level integer,
    id_nomenclature_life_stage integer DEFAULT get_default_nomenclature_value('STADE_VIE'),
    id_nomenclature_sex integer DEFAULT get_default_nomenclature_value('SEXE'),
    id_nomenclature_obj_count integer DEFAULT get_default_nomenclature_value('OBJ_DENBR'),
    id_nomenclature_type_count integer DEFAULT get_default_nomenclature_value('TYP_DENBR'),
    id_nomenclature_sensitivity integer,
    id_nomenclature_observation_status integer DEFAULT get_default_nomenclature_value('STATUT_OBS'),
    id_nomenclature_blurring integer DEFAULT get_default_nomenclature_value('DEE_FLOU'),
    id_nomenclature_source_status integer DEFAULT get_default_nomenclature_value('STATUT_SOURCE'),
    id_nomenclature_info_geo_type integer DEFAULT get_default_nomenclature_value('TYP_INF_GEO'),
    id_nomenclature_behaviour integer DEFAULT get_default_nomenclature_value('OCC_COMPORTEMENT'),
    id_nomenclature_biogeo_status integer DEFAULT get_default_nomenclature_value('STAT_BIOGEO'),
    reference_biblio character varying(5000),
    count_min integer,
    count_max integer,
    cd_nom integer,
    cd_hab integer,
    nom_cite character varying(1000) NOT NULL,
    meta_v_taxref character varying(50) DEFAULT gn_commons.get_default_parameter('taxref_version',NULL),
    sample_number_proof text,
    digital_proof text,
    non_digital_proof text,
    altitude_min integer,
    altitude_max integer,
    depth_min integer,
    depth_max integer,
    place_name character varying(500),
    the_geom_4326 public.geometry(Geometry,4326),
    the_geom_point public.geometry(Point,4326),
    the_geom_local public.geometry(Geometry,:local_srid),
    precision integer,
    id_area_attachment integer,
    date_min timestamp without time zone NOT NULL,
    date_max timestamp without time zone NOT NULL,
    validator character varying(1000),
    validation_comment text,
    observers character varying(1000),
    determiner character varying(1000),
    id_digitiser integer,
    id_nomenclature_determination_method integer DEFAULT gn_synthese.get_default_nomenclature_value('METH_DETERMIN'),
    comment_context text,
    comment_description text,
    additional_data jsonb,
    meta_validation_date timestamp without time zone,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    last_action character(1),
    CONSTRAINT enforce_dims_the_geom_4326 CHECK ((public.st_ndims(the_geom_4326) = 2)),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_point CHECK ((public.st_ndims(the_geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(the_geom_point) = 'POINT'::text) OR (the_geom_point IS NULL))),
    CONSTRAINT enforce_srid_the_geom_4326 CHECK ((public.st_srid(the_geom_4326) = 4326)),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = :local_srid)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 4326))
);
COMMENT ON TABLE synthese IS 'Table de synthèse destinée à recevoir les données de tous les protocoles. Pour consultation uniquement';
COMMENT ON COLUMN gn_synthese.synthese.id_source
  IS 'Permet d''identifier la localisation de l''enregistrement correspondant dans les schémas et tables de la base';
COMMENT ON COLUMN gn_synthese.synthese.id_module
  IS 'Permet d''identifier le module qui a permis la création de l''enregistrement. Ce champ est en lien avec utilisateurs.t_applications et permet de gérer le CRUVED grace à la table utilisateurs.cor_app_privileges';
COMMENT ON COLUMN gn_synthese.synthese.comment_context
  IS 'Commentaire du releve (ou regroupement)';
COMMENT ON COLUMN gn_synthese.synthese.comment_description
  IS 'Commentaire de l''occurrence';
COMMENT ON COLUMN gn_synthese.synthese.id_area_attachment
  IS 'Id area du rattachement géographique - cas des observation sans géométrie précise';
COMMENT ON COLUMN gn_synthese.synthese.id_nomenclature_obs_technique
  IS 'Correspondance champs standard occtax = obsTechnique. En raison d''un changement de nom, le code nomenclature associé reste ''METH_OBS'' ';
COMMENT ON COLUMN gn_synthese.synthese.id_area_attachment
  IS 'Id area du rattachement géographique - cas des observations sans géométrie précise';

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


---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_sources ADD CONSTRAINT pk_t_sources PRIMARY KEY (id_source);

ALTER TABLE ONLY synthese ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);

ALTER TABLE ONLY cor_area_synthese ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area);

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT pk_gn_synthese_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);

ALTER TABLE ONLY cor_observer_synthese ADD CONSTRAINT pk_cor_observer_synthese PRIMARY KEY (id_synthese, id_role);

---------------
--FOREIGN KEY--
---------------

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_source FOREIGN KEY (id_source) REFERENCES t_sources(id_source) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_id_nomenclature_grp_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

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
    ADD CONSTRAINT fk_synthese_id_nomenclature_biogeo_status FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles (id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_area_attachment FOREIGN KEY (id_area_attachment) REFERENCES ref_geo.l_areas (id_area) ON UPDATE CASCADE;

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

---------------
--CONSTRAINTS--
---------------

ALTER TABLE ONLY t_sources
    ADD CONSTRAINT unique_name_source UNIQUE (name_source);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT unique_id_sinp_unique UNIQUE (unique_id_sinp);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_altitude_max CHECK (altitude_max >= altitude_min);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_depth_max CHECK (depth_max >= depth_min);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_date_max CHECK (date_max >= date_min);

ALTER TABLE ONLY synthese
    ADD CONSTRAINT check_synthese_count_max CHECK (count_max >= count_min);

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique,'METH_OBS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geo_object_nature,'NAT_OBJ_GEO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_typ_grp CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ,'TYP_GRP')) NOT VALID;

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
  ADD CONSTRAINT check_synthese_biogeo_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_biogeo_status,'STAT_BIOGEO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_info_geo_type_id_area_attachment CHECK (NOT (ref_nomenclatures.get_cd_nomenclature(id_nomenclature_info_geo_type) = '2'  AND id_area_attachment IS NULL )) NOT VALID;

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
	public.ST_Transform(public.ST_SetSRID(public.box2d(public.ST_extent(s.the_geom_local))::geometry,:local_srid), 4326) AS bbox4326
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

CREATE UNIQUE INDEX i_unique_t_sources_name_source ON t_sources USING btree (name_source);

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



----------------------
--FUNCTIONS TRIGGERS--
----------------------

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

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement()
  RETURNS trigger AS
$BODY$
  DECLARE
  BEGIN
  -- Intersection avec toutes les areas et écriture dans cor_area_synthese
      INSERT INTO gn_synthese.cor_area_synthese 
        SELECT
          updated_rows.id_synthese AS id_synthese,
          a.id_area AS id_area
        FROM NEW as updated_rows
        JOIN ref_geo.l_areas a
          ON public.ST_INTERSECTS(updated_rows.the_geom_local, a.geom)  
        WHERE a.enable IS TRUE AND (public.ST_GeometryType(updated_rows.the_geom_local) = 'ST_Point' OR NOT public.ST_TOUCHES(updated_rows.the_geom_local,a.geom));
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_update_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  geom_change boolean;
  BEGIN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;

  -- Intersection avec toutes les areas et écriture dans cor_area_synthese
    INSERT INTO gn_synthese.cor_area_synthese SELECT
      s.id_synthese AS id_synthese,
      a.id_area AS id_area
      FROM ref_geo.l_areas a
      JOIN gn_synthese.synthese s
        ON public.ST_INTERSECTS(s.the_geom_local, a.geom)
      WHERE a.enable IS TRUE AND s.id_synthese = NEW.id_synthese AND (ST_GeometryType(NEW.the_geom_local) = 'ST_Point' OR NOT public.ST_TOUCHES(NEW.the_geom_local,a.geom));
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$ 
  -- Calculate sensitivity and diffusion level on insert in synthese
    BEGIN
    WITH cte AS (
        SELECT 
        gn_sensitivity.get_id_nomenclature_sensitivity(
          updated_rows.date_min::date, 
          taxonomie.find_cdref(updated_rows.cd_nom), 
          updated_rows.the_geom_local,
          ('{"STATUT_BIO": ' || updated_rows.id_nomenclature_bio_status::text || '}')::jsonb
        ) AS id_nomenclature_sensitivity,
        id_synthese,
        t_diff.cd_nomenclature as cd_nomenclature_diffusion_level
      FROM NEW AS updated_rows
      LEFT JOIN ref_nomenclatures.t_nomenclatures t_diff ON t_diff.id_nomenclature = updated_rows.id_nomenclature_diffusion_level
      WHERE updated_rows.id_nomenclature_sensitivity IS NULL
    )
    UPDATE gn_synthese.synthese AS s
    SET 
      id_nomenclature_sensitivity = c.id_nomenclature_sensitivity,
      id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature(
        'NIV_PRECIS',
        gn_sensitivity.calculate_cd_diffusion_level(
          c.cd_nomenclature_diffusion_level, 
          t_sensi.cd_nomenclature
        )
        
      )
    FROM cte AS c
    LEFT JOIN ref_nomenclatures.t_nomenclatures t_sensi ON t_sensi.id_nomenclature = c.id_nomenclature_sensitivity
    WHERE c.id_synthese = s.id_synthese
  ;
    RETURN NULL;
    END;
  $$;

 CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$ 
  -- Calculate sensitivity and diffusion level on update in synthese
  DECLARE calculated_id_sensi integer;
    BEGIN
        SELECT 
        gn_sensitivity.get_id_nomenclature_sensitivity(
          NEW.date_min::date, 
          taxonomie.find_cdref(NEW.cd_nom), 
          NEW.the_geom_local,
          ('{"STATUT_BIO": ' || NEW.id_nomenclature_bio_status::text || '}')::jsonb
        ) INTO calculated_id_sensi;
      UPDATE gn_synthese.synthese 
      SET 
      id_nomenclature_sensitivity = calculated_id_sensi,
      -- On ne met pas à jour le niveau de diffusion s'il a déjà une valeur
      id_nomenclature_diffusion_level = CASE WHEN OLD.id_nomenclature_diffusion_level IS NULL THEN (
        SELECT ref_nomenclatures.get_id_nomenclature(
            'NIV_PRECIS',
            gn_sensitivity.calculate_cd_diffusion_level(
              ref_nomenclatures.get_cd_nomenclature(OLD.id_nomenclature_diffusion_level),
              ref_nomenclatures.get_cd_nomenclature(calculated_id_sensi)
          )
      	)
      )
      ELSE OLD.id_nomenclature_diffusion_level
      END
      WHERE id_synthese = OLD.id_synthese
      ;
      RETURN NULL;
    END;
  $$;  

---------
--VIEWS--
---------

-- Vue de l'arbre taxonomique des taxons présents dans la Synthèse (jusqu'à la famille)
CREATE OR REPLACE VIEW gn_synthese.v_tree_taxons_synthese AS
 WITH cd_famille AS (
         SELECT t_1.cd_ref,
            t_1.lb_nom AS nom_latin,
            t_1.nom_vern AS nom_francais,
            t_1.cd_nom,
            t_1.id_rang,
            t_1.regne,
            t_1.phylum,
            t_1.classe,
            t_1.ordre,
            t_1.famille,
            t_1.lb_nom
           FROM taxonomie.taxref t_1
          WHERE (t_1.lb_nom::text IN ( SELECT DISTINCT t_2.famille
                   FROM gn_synthese.synthese s
                     JOIN taxonomie.taxref t_2 ON t_2.cd_nom = s.cd_nom))
        ), cd_regne AS (
         SELECT DISTINCT taxref.cd_nom,
            taxref.regne
           FROM taxonomie.taxref
          WHERE taxref.id_rang::text = 'KD'::text AND taxref.cd_nom = taxref.cd_ref
        )
 SELECT t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre
   FROM ( SELECT DISTINCT t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT DISTINCT r.cd_nom
                   FROM cd_regne r
                  WHERE r.regne::text = t_1.regne::text) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre
           FROM cd_famille t_1
             LEFT JOIN taxonomie.taxref ph ON ph.id_rang::text = 'PH'::text AND ph.cd_nom = ph.cd_ref AND ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
             LEFT JOIN taxonomie.taxref cl ON cl.id_rang::text = 'CL'::text AND cl.cd_nom = cl.cd_ref AND cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
             LEFT JOIN taxonomie.taxref ord ON ord.id_rang::text = 'OR'::text AND ord.cd_nom = ord.cd_ref AND ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL) t
  ORDER BY t.id_regne, (COALESCE(t.id_embranchement, t.id_regne)), (COALESCE(t.id_classe, t.id_embranchement)), (COALESCE(t.id_ordre, t.id_classe));
COMMENT ON VIEW gn_synthese.v_tree_taxons_synthese IS 'Vue destinée à l''arbre taxonomique de la synthese. S''arrête  à la famille pour des questions de performances';


-- Vue décodant les nomenclatures
CREATE OR REPLACE VIEW gn_synthese.v_synthese_decode_nomenclatures AS
SELECT
s.id_synthese,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_geo_object_nature) AS nat_obj_geo,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_grp_typ) AS grp_typ,
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
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_determination_method) AS determination_method,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_behaviour) AS occ_behaviour,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_biogeo_status) AS occ_stat_biogeo
FROM gn_synthese.synthese s;

-- Vue listant les observations de la synthèse pour l'application WEB
CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app AS
 SELECT s.id_synthese,
    s.unique_id_sinp,
    s.unique_id_sinp_grp,
    s.id_source,
    s.entity_source_pk_value,
    s.count_min,
    s.count_max,
    s.nom_cite,
    s.meta_v_taxref,
    s.sample_number_proof,
    s.digital_proof,
    s.non_digital_proof,
    s.altitude_min,
    s.altitude_max,
    s.depth_min,
    s.depth_max,
    s.place_name,
    s.precision,
    s.the_geom_4326,
    public.ST_asgeojson(the_geom_4326),
    s.date_min,
    s.date_max,
    s.validator,
    s.validation_comment,
    s.observers,
    s.id_digitiser,
    s.determiner,
    s.comment_context,
    s.comment_description,
    s.meta_validation_date,
    s.meta_create_date,
    s.meta_update_date,
    s.last_action,
    d.id_dataset,
    d.dataset_name,
    d.id_acquisition_framework,
    s.id_nomenclature_geo_object_nature,
    s.id_nomenclature_info_geo_type,
    s.id_nomenclature_grp_typ,
    s.grp_method,
    s.id_nomenclature_obs_technique,
    s.id_nomenclature_bio_status,
    s.id_nomenclature_bio_condition,
    s.id_nomenclature_naturalness,
    s.id_nomenclature_exist_proof,
    s.id_nomenclature_valid_status,
    s.id_nomenclature_diffusion_level,
    s.id_nomenclature_life_stage,
    s.id_nomenclature_sex,
    s.id_nomenclature_obj_count,
    s.id_nomenclature_type_count,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_observation_status,
    s.id_nomenclature_blurring,
    s.id_nomenclature_source_status,
    s.id_nomenclature_determination_method,
    s.id_nomenclature_behaviour,
    s.reference_biblio,
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
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;

-- Vue listant les observations pour l'export de la Synthèse
CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
 SELECT 
    s.id_synthese AS id_synthese,
    s.date_min::date AS date_debut,
    s.date_max::date AS date_fin,
    s.date_min::time AS heure_debut,
    s.date_max::time AS heure_fin,
    t.cd_nom AS cd_nom,
    t.cd_ref AS cd_ref,
    t.nom_valide AS nom_valide,
    t.nom_vern as nom_vernaculaire,
    s.nom_cite AS nom_cite,
    t.regne AS regne,
    t.group1_inpn AS group1_inpn,
    t.group2_inpn AS group2_inpn,
    t.classe AS classe,
    t.ordre AS ordre,
    t.famille AS famille,
    t.id_rang AS rang_taxo,
    s.count_min AS nombre_min,
    s.count_max AS nombre_max,
    s.altitude_min AS alti_min,
    s.altitude_max AS alti_max,
    s.depth_min AS prof_min,
    s.depth_max AS prof_max,
    s.observers AS observateurs,
    s.id_digitiser AS id_digitiser, -- Utile pour le CRUVED
    s.determiner AS determinateur,
    communes AS communes,
    public.ST_astext(s.the_geom_4326) AS geometrie_wkt_4326,
    public.ST_x(s.the_geom_point) AS x_centroid_4326,
    public.ST_y(s.the_geom_point) AS y_centroid_4326,
    public.ST_asgeojson(s.the_geom_4326) AS geojson_4326,-- Utile pour la génération de l'export en SHP
    public.ST_asgeojson(s.the_geom_local) AS geojson_local,-- Utile pour la génération de l'export en SHP
    s.place_name AS nom_lieu,
    s.comment_context AS comment_releve,
    s.comment_description AS comment_occurrence,
    s.validator AS validateur,
    n21.label_default AS niveau_validation,
    s.meta_validation_date as date_validation,
    s.validation_comment AS comment_validation,
    s.digital_proof AS preuve_numerique_url,
    s.non_digital_proof AS preuve_non_numerique,
    d.dataset_name AS jdd_nom,
    d.unique_dataset_id AS jdd_uuid,
    d.id_dataset AS jdd_id, -- Utile pour le CRUVED
    af.acquisition_framework_name AS ca_nom,
    af.unique_acquisition_framework_id AS ca_uuid,
    d.id_acquisition_framework AS ca_id,
    s.cd_hab AS cd_habref,
    hab.lb_code AS cd_habitat,
    hab.lb_hab_fr AS nom_habitat,
    s.precision as precision_geographique,
    n1.label_default AS nature_objet_geo,
    n2.label_default AS type_regroupement,
    s.grp_method AS methode_regroupement,
    n3.label_default AS technique_observation,
    n5.label_default AS biologique_statut,
    n6.label_default AS etat_biologique,
    n22.label_default AS biogeographique_statut,
    n7.label_default AS naturalite,
    n8.label_default AS preuve_existante,
    n9.label_default AS niveau_precision_diffusion,
    n10.label_default AS stade_vie,
    n11.label_default AS sexe,
    n12.label_default AS objet_denombrement,
    n13.label_default AS type_denombrement,
    n14.label_default AS niveau_sensibilite,
    n15.label_default AS statut_observation,
    n16.label_default AS floutage_dee,
    n17.label_default AS statut_source,
    n18.label_default AS type_info_geo,
    n19.label_default AS methode_determination,
    n20.label_default AS comportement,
    s.reference_biblio AS reference_biblio,
    s.entity_source_pk_value AS id_origine,
    s.unique_id_sinp AS uuid_perm_sinp,
    s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
    s.meta_create_date AS date_creation,
    s.meta_update_date AS date_modification,
    s.additional_data as champs_additionnels,
    COALESCE(s.meta_update_date, s.meta_create_date) AS derniere_action
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_meta.t_acquisition_frameworks af ON d.id_acquisition_framework = af.id_acquisition_framework
     LEFT OUTER JOIN (
        SELECT id_synthese, string_agg(DISTINCT area_name, ', ') AS communes
        FROM gn_synthese.cor_area_synthese cas
        LEFT OUTER JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
        JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code ='COM'
        GROUP BY id_synthese 
     ) sa ON sa.id_synthese = s.id_synthese
     LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s.id_nomenclature_bio_condition = n6.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s.id_nomenclature_naturalness = n7.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s.id_nomenclature_exist_proof = n8.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s.id_nomenclature_obj_count = n12.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s.id_nomenclature_type_count = n13.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s.id_nomenclature_sensitivity = n14.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s.id_nomenclature_blurring = n16.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s.id_nomenclature_determination_method = n19.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON s.id_nomenclature_valid_status = n21.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n22 ON s.id_nomenclature_biogeo_status = n22.id_nomenclature
     LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = s.cd_hab;


-- Vue d'export des métadonnées
CREATE OR REPLACE VIEW gn_synthese.v_metadata_for_export AS
 WITH count_nb_obs AS (
         SELECT count(*) AS nb_obs,
            synthese.id_dataset
           FROM gn_synthese.synthese
          GROUP BY synthese.id_dataset
        )
 SELECT d.dataset_name AS jeu_donnees,
    d.id_dataset AS jdd_id,
    d.unique_dataset_id AS jdd_uuid,
    af.acquisition_framework_name AS cadre_acquisition,
    af.unique_acquisition_framework_id AS ca_uuid,
    string_agg(DISTINCT concat(COALESCE(orga.nom_organisme, ((roles.nom_role::text || ' '::text) || roles.prenom_role::text)::character varying), ' (', nomencl.label_default,')'), ', '::text) AS acteurs,
    count_nb_obs.nb_obs AS nombre_obs
   FROM gn_meta.t_datasets d
     JOIN gn_meta.t_acquisition_frameworks af ON af.id_acquisition_framework = d.id_acquisition_framework
     LEFT JOIN gn_meta.cor_dataset_actor act ON act.id_dataset = d.id_dataset
     LEFT JOIN ref_nomenclatures.t_nomenclatures nomencl ON nomencl.id_nomenclature = act.id_nomenclature_actor_role
     LEFT JOIN utilisateurs.bib_organismes orga ON orga.id_organisme = act.id_organism
     LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = act.id_role
     JOIN count_nb_obs ON count_nb_obs.id_dataset = d.id_dataset
  GROUP BY d.id_dataset, d.unique_dataset_id, d.dataset_name, af.acquisition_framework_name, af.unique_acquisition_framework_id, count_nb_obs.nb_obs;

-- Vue des taxons par unité géographique, avec nombre d’observations et date de dernière observation
CREATE OR REPLACE VIEW gn_synthese.v_area_taxon AS
SELECT s.cd_nom, c.id_area, count(s.id_synthese) as nb_obs, max(s.date_min) as last_date
FROM gn_synthese.synthese s
JOIN gn_synthese.cor_area_synthese c ON s.id_synthese = c.id_synthese
JOIN ref_geo.l_areas la ON la.id_area = c.id_area
JOIN ref_geo.bib_areas_types bat ON bat.id_type = la.id_type
JOIN gn_commons.t_parameters tp ON tp.parameter_name = 'occtaxmobile_area_type' AND tp.parameter_value = bat.type_code
GROUP BY c.id_area, s.cd_nom;

-- Vue des couleurs des taxons par unité géographique
CREATE OR REPLACE VIEW gn_synthese.v_color_taxon_area AS
SELECT cd_nom, id_area, nb_obs, last_date,
 CASE
  WHEN date_part('day', (now() - last_date)) < 365 THEN 'grey'
  ELSE 'red'
 END as color
FROM gn_synthese.v_area_taxon;


-- Vue export des taxons de la synthèse
-- Première version qui reste à affiner/étoffer
CREATE OR REPLACE VIEW gn_synthese.v_synthese_taxon_for_export_view AS
 SELECT DISTINCT
    ref.nom_valide,
    ref.cd_ref,
    ref.nom_vern,
    ref.group1_inpn,
    ref.group2_inpn,
    ref.regne,
    ref.phylum,
    ref.classe,
    ref.ordre,
    ref.famille,
    ref.id_rang
FROM gn_synthese.synthese  s
JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
JOIN taxonomie.taxref ref ON t.cd_ref = ref.cd_nom;


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


CREATE TRIGGER tri_insert_cor_area_synthese
  AFTER insert ON gn_synthese.synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement();

CREATE TRIGGER tri_update_cor_area_synthese
  AFTER UPDATE OF the_geom_local, the_geom_4326 ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_trig_update_in_cor_area_synthese();

CREATE TRIGGER tri_insert_calculate_sensitivity
  AFTER INSERT ON gn_synthese.synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement();
  
CREATE TRIGGER tri_update_calculate_sensitivity
  AFTER UPDATE OF date_min, date_max, cd_nom, the_geom_local, id_nomenclature_bio_status ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row();


--------
--DATA--
--------

INSERT INTO gn_commons.t_modules (module_code, module_label, module_picto, module_desc, module_path, module_target, active_frontend, active_backend, module_doc_url) VALUES
('SYNTHESE', 'Synthese', 'fa-search', 'Application synthese', 'synthese', '_self', 'true', 'true', 'http://docs.geonature.fr/user-manual.html#synthese');


-- Fonctions import dans la synthese

CREATE OR REPLACE FUNCTION gn_synthese.import_json_row_format_insert_data(column_name varchar, data_type varchar, postgis_maj_num_version int)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	col_srid int;
BEGIN
	-- Gestion de postgis 3
	IF ((postgis_maj_num_version > 2) AND (data_type = 'geometry')) THEN
		col_srid := (SELECT find_srid('gn_synthese', 'synthese', column_name));
		RETURN '(st_setsrid(ST_GeomFromGeoJSON(datain->>''' || column_name  || '''), ' || col_srid::text || '))' || COALESCE('::' || data_type, '');
	ELSE
		RETURN '(datain->>''' || column_name  || ''')' || COALESCE('::' || data_type, '');
	END IF;

END;
$function$
;

  CREATE OR REPLACE FUNCTION gn_synthese.import_json_row(datain jsonb, datageojson text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
  DECLARE
    insert_columns text;
    select_columns text;
    update_columns text;

    geom geometry;
    geom_data jsonb;
    local_srid int;

   postgis_maj_num_version int;
BEGIN


  -- Import des données dans une table temporaire pour faciliter le traitement
  DROP TABLE IF EXISTS tmp_process_import;
  CREATE TABLE tmp_process_import (
      id_synthese int,
      datain jsonb,
      action char(1)
  );
  INSERT INTO tmp_process_import (datain)
  SELECT datain;

  postgis_maj_num_version := (SELECT split_part(version, '.', 1)::int FROM pg_available_extension_versions WHERE name = 'postgis' AND installed = true);

  -- Cas ou la geométrie est passée en geojson
  IF NOT datageojson IS NULL THEN
    geom := (SELECT ST_setsrid(ST_GeomFromGeoJSON(datageojson), 4326));
    local_srid := (SELECT parameter_value FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid');
    geom_data := (
        SELECT json_build_object(
            'the_geom_4326',geom,
            'the_geom_point',(SELECT ST_centroid(geom)),
            'the_geom_local',(SELECT ST_transform(geom, local_srid))
        )
    );

    UPDATE tmp_process_import d
      SET datain = d.datain || geom_data;
  END IF;

-- ############ TEST

  -- colonne unique_id_sinp exists
  IF EXISTS (
        SELECT 1 FROM jsonb_object_keys(datain) column_name WHERE column_name =  'unique_id_sinp'
    ) IS FALSE THEN
        RAISE NOTICE 'Column unique_id_sinp is mandatory';
        RETURN FALSE;
  END IF ;

-- ############ mapping colonnes

  WITH import_col AS (
    SELECT jsonb_object_keys(datain) AS column_name
  ), synt_col AS (
      SELECT column_name, column_default, CASE WHEN data_type = 'USER-DEFINED' THEN udt_name ELSE data_type END as data_type
      FROM information_schema.columns
      WHERE table_schema || '.' || table_name = 'gn_synthese.synthese'
  )
  SELECT
      string_agg(s.column_name, ',')  as insert_columns,
      string_agg(
          CASE
              WHEN NOT column_default IS NULL THEN
              'COALESCE(' || gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version) || ', ' || column_default || ') as ' || i.column_name
          ELSE gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version)
          END, ','
      ) as select_columns ,
      string_agg(
          s.column_name || '=' ||
          CASE
            WHEN NOT column_default IS NULL
            	THEN  'COALESCE(' || gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version) || ', ' || column_default || ') '
  			ELSE gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version)
          END
      , ',')
  INTO insert_columns, select_columns, update_columns
  FROM synt_col s
  JOIN import_col i
  ON i.column_name = s.column_name;

  -- ############# IMPORT DATA
  IF EXISTS (
      SELECT 1
      FROM   gn_synthese.synthese
      WHERE  unique_id_sinp = (datain->>'unique_id_sinp')::uuid
  ) IS TRUE THEN
    -- Update
    EXECUTE ' WITH i_row AS (
          UPDATE gn_synthese.synthese s SET ' || update_columns ||
          ' FROM  tmp_process_import
          WHERE s.unique_id_sinp =  (datain->>''unique_id_sinp'')::uuid
          RETURNING s.id_synthese, s.unique_id_sinp
          )
          UPDATE tmp_process_import d SET id_synthese = i_row.id_synthese
          FROM i_row
          WHERE unique_id_sinp = i_row.unique_id_sinp
          ' ;
  ELSE
    -- Insert
    EXECUTE 'WITH i_row AS (
          INSERT INTO gn_synthese.synthese ( ' || insert_columns || ')
          SELECT ' || select_columns ||
          ' FROM tmp_process_import
          RETURNING id_synthese, unique_id_sinp
          )
          UPDATE tmp_process_import d SET id_synthese = i_row.id_synthese
          FROM i_row
          WHERE unique_id_sinp = i_row.unique_id_sinp
          ' ;
  END IF;

  -- Import des cor_observers
  DELETE FROM gn_synthese.cor_observer_synthese
  USING tmp_process_import
  WHERE cor_observer_synthese.id_synthese = tmp_process_import.id_synthese;

  IF jsonb_typeof(datain->'ids_observers') = 'array' THEN
    INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
    SELECT DISTINCT id_synthese, (jsonb_array_elements(t.datain->'ids_observers'))::text::int
    FROM tmp_process_import t;
  END IF;

  RETURN TRUE;
  END;
$function$
;

CREATE OR REPLACE FUNCTION gn_synthese.import_row_from_table(
        select_col_name character varying,
        select_col_val character varying,
        tbl_name character varying,
        limit_ integer,
        offset_ integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
    DECLARE
      select_sql text;
      import_rec record;
    BEGIN

      --test que la table/vue existe bien
      --42P01         undefined_table
      IF EXISTS (
          SELECT 1 FROM information_schema.tables t  WHERE t.table_schema ||'.'|| t.table_name = LOWER(tbl_name)
      ) IS FALSE THEN
          RAISE 'Undefined table: %', tbl_name USING ERRCODE = '42P01';
      END IF ;

      --test que la colonne existe bien
      --42703         undefined_column
      IF EXISTS (
          SELECT * FROM information_schema.columns  t  WHERE  t.table_schema ||'.'|| t.table_name = LOWER(tbl_name) AND column_name = select_col_name
      ) IS FALSE THEN
          RAISE 'Undefined column: %', select_col_name USING ERRCODE = '42703';
      END IF ;

        -- TODO transtypage en text pour des questions de généricité. A réflechir
        select_sql := 'SELECT row_to_json(c)::jsonb d
            FROM ' || LOWER(tbl_name) || ' c
            WHERE ' ||  select_col_name|| '::text = ''' || select_col_val || '''
            LIMIT ' || limit_ || '
            OFFSET ' || offset_ ;

        FOR import_rec IN EXECUTE select_sql LOOP
            PERFORM gn_synthese.import_json_row(import_rec.d);
        END LOOP;

      RETURN TRUE;
      END;
    $BODY$;
