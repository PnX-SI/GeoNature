SET search_path = ref_geo, pg_catalog;

INSERT INTO l_areas (id_type, source_code, area_name, geom)
SELECT 1 AS id_type, insee_com, nom_com, geom FROM temp_fr_municipalities;

TRUNCATE TABLE l_municipalities;
INSERT INTO l_municipalities (id_municipality, id_area, status, fr_insee_com, fr_nom_com, fr_insee_arr, fr_nom_dep, fr_insee_dep, fr_nom_reg, fr_insee_reg, fr_code_epci)
SELECT id,  a.id_area, statut, insee_com, nom_com, insee_arr, nom_dep, insee_dep, nom_reg, insee_reg, code_epci
FROM temp_fr_municipalities t
JOIN l_areas a ON a.source_code = t.insee_com
;
REINDEX INDEX index_l_areas_geom;