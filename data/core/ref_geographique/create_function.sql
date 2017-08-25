DROP TABLE ref_geographique.mnt_vector IF EXISTS;
CREATE TABLE ref_geographique.mnt_vector AS
SELECT (ST_DumpAsPolygons(rast)).*
FROM ref_geographique.mnt;


-- DROP FUNCTION ref_geographique.fct_get_altitude_intersection(geometry);

CREATE OR REPLACE FUNCTION ref_geographique.fct_get_altitude_intersection(IN mygeom geometry)
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
    FROM ref_geographique.mnt_vector,d
    WHERE st_intersects(a,geom);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;



-- DROP FUNCTION ref_geographique.fct_get_municipality_intersection(geometry);

CREATE OR REPLACE FUNCTION ref_geographique.fct_get_municipality_intersection(IN mygeom geometry)
  RETURNS TABLE(code_insee character varying, name_municipality character varying) AS
$BODY$
DECLARE
    isrid int;
BEGIN
    SELECT gn_meta.get_default_parameter('local_srid', NULL) INTO isrid;
    RETURN QUERY
    WITH d  as (
        SELECT st_transform(myGeom,isrid) geom_trans
    )
    SELECT c.code_insee , nom FROM ref_geographique.l_communes c , d WHERE st_intersects(geom_trans, geom);

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;
