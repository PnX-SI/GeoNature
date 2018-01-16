-- DROP SCHEMA IF EXISTS ref_geo CASCADE;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA IF NOT EXISTS ref_geo;

SET search_path = ref_geo, pg_catalog;

----------------------
--TABLES & SEQUENCES--
----------------------
CREATE TABLE bib_areas_types (
    id_type integer NOT NULL,
    id_nomenclature_area_type integer,
    type_name character varying(200),
    type_code character varying(25),
    type_desc text,
    ref_name character varying(200),
    ref_version integer,
    num_version character varying(50)
);
COMMENT ON COLUMN bib_areas_types.ref_name IS 'Indique le nom du référentiel géographique utilisé pour ce type';
COMMENT ON COLUMN bib_areas_types.ref_version IS 'Indique l''année du référentiel utilisé';

CREATE SEQUENCE l_areas_id_area_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE l_areas (
    id_area integer NOT NULL,
    id_type integer NOT NULL,
    area_name character varying(250),
    area_code character varying(25),
    geom public.geometry(MultiPolygon,MYLOCALSRID),
    centroid public.geometry(Point,MYLOCALSRID),
    source character varying(250),
    comment text,
    enable boolean NOT NULL DEFAULT (TRUE),
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,
    CONSTRAINT enforce_geotype_l_areas_geom CHECK (((public.geometrytype(geom) = 'MULTIPOLYGON'::text) OR (geom IS NULL))),
    CONSTRAINT enforce_srid_l_areas_geom CHECK ((public.st_srid(geom) = MYLOCALSRID)),
    CONSTRAINT enforce_geotype_l_areas_centroid CHECK (((public.geometrytype(centroid) = 'POINT'::text) OR (centroid IS NULL))),
    CONSTRAINT enforce_srid_l_areas_centroid CHECK ((public.st_srid(centroid) = MYLOCALSRID))
);
ALTER SEQUENCE l_areas_id_area_seq OWNED BY l_areas.id_area;
ALTER TABLE ONLY l_areas ALTER COLUMN id_area SET DEFAULT nextval('l_areas_id_area_seq'::regclass);

CREATE TABLE li_municipalities (
    id_municipality character varying(25) NOT NULL,
    id_area integer NOT NULL,
    status character varying(22),
    insee_com character varying(5),
    nom_com character varying(50),
    insee_arr character varying(2),
    nom_dep character varying(30),
    insee_dep character varying(3),
    nom_reg character varying(35),
    insee_reg character varying(2),
    code_epci character varying(9),
    plani_precision double precision,
    siren_code character varying(10),
    canton character varying(200),
    population integer,
    multican character varying(3),
    cc_nom character varying(250),
    cc_siren bigint,
    cc_nature character varying(5),
    cc_date_creation character varying(10),
    cc_date_effet character varying(10),
    insee_commune_nouvelle character varying(5),
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone
);

CREATE TABLE li_grids (
    id_grid character varying(50) NOT NULL,
    id_area integer NOT NULL,
    cxmin integer,
    cxmax integer,
    cymin integer,
    cymax integer
);

CREATE TABLE dem_vector
(
  gid serial NOT NULL,
  geom public.geometry(Geometry,MYLOCALSRID),
  val double precision
);



----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY li_municipalities
    ADD CONSTRAINT pk_li_municipalities PRIMARY KEY (id_municipality);

ALTER TABLE ONLY li_grids
    ADD CONSTRAINT pk_li_grids PRIMARY KEY (id_grid);

ALTER TABLE ONLY l_areas
    ADD CONSTRAINT pk_l_areas PRIMARY KEY (id_area);

ALTER TABLE ONLY bib_areas_types
    ADD CONSTRAINT pk_bib_areas_types PRIMARY KEY (id_type);

ALTER TABLE ONLY dem_vector
    ADD CONSTRAINT pk_dem_vector PRIMARY KEY (gid);


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY bib_areas_types
    ADD CONSTRAINT fk_bib_areas_types_id_nomenclature_area_type FOREIGN KEY (id_nomenclature_area_type) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY l_areas
    ADD CONSTRAINT fk_l_areas_id_type FOREIGN KEY (id_type) REFERENCES bib_areas_types(id_type) ON UPDATE CASCADE;

ALTER TABLE ONLY li_municipalities
    ADD CONSTRAINT fk_li_municipalities_id_area FOREIGN KEY (id_area) REFERENCES l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY li_grids
    ADD CONSTRAINT fk_li_grids_id_area FOREIGN KEY (id_area) REFERENCES l_areas(id_area) ON UPDATE CASCADE;


