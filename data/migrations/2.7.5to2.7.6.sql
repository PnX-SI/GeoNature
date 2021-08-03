-- Add 'on delete cascade' on gn_synthese.cor_area_synthese.id_area FK
ALTER TABLE gn_synthese.cor_area_synthese
	drop CONSTRAINT fk_cor_area_synthese_id_area;
ALTER TABLE gn_synthese.cor_area_synthese
	ADD CONSTRAINT fk_cor_area_synthese_id_area
	FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
	on update cascade 
	on delete cascade;

-- Populate gn_synthese.cor_area_synthese on new areas inserted in ref_geo.l_areas
CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_l_areas_insert_cor_area_synthese_on_each_statement()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
  BEGIN
  -- Intersection de toutes les observations avec les nouvelles zones et écriture dans cor_area_synthese
      INSERT INTO gn_synthese.cor_area_synthese 
        SELECT
          new_areas.id_area AS id_area,
          s.id_synthese as id_synthese
        FROM NEW as new_areas
        join gn_synthese.synthese s 
          ON public.ST_INTERSECTS(s.the_geom_local, new_areas.geom)  
        WHERE new_areas.enable IS true
        	AND (
       				ST_GeometryType(s.the_geom_local) = 'ST_Point'
       			or
       				not public.ST_TOUCHES(s.the_geom_local, new_areas.geom)
       			);
  RETURN NULL;
  END;
  $function$
;

create trigger tri_insert_cor_area_synthese after
	insert on ref_geo.l_areas
	referencing new table as new
	for each statement
	execute procedure gn_synthese.fct_trig_l_areas_insert_cor_area_synthese_on_each_statement();
