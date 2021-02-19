-- Update script from GeoNature 2.6.0 to 2.6.1

----------------------------
-- SYNTHESE schema update
----------------------------
CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$ 
  -- Calculate sensitivity and diffusion level on insert in synthese
    BEGIN
    WITH cte AS (
        SELECT 
        gn_sensitivity.get_id_nomenclature_sensitivity(
          updated_rows.date_min::date, 
          taxonomie.find_cdref(updated_rows.cd_nom), 
          updated_rows.the_geom_local,
          ('{"STATUT_BIO": ' || updated_rows.id_nomenclature_bio_status::text || '}')::jsonb
        ) AS id_nomenclature_sensitivity,
        id_synthese,
        t_diff.cd_nomenclature as cd_nomenclature_diffusion_level
      FROM NEW AS updated_rows
      LEFT JOIN ref_nomenclatures.t_nomenclatures t_diff ON t_diff.id_nomenclature = updated_rows.id_nomenclature_diffusion_level
      WHERE updated_rows.id_nomenclature_sensitivity IS NULL
    )
    UPDATE gn_synthese.synthese AS s
    SET 
      id_nomenclature_sensitivity = c.id_nomenclature_sensitivity,
      id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature(
        'NIV_PRECIS',
        gn_sensitivity.calculate_cd_diffusion_level(
          c.cd_nomenclature_diffusion_level, 
          t_sensi.cd_nomenclature
        )
        
      )
    FROM cte AS c
    LEFT JOIN ref_nomenclatures.t_nomenclatures t_sensi ON t_sensi.id_nomenclature = c.id_nomenclature_sensitivity
    WHERE c.id_synthese = s.id_synthese
  ;
    RETURN NULL;
    END;
  $$;


DROP TRIGGER IF EXISTS tri_update_cor_area_synthese ON gn_synthese.synthese;
CREATE TRIGGER tri_update_cor_area_synthese
AFTER UPDATE OF the_geom_local, the_geom_4326 ON gn_synthese.synthese
FOR EACH ROW
EXECUTE PROCEDURE gn_synthese.fct_trig_update_in_cor_area_synthese();

COMMIT;