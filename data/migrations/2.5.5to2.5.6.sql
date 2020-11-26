ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_biogeo_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_biogeo_status,'STAT_BIOGEO')) NOT VALID;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_biogeo_status FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE gn_synthese.synthese ALTER COLUMN reference_biblio TYPE TEXT; 

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
 
CREATE OR REPLACE FUNCTION gn_synthese.import_row_from_table(
        select_col_name character varying,
        select_col_val character varying,
        tbl_name character varying,
        limit_ integer,
        offset_ integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
    DECLARE
      select_sql text;
      import_rec record;
    BEGIN

      --test que la table/vue existe bien
      --42P01         undefined_table
      IF EXISTS (
          SELECT 1 FROM information_schema.tables t  WHERE t.table_schema ||'.'|| t.table_name = LOWER(tbl_name)
      ) IS FALSE THEN
          RAISE 'Undefined table: %', tbl_name USING ERRCODE = '42P01';
      END IF ;

      --test que la colonne existe bien
      --42703         undefined_column
      IF EXISTS (
          SELECT * FROM information_schema.columns  t  WHERE  t.table_schema ||'.'|| t.table_name = LOWER(tbl_name) AND column_name = select_col_name
      ) IS FALSE THEN
          RAISE 'Undefined column: %', select_col_name USING ERRCODE = '42703';
      END IF ;

        -- TODO transtypage en text pour des questions de généricité. A réflechir
        select_sql := 'SELECT row_to_json(c)::jsonb d
            FROM ' || LOWER(tbl_name) || ' c
            WHERE ' ||  select_col_name|| '::text = ''' || select_col_val || '''
            LIMIT ' || limit_ || '
            OFFSET ' || offset_ ;

        FOR import_rec IN EXECUTE select_sql LOOP
            PERFORM gn_synthese.import_json_row(import_rec.d);
        END LOOP;

      RETURN TRUE;
      END;
    $BODY$;
