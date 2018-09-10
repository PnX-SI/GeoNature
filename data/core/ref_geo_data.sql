SET search_path = ref_geo, pg_catalog;

INSERT INTO l_areas (id_type, area_code, area_name, geom)
SELECT 101 AS id_type, insee_com, nom_com, geom FROM temp_fr_municipalities;

TRUNCATE TABLE li_municipalities;
INSERT INTO li_municipalities (id_municipality, id_area, status, insee_com, nom_com, insee_arr, nom_dep, insee_dep, nom_reg, insee_reg, code_epci)
SELECT id,  a.id_area, statut, insee_com, nom_com, insee_arr, nom_dep, insee_dep, nom_reg, insee_reg, code_epci
FROM temp_fr_municipalities t
JOIN l_areas a ON a.area_code = t.insee_com
;
REINDEX INDEX index_l_areas_geom;
