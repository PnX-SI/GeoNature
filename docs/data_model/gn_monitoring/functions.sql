CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_cor_site_area()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN

	DELETE FROM gn_monitoring.cor_site_area WHERE id_base_site = NEW.id_base_site;
	INSERT INTO gn_monitoring.cor_site_area
	SELECT NEW.id_base_site, (ref_geo.fct_get_area_intersection(NEW.geom)).id_area;

  RETURN NEW;
END;
$function$

CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_visite_date_max()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
	-- Si la date max de la visite est nulle ou inférieure à la date_min
	--	Modification de date max pour garder une cohérence des données
	IF
		NEW.visit_date_max IS NULL
		OR NEW.visit_date_max < NEW.visit_date_min
	THEN
      NEW.visit_date_max := NEW.visit_date_min;
    END IF;
  RETURN NEW;
END;
$function$

