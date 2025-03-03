CREATE OR REPLACE FUNCTION gn_sensitivity.calculate_cd_diffusion_level(cd_nomenclature_diffusion_level character varying, cd_nomenclature_sensitivity character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF cd_nomenclature_diffusion_level IS NULL 
    THEN RETURN
    CASE 
      WHEN cd_nomenclature_sensitivity = '0' THEN '5'
      WHEN cd_nomenclature_sensitivity = '1' THEN '1'
      WHEN cd_nomenclature_sensitivity = '2' THEN '2'
      WHEN cd_nomenclature_sensitivity = '3' THEN '3'
      WHEN cd_nomenclature_sensitivity = '4' THEN '4'
    END;
  ELSE 
    RETURN cd_nomenclature_diffusion_level;
  END IF;
END;
$function$

CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_delete_id_sensitivity_synthese()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE gn_synthese.synthese AS s
    SET id_nomenclature_sensitivity = gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying)
    FROM OLD AS deleted_rows
    WHERE s.unique_id_sinp = deleted_rows.uuid_attached_row;
    RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_maj_id_sensitivity_synthese()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE gn_synthese.synthese AS s
    SET id_nomenclature_sensitivity = updated_rows.id_nomenclature_sensitivity
    FROM NEW AS updated_rows
    WHERE s.unique_id_sinp = updated_rows.uuid_attached_row;
    RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(my_date_obs date, my_cd_ref integer, my_geom geometry, my_criterias jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
        DECLARE
            sensitivity integer;
        BEGIN
            -- Paramètres durée, zone géographique, période de l'observation et critères biologique
            SELECT INTO sensitivity r.id_nomenclature_sensitivity
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref r
            JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = r.id_nomenclature_sensitivity
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_area USING(id_sensitivity)
            LEFT OUTER JOIN ref_geo.l_areas a USING(id_area)
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
            WHERE
                ( -- taxon
                    my_cd_ref = r.cd_ref
                ) AND ( -- zone géographique de validité
                    a.geom IS NULL -- pas de restriction géographique à la validité de la règle
                    OR
                    st_intersects(my_geom, a.geom)
                ) AND ( -- période de validité
                    to_char(my_date_obs, 'MMDD') between to_char(r.date_min, 'MMDD') and to_char(r.date_max, 'MMDD')
                ) AND ( -- durée de validité
                    (date_part('year', CURRENT_TIMESTAMP) - r.sensitivity_duration) <= date_part('year', my_date_obs)
                ) AND ( -- critère
                    c.id_criteria IS NULL -- règle sans restriction de critère
                    OR
                    -- Note: no need to check criteria type, as we use id_nomenclature which can not conflict
                    c.id_criteria IN (SELECT value::int FROM jsonb_each_text(my_criterias))
                )
            ORDER BY n.cd_nomenclature DESC;

            IF sensitivity IS NULL THEN
                sensitivity := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));
            END IF;

            return sensitivity;
        END;
        $function$

