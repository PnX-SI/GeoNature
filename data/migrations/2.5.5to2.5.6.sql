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

-- synthese 

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_biogeo_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_biogeo_status,'STAT_BIOGEO')) NOT VALID;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_biogeo_status FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


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

 CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$ 
  -- Calculate sensitivity and diffusion level on update in synthese
  DECLARE calculated_id_sensi integer;
    BEGIN
        SELECT 
        gn_sensitivity.get_id_nomenclature_sensitivity(
          NEW.date_min::date, 
          taxonomie.find_cdref(NEW.cd_nom), 
          NEW.the_geom_local,
          ('{"STATUT_BIO": ' || NEW.id_nomenclature_bio_status::text || '}')::jsonb
        ) INTO calculated_id_sensi;
      UPDATE gn_synthese.synthese 
      SET 
      id_nomenclature_sensitivity = calculated_id_sensi,
      -- TODO: est-ce qu'on remet à jour le niveau de diffusion lors d'une MAJ de la sensi ?
      id_nomenclature_diffusion_level = (
        SELECT ref_nomenclatures.get_id_nomenclature(
            'NIV_PRECIS',
            gn_sensitivity.calculate_cd_diffusion_level(
              ref_nomenclatures.get_cd_nomenclature(OLD.id_nomenclature_diffusion_level),
              ref_nomenclatures.get_cd_nomenclature(calculated_id_sensi)
          )
      	)
      )
      WHERE id_synthese = OLD.id_synthese
      ;
      RETURN NULL;
    END;
  $$;
  
CREATE TRIGGER tri_insert_calculate_sensitivity
 AFTER INSERT ON gn_synthese.synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement();
  
CREATE TRIGGER tri_update_calculate_sensitivity
 AFTER UPDATE OF date_min, date_max, cd_nom, the_geom_local, id_nomenclature_bio_status ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row();
  
 
 -- refactor cor_area triggers
 CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement()
  RETURNS trigger AS
$BODY$
  DECLARE
  BEGIN
  -- Intersection avec toutes les areas et écriture dans cor_area_synthese
      INSERT INTO gn_synthese.cor_area_synthese 
        SELECT
          updated_rows.id_synthese AS id_synthese,
          a.id_area AS id_area
        FROM NEW as updated_rows
        JOIN ref_geo.l_areas a
          ON public.ST_INTERSECTS(updated_rows.the_geom_local, a.geom)  
        WHERE a.enable IS TRUE AND (ST_GeometryType(updated_rows.the_geom_local) = 'ST_Point' OR NOT public.ST_TOUCHES(updated_rows.the_geom_local,a.geom));
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_update_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  geom_change boolean;
  BEGIN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;

  -- Intersection avec toutes les areas et écriture dans cor_area_synthese
    INSERT INTO gn_synthese.cor_area_synthese SELECT
      s.id_synthese AS id_synthese,
      a.id_area AS id_area
      FROM ref_geo.l_areas a
      JOIN gn_synthese.synthese s
        ON public.ST_INTERSECTS(s.the_geom_local, a.geom)
      WHERE a.enable IS TRUE AND s.id_synthese = NEW.id_synthese AND (ST_GeometryType(updated_rows.the_geom_local) = 'ST_Point' OR NOT public.ST_TOUCHES(updated_rows.the_geom_local,a.geom));
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER tri_insert_cor_area_synthese ON gn_synthese.synthese;
CREATE TRIGGER tri_insert_cor_area_synthese
AFTER insert ON gn_synthese.synthese
REFERENCING NEW TABLE AS NEW
FOR EACH STATEMENT
EXECUTE PROCEDURE gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement();


CREATE TRIGGER tri_update_cor_area_synthese
AFTER UPDATE OF the_geom_local, the_geom_4326 ON gn_synthese.synthese
FOR EACH ROW
EXECUTE PROCEDURE gn_synthese.fct_trig_update_in_cor_area_synthese();


 
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
