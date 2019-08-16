
ALTER TABLE ref_geo.l_areas DISABLE TRIGGER tri_meta_dates_change_l_areas;
ALTER TABLE ref_geo.li_municipalities DISABLE TRIGGER tri_meta_dates_change_li_municipalities;

-- libération des id pour les unités géo
UPDATE ref_geo.l_areas
SET id_area = id_area + 1000000
WHERE id_area < 155;

ALTER TABLE ref_geo.li_municipalities ENABLE TRIGGER tri_meta_dates_change_li_municipalities;

-- reinsertion des utités géo dans les id libérés
INSERT INTO ref_geo.l_areas(id_area, id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  id_unite_geo,
  (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'UG') AS id_type, 
  concat('unite_geo_', id_unite_geo::text), 
  id_unite_geo, 
  the_geom, 
  ST_Centroid(the_geom),
  now(),
  now()
FROM v1_compat.l_unites_geo;

-- maj de la sequence
SELECT pg_catalog.setval('ref_geo.l_areas_id_area_seq', (SELECT max(id_area) FROM ref_geo.l_areas), true);

ALTER TABLE ref_geo.l_areas ENABLE TRIGGER tri_meta_dates_change_l_areas;

--Perfs
VACUUM FULL ref_geo.l_areas;
VACUUM ANALYSE ref_geo.l_areas;
REINDEX TABLE ref_geo.l_areas;
