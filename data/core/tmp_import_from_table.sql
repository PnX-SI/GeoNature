CREATE OR REPLACE FUNCTION gn_synthese.import_from_table (
    select_col_name character varying, 
    select_col_val character varying,
    tbl_name character varying,
    limit_ integer default 1e8,
    offset_ integer default 0
    ) RETURNS boolean LANGUAGE 'plpgsql' COST 100 VOLATILE AS $BODY$

    DECLARE
        insert_columns text;
        select_cmd text;
        select_columns text;
        update_columns text;
        start_time timestamp;
        insert_cmd text;
        update_cmd text;
        cond_joint_synthese text;
        error_msg text;
        test text;
        
    BEGIN


	start_time := (SELECT clock_timestamp());

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

        WITH import_col AS (
            SELECT attname::text as column_name
            FROM   pg_attribute
            WHERE  attrelid = tbl_name::regclass
                AND    attnum > 0
                AND    NOT attisdropped
        ), synt_col AS (
            SELECT column_name, column_default, CASE WHEN data_type =
                'USER-DEFINED' THEN NULL ELSE data_type END as data_type
            FROM information_schema.columns
            WHERE table_schema || '.' || table_name ='gn_synthese.synthese'
        )
        SELECT
            string_agg(s.column_name, ',')  as insert_columns,
            string_agg(
                CASE
                    WHEN NOT column_default IS NULL THEN 'COALESCE(d.' ||
                        i.column_name  || COALESCE('::' || data_type, '') || ', ' ||
                        column_default || ') as ' || i.column_name
                    ELSE 'd.' || i.column_name || COALESCE('::' || data_type, '')
                END, ','
            ) as select_columns ,
            string_agg(
                s.column_name || '=' || CASE
                    WHEN NOT column_default IS NULL THEN 'COALESCE(d.' ||
                        i.column_name  || COALESCE('::' || data_type, '') || ', ' ||
                        column_default || ') '
                    ELSE 'd.' || i.column_name || COALESCE('::' || data_type, '')
                END
            , ',')
        INTO insert_columns, select_columns, update_columns
        FROM synt_col s
        JOIN import_col i ON i.column_name = s.column_name;

        DROP TABLE IF EXISTS tmp_process_import;
        CREATE TEMP TABLE tmp_process_import (
            id_synthese int,
            entity_source_pk_value varchar,
            cd_nom int,
            action char(1)
        );



        cond_joint_synthese := '
            (d.entity_source_pk_value::varchar = s.entity_source_pk_value AND s.id_source = d.id_source)
            '
        ;
