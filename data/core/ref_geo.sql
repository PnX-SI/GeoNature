-- DROP SCHEMA IF EXISTS ref_geo CASCADE;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA IF NOT EXISTS ref_geo;

SET search_path = ref_geo, pg_catalog;


-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_geom_local()
  RETURNS trigger AS
$BODY$
DECLARE
	the4326geomcol text := quote_ident(TG_ARGV[0]);
	thelocalgeomcol text := quote_ident(TG_ARGV[1]);
        thelocalsrid int;
        thegeomlocalvalue public.geometry;
        thegeomchange boolean;
BEGIN
	-- Test si la geom a été modifiée
	EXECUTE FORMAT(
		'SELECT ST_EQUALS($1.%I, $1.%I)', the4326geomcol, thelocalgeomcol
		) INTO thegeomchange USING NEW;
	-- si insertion ou geom modifiée, on calcule la geom locale
	IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NOT thegeomchange )) THEN
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


----------------------
--TABLES & SEQUENCES--
----------------------

CREATE SEQUENCE bib_areas_types_id_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE bib_areas_types (
    id_type integer NOT NULL,
    type_name character varying(200) NOT NULL,
    type_code character varying(25) NOT NULL,
    type_desc text,
    ref_name character varying(200),
    ref_version integer,
    num_version character varying(50)
);
COMMENT ON COLUMN bib_areas_types.ref_name IS 'Indique le nom du référentiel géographique utilisé pour ce type';
COMMENT ON COLUMN bib_areas_types.ref_version IS 'Indique l''année du référentiel utilisé';
ALTER SEQUENCE bib_areas_types_id_type_seq OWNED BY bib_areas_types.id_type;
ALTER TABLE ONLY bib_areas_types ALTER COLUMN id_type SET DEFAULT nextval('bib_areas_types_id_type_seq'::regclass);

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
ALTER TABLE l_areas ALTER COLUMN geom SET STORAGE EXTERNAL;

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

