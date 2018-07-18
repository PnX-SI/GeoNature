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
CREATE OR REPLACE FUNCTION get_default_cd_nomenclature_value(myidtype character varying, myidorganism integer DEFAULT 0, myregne character varying(20) DEFAULT '0', mygroup2inpn character varying(255) DEFAULT '0') RETURNS integer
IMMUTABLE
LANGUAGE plpgsql
AS $$
--Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
--Return -1 if nothing matche with given parameters
  DECLARE
    thenomenclaturecd integer;
  BEGIN
      SELECT INTO thenomenclaturecd cd_nomenclature
      FROM gn_synthese.defaults_nomenclatures_value
      WHERE mnemonique_type = myidtype
      AND (id_organism = 0 OR id_organism = myidorganism)
      AND (regne = '0' OR regne = myregne)
      AND (group2_inpn = '0' OR group2_inpn = mygroup2inpn)
      ORDER BY group2_inpn DESC, regne DESC, id_organism DESC LIMIT 1;
    IF (thenomenclaturecd IS NOT NULL) THEN
      RETURN thenomenclaturecd;
    END IF;
    RETURN NULL;
  END;
$$;


------------------------
--TABLES AND SEQUENCES--
------------------------
CREATE TABLE t_sources (
    id_source integer NOT NULL,
    name_source character varying(255) NOT NULL,
    desc_source text,
    entity_source_pk_field character varying(255),
    url_source character varying(255),
    target character varying(10),
    picto_source character varying(255),
    groupe_source character varying(50) NOT NULL,
    active boolean NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);


CREATE TABLE synthese (
    id_synthese integer NOT NULL,
    unique_id_sinp uuid,
    unique_id_sinp_grp uuid,
    id_source integer,
    entity_source_pk_value character varying,
    id_dataset integer,
    cd_nomenclature_geo_object_nature character varying DEFAULT get_default_cd_nomenclature_value('NAT_OBJ_GEO'),
    cd_nomenclature_grp_typ character varying DEFAULT get_default_cd_nomenclature_value('TYP_GRP'),
    cd_nomenclature_obs_meth character varying DEFAULT get_default_cd_nomenclature_value('METH_OBS'),
    cd_nomenclature_obs_technique character varying DEFAULT get_default_cd_nomenclature_value('TECHNIQUE_OBS'),
    cd_nomenclature_bio_status character varying DEFAULT get_default_cd_nomenclature_value('STATUT_BIO'),
    cd_nomenclature_bio_condition character varying DEFAULT get_default_cd_nomenclature_value('ETA_BIO'),
    cd_nomenclature_naturalness character varying DEFAULT get_default_cd_nomenclature_value('NATURALITE'),
    cd_nomenclature_exist_proof character varying DEFAULT get_default_cd_nomenclature_value('PREUVE_EXIST'),
    cd_nomenclature_valid_status character varying DEFAULT get_default_cd_nomenclature_value('STATUT_VALID'),
    cd_nomenclature_diffusion_level character varying DEFAULT get_default_cd_nomenclature_value('NIV_PRECIS'),
    cd_nomenclature_life_stage character varying DEFAULT get_default_cd_nomenclature_value('STADE_VIE'),
    cd_nomenclature_sex character varying DEFAULT get_default_cd_nomenclature_value('SEXE'),
    cd_nomenclature_obj_count character varying DEFAULT get_default_cd_nomenclature_value('OBJ_DENBR'),
    cd_nomenclature_type_count character varying DEFAULT get_default_cd_nomenclature_value('TYP_DENBR'),
    cd_nomenclature_sensitivity character varying DEFAULT get_default_cd_nomenclature_value('SENSIBILITE'),
    cd_nomenclature_observation_status character varying DEFAULT get_default_cd_nomenclature_value('STATUT_OBS'),
    cd_nomenclature_blurring character varying DEFAULT get_default_cd_nomenclature_value('DEE_FLOU'),
    cd_nomenclature_source_status character varying DEFAULT get_default_cd_nomenclature_value('STATUT_SOURCE'),
    cd_nomenclature_info_geo_type character varying DEFAULT get_default_cd_nomenclature_value('TYP_INF_GEO'),
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
    the_geom_local public.geometry(Geometry,MYLOCALSRID),
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
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 4326))
);
COMMENT ON TABLE synthese IS 'Table de synthèse destinée à recevoir les données de tous les protocoles. Pour consultation uniquement';

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