-- OR d.unique_id_sinp = s.unique_id_sinp
        insert_cmd := ' 
            WITH data AS (
                SELECT * FROM ' || tbl_name || ' LIMIT ' ||"limit_"||' OFFSET ' ||offset_|| '  
            ), inserted_rows as (
                INSERT INTO gn_synthese.synthese (' || insert_columns || ') 
                    SELECT ' || select_columns  || ' FROM data d
                    LEFT OUTER JOIN gn_synthese.synthese s ON ' ||cond_joint_synthese|| '
                    WHERE s.id_synthese IS NULL
                    RETURNING id_synthese, entity_source_pk_value::varchar, cd_nom
            )
            INSERT INTO tmp_process_import
                SELECT id_synthese, entity_source_pk_value, cd_nom, ''I'' as action
                FROM inserted_rows'
        ;
        RAISE NOTICE '%', insert_cmd;
        EXECUTE insert_cmd;

         RAISE NOTICE 'Insert cor_area_synthese : %', clock_timestamp();

        update_cmd := '
            WITH data AS (
                SELECT * FROM ' || tbl_name || ' LIMIT ' ||"limit_"||' OFFSET ' ||offset_|| ' 
            ), updated_rows as (
                UPDATE gn_synthese.synthese s 
                SET ' || update_columns || ' 
                FROM data d
                LEFT JOIN tmp_process_import t
                ON d.entity_source_pk_value::varchar = t.entity_source_pk_value 
                WHERE ' ||cond_joint_synthese|| ' AND t.entity_source_pk_value IS NULL
                RETURNING s.id_synthese, s.entity_source_pk_value, s.cd_nom
            )
            INSERT INTO tmp_process_import
                SELECT id_synthese, entity_source_pk_value, cd_nom, ''U'' as action
                FROM updated_rows'
        ;

        EXECUTE update_cmd;
        RAISE NOTICE '%', update_cmd;


     --Test si ids_observateur est spécifié
     IF (
        SELECT true
        FROM   pg_attribute
        WHERE  attrelid = tbl_name::regclass
            AND    attname::text = 'ids_observateur'
    ) IS TRUE THEN
         RAISE NOTICE 'Import des observateurs : %', clock_timestamp();
         -- Import des observateurs

        ALTER TABLE gn_synthese.cor_observer_synthese DISABLE TRIGGER trg_maj_synthese_observers_txt;

        RAISE NOTICE '    Clean observateurs : %', clock_timestamp();
        DELETE FROM gn_synthese.cor_observer_synthese
            USING tmp_process_import
            WHERE cor_observer_synthese.id_synthese = tmp_process_import.id_synthese ;

         RAISE NOTICE '    INSERT observateurs : %', clock_timestamp();
         EXECUTE FORMAT (
            'WITH obs AS (
                SELECT id_synthese,  unnest(ids_observateur)::int as id_role
                FROM %s d
                JOIN tmp_process_import c
                  ON d.entity_source_pk_value = d.entity_source_pk_value
                WHERE c.action IN (''I'', ''U'')
            )
            INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
                SELECT DISTINCT id_synthese, id_role
                FROM obs
                JOIN utilisateurs.t_roles
                 USING(id_role)
            ', tbl_name
        );

         ALTER TABLE gn_synthese.cor_observer_synthese ENABLE TRIGGER
trg_maj_synthese_observers_txt;

     END IF;

	CREATE TABLE IF NOT EXISTS gn_synthese.import_logs(
	table_name text,
	success text,
	error_msg text,
	start_time timestamp,
	end_time timestamp,
	nb_insert integer,
	nb_update integer,
	nb_delete integer
	);

     INSERT INTO gn_synthese.import_logs (
          table_name, success, error_msg, start_time, end_time, nb_insert,
         nb_update, nb_delete
    )
    SELECT
          tbl_name, true, NULL, start_time, clock_timestamp(),
          count(*) FILTER (WHERE action='I') as nb_insert,
          count(*) FILTER (WHERE action='U') as nb_update,
          count(*) FILTER (WHERE action='D') as nb_delete
    FROM tmp_process_import;
    
     RAISE NOTICE '%', clock_timestamp();

     RAISE NOTICE 'END : %', clock_timestamp();



     RAISE NOTICE 'Update cor_area_synthese : %', clock_timestamp();

      RETURN TRUE;
      END;
    $BODY$;

-- 
-- TRUNCATE TABLE gn_synthese.import_logs;
-- DROP TABLE IF EXISTS gn_synthese.test;
-- CREATE TABLE gn_synthese.test AS (
-- SELECT uuid_generate_v4(), 
-- 1 AS id_source,
-- '4' AS entity_source_pk_value,
-- 'youpi' AS nom_cite,
-- NOW() as date_min,
-- NOW() as date_max,
-- '{1, 2}'::INT[] as ids_observateur
-- );
-- SELECT * FROM gn_synthese.test;
-- SELECT gn_synthese.import_from_table('id_source', '1', 'gn_synthese.test', 1000, 0);
-- SELECT * FROM gn_synthese.import_logs;
-- SELECT observers FROM gn_synthese.synthese;
-- SELECT * FROM gn_synthese.cor_observer_synthese
