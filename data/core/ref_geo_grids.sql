SET search_path = ref_geo, pg_catalog, public;

INSERT INTO ref_geo.l_areas (id_type, area_code, area_name, geom)
SELECT ref_geo.get_id_area_type('M10') AS id_type, cd_sig, code_10km,  geom 
FROM ref_geo.temp_grids_10;

INSERT INTO ref_geo.li_grids(id_grid, id_area, cxmin, cxmax, cymin, cymax)
SELECT area_code, id_area, ST_XMin(g.geom), ST_XMax(g.geom), ST_YMin(g.geom), ST_YMax(g.geom)
FROM ref_geo.temp_grids_10 g
JOIN ref_geo.l_areas l ON l.area_code = cd_sig;


INSERT INTO ref_geo.l_areas (id_type, area_code, area_name, geom)
SELECT ref_geo.get_id_area_type('M1') AS id_type, cd_sig, code_10km,  geom 
FROM ref_geo.temp_grids_1;

INSERT INTO ref_geo.li_grids(id_grid, id_area, cxmin, cxmax, cymin, cymax)
SELECT area_code, id_area, ST_XMin(g.geom), ST_XMax(g.geom), ST_YMin(g.geom), ST_YMax(g.geom)
FROM ref_geo.temp_grids_1 g
JOIN ref_geo.l_areas l ON l.area_code = cd_sig;


INSERT INTO ref_geo.l_areas (id_type, area_code, area_name, geom)
SELECT ref_geo.get_id_area_type('M5') AS id_type, cd_sig, code5km,  geom 
FROM ref_geo.temp_grids_5;

INSERT INTO ref_geo.li_grids(id_grid, id_area, cxmin, cxmax, cymin, cymax)
SELECT area_code, id_area, ST_XMin(g.geom), ST_XMax(g.geom), ST_YMin(g.geom), ST_YMax(g.geom)
FROM ref_geo.temp_grids_5 g
JOIN ref_geo.l_areas l ON l.area_code = cd_sig;

REINDEX INDEX index_l_areas_geom;


DROP TABLE ref_geo.temp_grids_1;
DROP TABLE ref_geo.temp_grids_5;
DROP TABLE ref_geo.temp_grids_10;