IMPORT FOREIGN SCHEMA layers FROM SERVER geonature1server INTO v1_compat;

ALTER TABLE ref_geo.l_areas DISABLE TRIGGER tri_meta_dates_change_l_areas;

-- aire d'adhesion
INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'AA') AS id_type, 
  'Aire adhesion PNE', 
  'AA_PNE',  
  ST_Multi(ST_MakePolygon(the_geom)), 
  ST_Centroid(ST_MakePolygon(the_geom)),
  now(),
  now()
FROM v1_compat.l_aireadhesion;

-- secteurs
INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'SEC') AS id_type, 
  nom_secteur, 
  id_secteur, 
  the_geom, 
  ST_Centroid(the_geom),
  now(),
  now()
FROM v1_compat.l_secteurs;


-- autre aires dont le type est déja dans GN1 et dont l'id_type correspond
INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  id_type, 
  nomzone, 
  id_zone, 
  ST_Multi(the_geom), 
  ST_Centroid(the_geom),
  now(),
  now()
FROM v1_compat.l_zonesstatut
WHERE id_type <= 20;
;

-- création des types d'aires non présents par défaut dans GN2
DELETE FROM ref_geo.bib_areas_types WHERE type_code IN('SITE_CLASSES', 'SITE_INSC', 'PPN', 'PAF');
INSERT INTO ref_geo.bib_areas_types(type_name, type_code, type_desc) VALUES 
('Site classés', 'SITE_CLASSES', 'Sites classés')
,('Site inscrits', 'SITE_INSC', 'Sites inscrits')
,('Perimetres de protection de RN', 'PPN', 'Perimetres de protection de réserves naturelles')
,('Plans d''aménagement forestier', 'PAF', 'Plans d''aménagement forestier')
;
INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'SITE_CLASSES') AS id_type, 
  nomzone, 
  concat('SITE_CLASSES_', id_zone::varchar) AS id_zone,  
  ST_Multi(the_geom), 
  ST_Centroid(the_geom),
  now(),
  now()
FROM v1_compat.l_zonesstatut
WHERE id_type = 21;
;

INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'SITE_INSC') AS id_type, 
  nomzone, 
  concat('SITE_INSC_', id_zone::varchar) AS id_zone,  
  ST_Multi(the_geom), 
  ST_Centroid(the_geom),
  now(),
  now()
FROM v1_compat.l_zonesstatut
WHERE id_type = 22;
;

INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'PPN') AS id_type, 
  nomzone, 
  concat('PPN_', id_zone::varchar) AS id_zone,   
  ST_Multi(the_geom), 
  ST_Centroid(the_geom),
  now(),
  now()
FROM v1_compat.l_zonesstatut
WHERE id_type = 23;
;

INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, meta_create_date, meta_update_date)
SELECT 
  (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'PAF') AS id_type, 
  nomzone, 
  concat('PAF_', id_zone::varchar) AS id_zone,   
  ST_Multi(the_geom), 
  ST_Centroid(the_geom),
  now(),
  now()
FROM v1_compat.l_zonesstatut
WHERE id_type = 24;
;

ALTER TABLE ref_geo.l_areas ENABLE TRIGGER tri_meta_dates_change_l_areas;

-- TODO Voir l'impact de l'absence de lien entre commune et secteur

-- recalcul des couleurs après intégration des nouvelles aires
