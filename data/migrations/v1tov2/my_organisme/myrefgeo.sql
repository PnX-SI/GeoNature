-- TODO: pour supprimer les communes, il faut supprimer cor_synthese_area, et donc rejouer les triggers apres coup...

DELETE FROM gn_synthese.cor_area_synthese;
DELETE FROM ref_geo.l_areas WHERE id_type = 25;
DELETE FROM ref_geo.li_municipalities;

SELECT pg_catalog.setval('ref_geo.l_areas_id_area_seq', 1, true);

-- reinsertion des utités géo
INSERT INTO ref_geo.l_areas(
            id_type, area_name, area_code, geom, centroid)
SELECT 
(SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'UG') AS id_type, id_unite_geo::text, id_unite_geo, the_geom, ST_Centroid(the_geom)
FROM v1_compat.l_unites_geo;

SELECT pg_catalog.setval('ref_geo.l_areas_id_area_seq', (SELECT max(id_area) FROM ref_geo.l_areas), true);

-- on insert les communes dans le sh