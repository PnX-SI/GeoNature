    -- Import dans la synthese, ajout de limit et offset 
    -- pour pouvoir boucler et traiter des quantités raisonables de données
CREATE OR REPLACE FUNCTION gn_synthese.import_row_from_table(
    select_col_name character varying,
    select_col_val character varying,
    tbl_name character varying,
    limit_ integer,
    offset_ integer)
  RETURNS boolean AS
  $BODY$
  DECLARE
    select_sql text;
    import_rec record;
  BEGIN

    --test que la table/vue existe bien
    --42P01 	undefined_table
    IF EXISTS (
        SELECT 1 FROM information_schema.tables t  WHERE t.table_schema ||'.'|| t.table_name = tbl_name
    ) IS FALSE THEN
        RAISE 'Undefined table: %', tbl_name USING ERRCODE = '42P01';
    END IF ;

    --test que la colonne existe bien
    --42703 	undefined_column
    IF EXISTS (
        SELECT * FROM information_schema.columns  t  WHERE  t.table_schema ||'.'|| t.table_name = tbl_name AND column_name = select_col_name
    ) IS FALSE THEN
        RAISE 'Undefined column: %', select_col_name USING ERRCODE = '42703';
    END IF ;


      -- TODO transtypage en text pour des questions de généricité. A réflechir
      select_sql := 'SELECT row_to_json(c)::jsonb d
          FROM ' || tbl_name || ' c
          WHERE ' ||  select_col_name|| '::text = ''' || select_col_val || '''
          LIMIT ' || limit_ || '
          OFFSET ' || offset_ ;

      FOR import_rec IN EXECUTE select_sql LOOP
          PERFORM gn_synthese.import_json_row(import_rec.d);
      END LOOP;

    RETURN TRUE;
    END;
  $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100;
