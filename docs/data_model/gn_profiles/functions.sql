CREATE OR REPLACE FUNCTION gn_profiles.check_profile_altitudes(in_alt_min integer, in_alt_max integer, profil_altitude_min integer, profil_altitude_max integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
   BEGIN
    RETURN in_alt_min >= profil_altitude_min AND
      in_alt_max <= profil_altitude_max;
  END;
$function$

CREATE OR REPLACE FUNCTION gn_profiles.check_profile_distribution(in_geom geometry, profil_geom geometry)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de vérifier la cohérence d'une donnée d'occurrence en s'assurant que sa
--localisation est totalement incluse dans l'aire d'occurrences valide définie par le profil du
--taxon en question
  BEGIN
     RETURN ST_Contains(profil_geom, in_geom);
  END;
$function$

CREATE OR REPLACE FUNCTION gn_profiles.check_profile_phenology(in_cd_ref integer, in_date_min date, in_date_max date, in_altitude_min integer, in_altitude_max integer, in_id_nomenclature_life_stage integer, check_life_stage boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
  BEGIN


  IF check_life_stage THEN
    -- Suppression des valeurs inconnue et non renseignée
    IF
        in_id_nomenclature_life_stage = ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0')
        OR
        in_id_nomenclature_life_stage = ref_nomenclatures.get_id_nomenclature('STADE_VIE', '1')
    THEN
        in_id_nomenclature_life_stage := NULL;
    END IF;

    RETURN EXISTS (
        SELECT *
        FROM gn_profiles.vm_cor_taxon_phenology c
        WHERE in_cd_ref = c.cd_ref
            AND date_part('doy', in_date_min) >= c.doy_min
            AND date_part('doy', in_date_max) <= c.doy_max
            AND in_altitude_min >= calculated_altitude_min
            AND in_altitude_max <= calculated_altitude_max
            AND in_id_nomenclature_life_stage = c.id_nomenclature_life_stage
    );
  ELSE
      RETURN EXISTS (
        SELECT *
        FROM gn_profiles.vm_cor_taxon_phenology c
        WHERE in_cd_ref = c.cd_ref
            AND date_part('doy', in_date_min) >= c.doy_min
            AND date_part('doy', in_date_max) <= c.doy_max
            AND in_altitude_min >= calculated_altitude_min
            AND in_altitude_max <= calculated_altitude_max
    );
   END IF;
  END;
$function$

CREATE OR REPLACE FUNCTION gn_profiles.fct_auto_validation(new_validation_status integer DEFAULT 2, score integer DEFAULT 3)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
declare old_validation_status int := 0;

validation_id_type int := ref_nomenclatures.get_id_nomenclature_type('STATUT_VALID');

-- Retrieve the new validation status's nomenclature id
new_id_status_validation int := (
    select tn.id_nomenclature
    from ref_nomenclatures.t_nomenclatures tn
    where tn.cd_nomenclature = new_validation_status::varchar
    and id_type = validation_id_type
);

-- Retrieve the old validation status nomenclature id
old_id_status_validation int := (
    select tn.id_nomenclature
    from ref_nomenclatures.t_nomenclatures tn
    where tn.cd_nomenclature = old_validation_status::varchar
    and id_type = validation_id_type
);

-- Retrieve the list of observations tagged with the old validation status
list_uuid_obs_status_updatable uuid [] := (
    select array_agg(vlv.uuid_attached_row)
    from gn_commons.v_latest_validation vlv
    join gn_profiles.v_consistancy_data vcd on vlv.uuid_attached_row = vcd.id_sinp
    and (
        (
            vcd.valid_phenology::int + vcd.valid_altitude::int + vcd.valid_distribution::int
        ) = score
    )
    where vlv.id_nomenclature_valid_status = old_id_status_validation
        and id_validator is null
);
  
number_of_obs_to_update int := array_length(list_uuid_obs_status_updatable, 1);
begin if  number_of_obs_to_update > 0 then 
	raise notice '% observations seront validées automatiquement',number_of_obs_to_update;
-- Update Validation status 
	insert into gn_commons.t_validations (uuid_attached_row, id_nomenclature_valid_status, validation_auto, id_validator, validation_comment, validation_date) 
		select t_uuid.uuid_attached_row, new_id_status_validation ,true, null,'auto = default value',CURRENT_TIMESTAMP
		from 
		(select distinct on (uuid_attached_row) uuid_attached_row
	            from gn_commons.t_validations tv
	            where uuid_attached_row = any (list_uuid_obs_status_updatable)
	     )  t_uuid;
else
raise notice 'Aucune entrée dans les dernières observations n''est candidate à la validation automatique';
end if;
return 0;
end;
$function$

CREATE OR REPLACE FUNCTION gn_profiles.get_parameters(my_cd_nom integer)
 RETURNS TABLE(cd_ref integer, spatial_precision integer, temporal_precision_days integer, active_life_stage boolean, distance smallint)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    -- fonction permettant de récupérer les paramètres les plus adaptés
    -- (définis au plus proche du taxon) pour calculer le profil d'un taxon donné
    -- par exemple, s'il existe des paramètres pour les "Animalia" des paramètres pour le renard,
    -- les paramètres du renard surcoucheront les paramètres Animalia pour cette espèce
      DECLARE
      BEGIN
       RETURN QUERY
       SELECT
            t.cd_ref,
            parameters.*
        FROM (
            SELECT
                param.spatial_precision,
                param.temporal_precision_days,
                param.active_life_stage,
                parents.distance
            FROM
                gn_profiles.cor_taxons_parameters param
            JOIN
                taxonomie.find_all_taxons_parents(my_cd_nom) parents ON parents.cd_nom=param.cd_nom
        UNION
            SELECT
                (SELECT value::int4 FROM gn_profiles.t_parameters WHERE name = 'default_spatial_precision') AS spatial_precision,
                (SELECT value::int4 FROM gn_profiles.t_parameters WHERE name = 'default_temporal_precision_days') AS temporal_precision_days,
                (SELECT value::boolean FROM gn_profiles.t_parameters WHERE name = 'default_active_life_stage') AS active_life_stage,
                NULL AS distance
        ) AS parameters
        JOIN
            taxonomie.taxref t ON t.cd_nom = my_cd_nom
        ORDER BY
            distance
        LIMIT 1
       ;
      END;
    $function$

CREATE OR REPLACE FUNCTION gn_profiles.refresh_profiles()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
-- Rafraichissement des vues matérialisées des profils
-- USAGE : SELECT gn_profiles.refresh_profiles()
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_profiles.vm_valid_profiles;
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_profiles.vm_cor_taxon_phenology;
END
$function$

