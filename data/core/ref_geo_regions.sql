SET search_path = ref_geo, pg_catalog, public;

INSERT INTO l_areas (id_type, area_code, area_name, geom, geojson_4326)
SELECT get_id_area_type('REG') AS id_type, insee_reg, nom_reg, geom, geojson 
FROM temp_fr_regions
;

REINDEX INDEX index_l_areas_geom;
