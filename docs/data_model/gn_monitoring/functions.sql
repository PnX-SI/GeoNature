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

CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_t_individuals_t_observations_cd_nom()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN

        -- Mise à jour du cd_nom de la table observation
        IF
            NEW.id_individual = OLD.id_individual
        THEN
            UPDATE gn_monitoring.t_observations SET cd_nom = NEW.cd_nom WHERE id_individual = NEW.id_individual;
        END IF;

    RETURN NEW;
    END;
    $function$

CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_t_observations_cd_nom()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN

        -- Récupération du cd_nom depuis la table des individus
        IF
            NOT NEW.id_individual IS NULL
        THEN
        NEW.cd_nom := (SELECT cd_nom FROM gn_monitoring.t_individuals ti WHERE id_individual = NEW.id_individual);
        END IF;

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

