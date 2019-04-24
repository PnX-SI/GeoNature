-- libération des id pour les unités géo
UPDATE ref_geo.l_areas
SET id_area = id_area + 1000;

-- reinsertion des utités géo dans les id libérés
INSERT INTO ref_geo.l_areas(
            id_area, id_type, area_name, area_code, geom, centroid)
SELECT 
id_unite_geo,(SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'UG') AS id_type, concat('unite_geoo', id_unite_geo::text), id_unite_geo, the_geom, ST_Centroid(the_geom)
FROM v1_compat.l_unites_geo;

-- maj de la sequence
SELECT pg_catalog.setval('ref_geo.l_areas_id_area_seq', (SELECT max(id_area) FROM ref_geo.l_areas), true);
