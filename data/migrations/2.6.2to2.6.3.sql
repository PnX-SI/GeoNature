-- Update script from GeoNature 2.6.2 to 2.6.3

BEGIN;
   ----------------------------------------------
   -- REF_GEO - ADD MISSING UNIQUE CONSTRAINTS --
   ----------------------------------------------

   CREATE UNIQUE INDEX IF NOT EXISTS i_unique_l_areas_id_type_area_code ON ref_geo.l_areas (id_type, area_code);
   ALTER TABLE ONLY ref_geo.l_areas DROP CONSTRAINT IF EXISTS unique_l_areas_id_type_area_code;
   ALTER TABLE ONLY ref_geo.l_areas
        ADD CONSTRAINT  unique_l_areas_id_type_area_code UNIQUE (id_type, area_code);
   CREATE UNIQUE INDEX IF NOT EXISTS  i_unique_bib_areas_types_type_code ON ref_geo.bib_areas_types(type_code);
   ALTER TABLE ONLY ref_geo.bib_areas_types DROP CONSTRAINT IF EXISTS unique_bib_areas_types_type_code;
   ALTER TABLE ONLY ref_geo.bib_areas_types
        ADD CONSTRAINT unique_bib_areas_types_type_code UNIQUE (type_code);
    

   -- !!! TODO !!! A ne faire que si le paramètre n'existe pas déjà dans la table...
   -- Oubli de la 2.6.0 - A faire seulement sur une nouvelle installation faite avec la 2.6.0, 2.6.1 ou 2.6.2
   -- où il manquait ce paramètre fait en update2.5.5to2.6.0
   INSERT INTO gn_commons.t_parameters
   (id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value)
   VALUES(0, 'ref_sensi_version', 'Version du referentiel de sensibilité', 'Referentiel de sensibilite taxref v13 2020', '');


COMMIT;