CREATE TABLE defaults_nomenclatures_value (
    mnemonique_type character varying(50) NOT NULL,
    id_organism integer NOT NULL DEFAULT 0,
    regne character varying(20) NOT NULL DEFAULT '0',
    group2_inpn character varying(255) NOT NULL DEFAULT '0',
    cd_nomenclature character varying(20) NOT NULL
);
---------------
--PRIMARY KEY--
---------------

ALTER TABLE ONLY t_sources ADD CONSTRAINT pk_t_sources PRIMARY KEY (id_source);

ALTER TABLE ONLY synthese ADD CONSTRAINT pk_synthese PRIMARY KEY (id_synthese);

ALTER TABLE ONLY cor_area_synthese ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area);

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT pk_gn_synthese_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);


---------------
--FOREIGN KEY--
---------------
ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_dataset FOREIGN KEY (id_dataset) REFERENCES gn_meta.t_datasets(id_dataset) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_source FOREIGN KEY (id_source) REFERENCES t_sources(id_source) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY synthese
    ADD CONSTRAINT fk_synthese_id_validator FOREIGN KEY (id_validator) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

ALTER TABLE ONLY cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_synthese FOREIGN KEY (id_synthese) REFERENCES synthese(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY cor_area_synthese
    ADD CONSTRAINT fk_cor_area_synthese_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT fk_gn_synthese_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

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
  ADD CONSTRAINT check_synthese_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_obs_technique,'METH_OBS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_geo_object_nature,'NAT_OBJ_GEO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_typ_grp CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_grp_typ,'TYP_GRP')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_obs_technique,'TECHNIQUE_OBS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_bio_status,'STATUT_BIO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_bio_condition,'ETA_BIO')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_naturalness,'NATURALITE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_exist_proof,'PREUVE_EXIST')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_valid_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_valid_status,'STATUT_VALID')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_diffusion_level CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_diffusion_level,'NIV_PRECIS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_life_stage,'STADE_VIE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_sex CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_sex,'SEXE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_obj_count,'OBJ_DENBR')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_type_count,'TYP_DENBR')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_sensitivity,'SENSIBILITE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_observation_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_observation_status,'STATUT_OBS')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_blurring,'DEE_FLOU')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_source_status,'STATUT_SOURCE')) NOT VALID;

ALTER TABLE synthese
  ADD CONSTRAINT check_synthese_info_geo_type CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature_info_geo_type,'TYP_INF_GEO')) NOT VALID;


ALTER TABLE ONLY defaults_nomenclatures_value
    ADD CONSTRAINT check_gn_synthese_defaults_nomenclatures_value_is_nomenclature_in_type CHECK (ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(cd_nomenclature, mnemonique_type)) NOT VALID;

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
  WHERE cd_nomenclature_valid_status IN('1','2')
)
,loc AS (
  SELECT cd_ref,
	count(*) AS nbobs,
	ST_Transform(ST_SetSRID(box2d(st_extent(s.the_geom_local))::geometry,2154), 4326) AS bbox4326
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
CREATE INDEX _synthese_t_sources ON synthese USING btree (id_source);

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

CREATE OR REPLACE FUNCTION fct_tri_refresh_vm_min_max_for_taxons()
  RETURNS trigger AS
$BODY$
begin
        PERFORM REFRESH MATERIALIZED VIEW CONCURRENTLY gn_synthese.vm_min_max_for_taxons;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


---------
--VIEWS--
---------
CREATE OR REPLACE VIEW v_synthese_for_web_app AS
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

CREATE OR REPLACE VIEW v_synthese_decode_nomenclatures AS
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

CREATE TRIGGER tri_refresh_vm_min_max_for_taxons
  AFTER INSERT OR UPDATE OR DELETE
  ON synthese
  FOR EACH ROW
  EXECUTE PROCEDURE fct_tri_refresh_vm_min_max_for_taxons();


--------
--DATA--
--------
INSERT INTO t_sources (id_source, name_source, desc_source, entity_source_pk_field, url_source, target, picto_source, groupe_source, active) VALUES (0, 'API', 'Donnée externe non définie (insérée dans la synthese à partir du service REST de l''API sans entity_source_pk_value fourni)', NULL, NULL, NULL, NULL, 'NONE', false);
