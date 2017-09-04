DROP TABLE ref_geo.dem_vector IF EXISTS;
CREATE TABLE ref_geo.dem_vector AS
SELECT (ST_DumpAsPolygons(rast)).*
FROM ref_geo.dem;


-- DROP FUNCTION ref_geo.fct_get_altitude_intersection(geometry);

CREATE OR REPLACE FUNCTION ref_geo.fct_get_altitude_intersection(IN mygeom geometry)
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
    FROM ref_geo.dem_vector,d
    WHERE st_intersects(a,geom);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;



-- DROP FUNCTION ref_geo.fct_get_municipality_intersection(geometry);

CREATE OR REPLACE FUNCTION ref_geo.fct_get_municipality_intersection(IN mygeom geometry)
  RETURNS TABLE(insee_code character varying, municipality_name character varying) AS
$BODY$
DECLARE
    isrid int;
BEGIN
    SELECT gn_meta.get_default_parameter('local_srid', NULL) INTO isrid;
    RETURN QUERY
    WITH d  as (
        SELECT st_transform(myGeom,isrid) geom_trans
    )
    SELECT c.insee_code , municipality_name FROM ref_geo.l_municipalities c , d WHERE st_intersects(geom_trans, geom);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
