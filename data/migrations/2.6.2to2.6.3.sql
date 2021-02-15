-- Update script from GeoNature 2.6.2 to 2.6.3

BEGIN;
   ------------------------------------
   -- ADD MISSING UNIQUE CONSTRAINTS --
   ------------------------------------

   CREATE UNIQUE INDEX IF NOT EXISTS i_unique_l_areas_id_type_area_code ON ref_geo.l_areas (id_type, area_code);
   ALTER TABLE ONLY ref_geo.l_areas DROP CONSTRAINT IF EXISTS unique_l_areas_id_type_area_code;
   ALTER TABLE ONLY ref_geo.l_areas
        ADD CONSTRAINT  unique_l_areas_id_type_area_code UNIQUE (id_type, area_code);
   CREATE UNIQUE INDEX IF NOT EXISTS  i_unique_bib_areas_types_type_code ON ref_geo.bib_areas_types(type_code);
   ALTER TABLE ONLY ref_geo.bib_areas_types DROP CONSTRAINT IF EXISTS unique_bib_areas_types_type_code;
   ALTER TABLE ONLY ref_geo.bib_areas_types
        ADD CONSTRAINT unique_bib_areas_types_type_code UNIQUE (type_code);
    

COMMIT;