CREATE TABLE dem
(
  rid serial NOT NULL,
  rast public.raster
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

ALTER TABLE ONLY dem
  ADD CONSTRAINT pk_dem PRIMARY KEY (rid);
  
ALTER TABLE ONLY dem_vector
    ADD CONSTRAINT pk_dem_vector PRIMARY KEY (gid);


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY l_areas
    ADD CONSTRAINT fk_l_areas_id_type FOREIGN KEY (id_type) REFERENCES bib_areas_types(id_type) ON UPDATE CASCADE;

ALTER TABLE ONLY li_municipalities
    ADD CONSTRAINT fk_li_municipalities_id_area FOREIGN KEY (id_area) REFERENCES l_areas(id_area) ON UPDATE CASCADE;

ALTER TABLE ONLY li_grids
    ADD CONSTRAINT fk_li_grids_id_area FOREIGN KEY (id_area) REFERENCES l_areas(id_area) ON UPDATE CASCADE;


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
CREATE OR REPLACE FUNCTION ref_geo.fct_get_altitude_intersection(IN mygeom public.geometry)
  RETURNS TABLE(altitude_min integer, altitude_max integer) AS
$BODY$
DECLARE
    thesrid int;
    is_vectorized int;
BEGIN
  SELECT gn_commons.get_default_parameter('local_srid', NULL) INTO thesrid;
  SELECT COALESCE(gid, NULL) FROM ref_geo.dem_vector LIMIT 1 INTO is_vectorized;
	
  IF is_vectorized IS NULL THEN
    -- Use dem
    RETURN QUERY
    SELECT min((altitude).val)::integer AS altitude_min, max((altitude).val)::integer AS altitude_max
    FROM (
	SELECT ST_DumpAsPolygons(ST_clip(rast, 1
	, st_transform(myGeom,thesrid), true)) AS altitude
	FROM ref_geo.dem AS altitude 
	WHERE st_intersects(rast,st_transform(myGeom,thesrid))
    ) AS a;		
  -- Use dem_vector
  ELSE
    RETURN QUERY
    WITH d  as (
        SELECT st_transform(myGeom,thesrid) a
     )
    SELECT min(val)::int as altitude_min, max(val)::int as altitude_max
    FROM ref_geo.dem_vector, d
    WHERE st_intersects(a,geom);
  END IF;
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


CREATE OR REPLACE FUNCTION ref_geo.get_id_area_type(mytype character varying)
  RETURNS integer AS
$BODY$
--Function which return the id_type_area from the type_code of an area type
DECLARE theidtype character varying;
  BEGIN
SELECT INTO theidtype id_type FROM ref_geo.bib_areas_types WHERE type_code = mytype;
return theidtype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

-- Fonction trigger pour conserver l'intégriter entre deux champs géom
-- A TERMINER

-- CREATE OR REPLACE FUNCTION ref_geo.fct_tri_geom_integrity()
--   RETURNS trigger AS
-- $BODY$
-- DECLARE
-- 	the4326geomcol text := quote_ident(TG_ARGV[0]);
-- 	thelocalgeomcol text := quote_ident(TG_ARGV[1]);
-- 	thepkcolname text := quote_ident(TG_ARGV[2]);
--   thelocalsrid int;
--   thegeomlocalvalue public.geometry;
--   thegeom4326value public.geometry;
--   thegeom4326change boolean;
--   thegeomlocalchange boolean;
--   -- fonction trigger qui permet de garder l'intégriter entre les deux champs geom4326 et geomlocal
--   -- en executant des st_transform
--   -- à executer AFTER INSERT
-- BEGIN
-- SELECT INTO thelocalsrid parameter_value::int FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid';
-- IF (TG_OP = 'INSERT') THEN
-- -- si geom_4326 n'est pas null on remplit geom_local
--     --INSERT INTO pr_occtax.debug (d) VALUES (hstore(new)->'geom_4326'::text);
--   IF(hstore(NEW) -> the4326geomcol IS NOT NULL) THEN
--     INSERT INTO pr_occtax.debug(d) VALUES (TG_TABLE_NAME);

--   -- si geom4326 est null et que geomlocal ne l'est pas on remplit geom_4326 
--   ELSIF(hstore(NEW)->thelocalgeomcol IS NOT NULL) THEN
--   INSERT INTO pr_occtax.debug (d) VALUES ( FORMAT ('UPDATE %s.%s SET %s = (SELECT ST_TRANSFORM(%7$s.%s, %s)) WHERE %6$s=$1.%6$s', TG_TABLE_NAME, TG_TABLE_SCHEMA, the4326geomcol, thelocalgeomcol, thelocalsrid, thepkcolname, NEW ));
--     EXECUTE FORMAT ('UPDATE %s.%s SET %s = (SELECT ST_TRANSFORM($1.%s, %s)) WHERE %6$s=$1.%6$s', TG_TABLE_NAME, TG_TABLE_SCHEMA, the4326geomcol, thelocalgeomcol, thelocalsrid, thepkcolname ) INTO thegeomlocalvalue USING NEW;

--   END IF;
-- ELSIF (TG_OP = 'UPDATE') THEN 
--  -- on vérifie si la geom 4326 a changé
--   EXECUTE FORMAT('SELECT ST_EQUALS($1.%I, $2.%I)', the4326geomcol) INTO thegeom4326change USING NEW, OLD;
--     -- si il a changé on met à jour la geom_local
--     IF (thegeom4326change) THEN
--     EXECUTE FORMAT ('UPDATE $1.$2 SET $3 = (SELECT ST_TRANSFORM($4.%s, %s)) WHERE $5=$4.$5', the4326geomcol, thelocalsrid ) INTO thegeomlocalvalue USING TG_TABLE_NAME, TG_TABLE_SCHEMA, thelocalgeomcol, NEW, thepkcolname;

--     ELSE
--         EXECUTE FORMAT('SELECT ST_EQUALS($1.%I, $2.%I)', thelocalgeomcol) INTO thegeomlocalchange USING NEW, OLD;
--         IF (thegeomlocalchange) THEN
--     EXECUTE FORMAT ('UPDATE $1.$2 SET $3 = (SELECT ST_TRANSFORM($4.%s, %s)) WHERE $5=$4.$5', the4326geomcol, thelocalsrid ) INTO thegeomlocalvalue USING TG_TABLE_NAME, TG_TABLE_SCHEMA, thelocalgeomcol, NEW, thepkcolname;

--         END IF;
--     END IF;
-- END IF;

-- RETURN NULL;
-- END;
-- $BODY$
--   LANGUAGE plpgsql VOLATILE
--   COST 100;

--------
--DATA--
--------

INSERT INTO bib_areas_types (type_name, type_code, type_desc, ref_name, ref_version) VALUES
('Coeurs des Parcs nationaux', 'ZC', NULL, NULL,NULL),
('ZNIEFF2', 'ZNIEFF2', NULL, NULL,NULL),
('ZNIEFF1', 'ZNIEFF1', NULL, NULL,NULL),
('Aires de protection de biotope', 'APB', NULL, NULL,NULL),
('Réserves naturelles nationales', 'RNN', NULL, NULL,NULL),
('Réserves naturelles regionales', 'RNR', NULL, NULL,NULL),
('Natura 2000 - Zones de protection spéciales', 'ZPS', NULL, NULL,NULL),
('Natura 2000 - Sites d''importance communautaire', 'SIC', NULL, NULL,NULL),
('Zone d''importance pour la conservation des oiseaux', 'ZICO', NULL, NULL,NULL),
('Réserves nationales de chasse et faune sauvage', 'RNCFS', NULL, NULL,NULL),
('Réserves intégrales de parc national', 'RIPN', NULL, NULL,NULL),
('Sites acquis des Conservatoires d''espaces naturels', 'SCEN', NULL, NULL,NULL),
('Sites du Conservatoire du Littoral', 'SCL', NULL, NULL,NULL),
('Parcs naturels marins', 'PNM', NULL, NULL,NULL),
('Parcs naturels régionaux', 'PNR', NULL, NULL,NULL),
('Réserves biologiques', 'RBIOL', NULL, NULL,NULL),
('Réserves de biosphère', 'RBIOS', NULL, NULL,NULL),
('Réserves naturelles de Corse', 'RNC', NULL, NULL,NULL),
('Sites Ramsar', 'SRAM', NULL, NULL,NULL),
('Aire d''adhésion des Parcs nationaux', 'AA', NULL, NULL,NULL),
('Natura 2000 - Zones spéciales de conservation', 'ZSC', NULL, NULL,NULL),
('Natura 2000 - Proposition de sites d''intéret communautaire', 'PSIC', NULL, NULL,NULL),
('Périmètre d''étude de la charte des Parcs nationaux', 'PEC', NULL, NULL,NULL),
('Unités géographiques', 'UG', 'Unités géographiques permettant une orientation des prospections', NULL, NULL),
('Communes', 'COM', 'Type commune', 'IGN admin_express',2017),
('Départements', 'DEP', 'Type département', 'IGN admin_express',2017),
('Mailles10*10', 'M10', 'Type maille INPN 10*10km', NULL,NULL),
('Mailles1*1', 'M1', 'Type maille INPN 1*1km', NULL,NULL),
('Secteurs', 'SEC', NULL, NULL,NULL),
('Massifs', 'MAS', NULL, NULL,NULL),
('Zones biogéographiques', 'ZBIOG', NULL, NULL,NULL);
