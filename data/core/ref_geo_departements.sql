SET search_path = ref_geo, pg_catalog, public;

INSERT INTO ref_geo.l_areas (id_type, area_code, area_name, geom, geojson_4326)
SELECT get_id_area_type('DEP') AS id_type, insee_dep, nom_dep, geom, geojson
FROM temp_fr_departements;
