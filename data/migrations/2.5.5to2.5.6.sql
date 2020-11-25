CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_calculate_sensitivity() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$ 
    BEGIN
    INSERT INTO gn_sensitivity.cor_sensitivity_synthese(uuid_attached_row, id_nomenclature_sensitivity, meta_create_date)
    SELECT 
      NEW.uuid_perm_sinp, 
      gn_sensitivity.get_id_nomenclature_sensitivity(
        updated_table.date_min, 
        taxonomie.find_cdref(updated_table.cd_nom), 
        updated_table.geom_local,
         ('{"STATUT_BIO": ' || updated_table.id_nomenclature_bio_status::text || '}')::jsonb
      ),
      NOW()
      FROM NEW as updated_table
      ;
    RETURN NULL;
    END;
  $$;
  
 CREATE TRIGGER tri_insert_calculate_sensitivity
 AFTER INSERT ON gn_synthese.synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_synthese.fct_tri_calculate_sensitivity();
  
  CREATE TRIGGER tri_update_calculate_sensitivity
 AFTER UPDATE ON gn_synthese.synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_synthese.fct_tri_calculate_sensitivity();
  
 
 
 
 -- sensitivity schema
 
 CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_maj_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese 
    SET id_nomenclature_sensitivity = updated_rows.id_nomenclature_sensitivity
    FROM NEW AS updated_rows
    JOIN gn_synthese.synthese s ON s.unique_id_sinp = updated_rows.uuid_attached_row;
    RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Trigger function executed by a ON EACH STATEMENT triger
CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_delete_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese 
    SET id_nomenclature_sensitivity = gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying)
    FROM OLD AS deleted_rows
    JOIN gn_synthese.synthese s ON s.unique_id_sinp = deleted_rows.uuid_attached_row;
    RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
 

 CREATE TRIGGER tri_insert_id_sensitivity_synthese
  AFTER INSERT ON gn_sensitivity.cor_sensitivity_synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_sensitivity.fct_tri_maj_id_sensitivity_synthese();

DROP TRIGGER tri_maj_id_sensitivity_synthese ON gn_sensitivity.cor_sensitivity_synthese;
CREATE TRIGGER tri_maj_id_sensitivity_synthese
  AFTER UPDATE ON gn_sensitivity.cor_sensitivity_synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_sensitivity.fct_tri_maj_id_sensitivity_synthese();
 