--------------
--CONSTRAINS--
--------------
ALTER TABLE bib_areas_types
  ADD CONSTRAINT check_bib_areas_types_area_type CHECK (ref_nomenclatures.check_nomenclature_type(id_nomenclature_area_type,22));


---------
--INDEX--
---------
CREATE INDEX index_l_areas_geom ON l_areas USING gist (geom);
CREATE INDEX index_l_areas_centroid ON l_areas USING gist (centroid);
CREATE INDEX index_dem_vector_geom ON dem_vector USING gist (geom);

------------
--TRIGGERS--
------------
CREATE TRIGGER tri_meta_dates_change_l_areas BEFORE INSERT OR UPDATE ON l_areas FOR EACH ROW EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
CREATE TRIGGER tri_meta_dates_change_li_municipalities BEFORE INSERT OR UPDATE ON li_municipalities FOR EACH ROW EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION fct_get_altitude_intersection(IN mygeom public.geometry)
  RETURNS TABLE(altitude_min integer, altitude_max integer) AS
$BODY$
DECLARE
    isrid int;
BEGIN
    SELECT gn_meta.get_default_parameter('local_srid', NULL) INTO isrid;
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



CREATE OR REPLACE FUNCTION fct_get_area_intersection(
  IN mygeom public.geometry,
  IN myidtype integer DEFAULT NULL::integer)
RETURNS TABLE(id_area integer, id_type integer, area_code character varying, area_name character varying) AS
$BODY$
DECLARE
  isrid int;
BEGIN
  SELECT gn_meta.get_default_parameter('local_srid', NULL) INTO isrid;
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

--------
--DATA--
--------

INSERT INTO bib_areas_types (id_type, type_name, type_code, type_desc, ref_name, ref_version) VALUES
(1, 'Coeurs des Parcs nationaux', 'ZC', NULL, NULL,NULL),
(2, 'znieff2', NULL, NULL, NULL,NULL),
(3, 'znieff1', NULL, NULL, NULL,NULL),
(4, 'Aires de protection de biotope', NULL, NULL, NULL,NULL),
(5, 'Réserves naturelles nationales', NULL, NULL, NULL,NULL),
(6, 'Réserves naturelles regionales', NULL, NULL, NULL,NULL),
(7, 'Natura 2000 - Zones de protection spéciales', 'ZPS', NULL, NULL,NULL),
(8, 'Natura 2000 - Sites d''importance communautaire', 'SIC', NULL, NULL,NULL),
(9, 'Zone d''importance pour la conservation des oiseaux', 'ZICO', NULL, NULL,NULL),
(10, 'Réserves nationales de chasse et faune sauvage', NULL, NULL, NULL,NULL),
(11, 'Réserves intégrales de parc national', NULL, NULL, NULL,NULL),
(12, 'Sites acquis des Conservatoires d''espaces naturels', NULL, NULL, NULL,NULL),
(13, 'Sites du Conservatoire du Littoral', NULL, NULL, NULL,NULL),
(14, 'Parcs naturels marins', NULL, NULL, NULL,NULL),
(15, 'Parcs naturels régionaux', 'PNR', NULL, NULL,NULL),
(16, 'Réserves biologiques', NULL, NULL, NULL,NULL),
(17, 'Réserves de biosphère', NULL, NULL, NULL,NULL),
(18, 'Réserves naturelles de Corse', NULL, NULL, NULL,NULL),
(19, 'Sites Ramsar', NULL, NULL, NULL,NULL),
(20, 'Aire d''adhésion des Parcs nationaux', 'AA', NULL, NULL,NULL),
(21, 'Natura 2000 - Zones spéciales de conservation', 'ZSC', NULL, NULL,NULL),
(22, 'Natura 2000 - Proposition de sites d''intéret communautaire', 'pSIC', NULL, NULL,NULL),
(23, 'Périmètre d''étude de la charte des Parcs nationaux', 'PEC', NULL, NULL,NULL),
(101, 'Communes', NULL, 'type commune', 'IGN admin_express',2017),
(102, 'Départements', NULL, 'type département', 'IGN admin_express',2017),
(201, 'Mailles10*10', NULL, 'type maille inpn 10*10', NULL,NULL),
(202, 'Mailles1*1', NULL, 'type maille inpn 1*1', NULL,NULL),
(10001, 'Secteurs', NULL, NULL, NULL,NULL),
(10002, 'Massifs', NULL, NULL, NULL,NULL),
(10003, 'Zones biogéographiques', NULL, NULL, NULL,NULL);
