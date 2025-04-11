CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_calculate_sensitivity_on_each_statement()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ 
            -- Calculate sensitivity on insert in synthese
            BEGIN
            WITH cte AS (
              SELECT 
                id_synthese,
                gn_sensitivity.get_id_nomenclature_sensitivity(
                  new_row.date_min::date, 
                  taxonomie.find_cdref(new_row.cd_nom), 
                  new_row.the_geom_local,
                  jsonb_build_object(
                    'STATUT_BIO', new_row.id_nomenclature_bio_status,
                    'OCC_COMPORTEMENT', new_row.id_nomenclature_behaviour
                  )
                ) AS id_nomenclature_sensitivity
              FROM
                NEW AS new_row
            )
            UPDATE
              gn_synthese.synthese AS s
            SET 
              id_nomenclature_sensitivity = c.id_nomenclature_sensitivity
            FROM
              cte AS c
            WHERE
              c.id_synthese = s.id_synthese
            ;
            RETURN NULL;
            END;
          $function$

CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_log_delete_on_synthese()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
    BEGIN
        -- log id/uuid of deleted datas into specific log table
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO gn_synthese.t_log_synthese
            SELECT
                o.id_synthese    AS id_synthese
                , 'D'                AS last_action
                , now()              AS meta_last_action_date
            from old_table o
            ON CONFLICT (id_synthese)
            DO UPDATE SET last_action = 'D', meta_last_action_date = now();
        END IF;
        RETURN NULL;
    END;
    $function$

CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_maj_observers_txt()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  theobservers text;
  theidsynthese integer;
BEGIN
  IF (TG_OP = 'UPDATE') OR (TG_OP = 'INSERT') THEN
    theidsynthese = NEW.id_synthese;
  END IF;
  IF (TG_OP = 'DELETE') THEN
    theidsynthese = OLD.id_synthese;
  END IF;
  --Construire le texte pour le champ observers de la synthese
  SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ')
  FROM utilisateurs.t_roles r
  WHERE r.id_role IN(SELECT id_role FROM gn_synthese.cor_observer_synthese WHERE id_synthese = theidsynthese);
  --mise à jour du champ observers dans la table synthese
  UPDATE gn_synthese.synthese
  SET observers = theobservers
  WHERE id_synthese =  theidsynthese;
RETURN NULL;
END;
$function$

CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_update_sensitivity_on_each_row()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$ 
            -- Calculate sensitivity on update in synthese
            BEGIN
            NEW.id_nomenclature_sensitivity = gn_sensitivity.get_id_nomenclature_sensitivity(
                NEW.date_min::date, 
                taxonomie.find_cdref(NEW.cd_nom), 
                NEW.the_geom_local,
                jsonb_build_object(
                  'STATUT_BIO', NEW.id_nomenclature_bio_status,
                  'OCC_COMPORTEMENT', NEW.id_nomenclature_behaviour
                )
            );
            RETURN NEW;
            END;
          $function$

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
  $function$

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_l_areas_insert_cor_area_synthese_on_each_statement()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
      DECLARE
      BEGIN
      -- Intersection de toutes les observations avec les nouvelles zones et écriture dans cor_area_synthese
          INSERT INTO gn_synthese.cor_area_synthese (id_area, id_synthese)
            SELECT
              new_areas.id_area AS id_area,
              s.id_synthese as id_synthese
            FROM NEW as new_areas
            join gn_synthese.synthese s
              ON public.ST_INTERSECTS(s.the_geom_local, new_areas.geom)
            WHERE new_areas.enable IS true
                AND (
                        ST_GeometryType(s.the_geom_local) = 'ST_Point'
                    OR
                    NOT public.ST_TOUCHES(s.the_geom_local, new_areas.geom)
                );
      RETURN NULL;
      END;
      $function$

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_update_in_cor_area_synthese()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
      WHERE a.enable IS TRUE AND s.id_synthese = NEW.id_synthese AND (ST_GeometryType(NEW.the_geom_local) = 'ST_Point' OR NOT public.ST_TOUCHES(NEW.the_geom_local,a.geom));
  RETURN NULL;
  END;
  $function$

CREATE OR REPLACE FUNCTION gn_synthese.get_default_nomenclature_value(myidtype character varying, myidorganism integer DEFAULT NULL::integer, myregne character varying DEFAULT '0'::character varying, mygroup2inpn character varying DEFAULT '0'::character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    --Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
    --Return -1 if nothing matche with given parameters
      DECLARE
        thenomenclatureid integer;
      BEGIN
          SELECT INTO thenomenclatureid id_nomenclature FROM (
            SELECT
                id_nomenclature,
                regne,
                group2_inpn,
                CASE
                    WHEN n.id_organism = myidorganism THEN 1
                    ELSE 0
                END prio_organisme
            FROM gn_synthese.defaults_nomenclatures_value n
            JOIN utilisateurs.bib_organismes o
            ON o.id_organisme = n.id_organism
            WHERE mnemonique_type = myidtype
            AND (n.id_organism = myidorganism OR n.id_organism = NULL OR o.nom_organisme = 'ALL')
            AND (regne = myregne OR regne = '0')
            AND (group2_inpn = mygroup2inpn OR group2_inpn = '0')
        ) AS defaults_nomenclatures_value
        ORDER BY group2_inpn DESC, regne DESC, prio_organisme DESC LIMIT 1;
        RETURN thenomenclatureid;
      END;
    $function$

CREATE OR REPLACE FUNCTION gn_synthese.get_ids_synthese_for_user_action(myuser integer, myaction text)
 RETURNS integer[]
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
-- The fonction return a array of id_synthese for the given id_role and CRUVED action
-- USAGE : SELECT gn_synthese.get_ids_synthese_for_user_action(1,'U');
DECLARE
  idssynthese integer[];
BEGIN
WITH apps_avalaible AS(
	SELECT id_application, max(tag_object_code) AS portee FROM (
	  SELECT a.id_application, v.tag_object_code
	  FROM utilisateurs.t_applications a
	  JOIN utilisateurs.v_usersaction_forall_gn_modules v ON a.id_parent = v.id_application
	  WHERE id_role = myuser
	  AND tag_action_code = myaction
	  UNION
	  SELECT id_application, tag_object_code
	  FROM utilisateurs.v_usersaction_forall_gn_modules
	  WHERE id_role = myuser
	  AND tag_action_code = myaction
	) a
	GROUP BY id_application
)
SELECT INTO idssynthese array_agg(DISTINCT s.id_synthese)
FROM gn_synthese.synthese s
LEFT JOIN gn_synthese.cor_observer_synthese cos ON cos.id_synthese = s.id_synthese
LEFT JOIN gn_meta.cor_dataset_actor cda ON cda.id_dataset = s.id_dataset
--JOIN apps_avalaible a ON a.id_application = s.id_module
WHERE s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 3::text)
OR (cda.id_organism = (SELECT id_organisme FROM utilisateurs.t_roles WHERE id_role = myuser) AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 2::text))
OR (s.id_digitiser = myuser AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 1::text))
OR (cos.id_role = myuser AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 1::text))
OR (cda.id_role = myuser AND s.id_module IN (SELECT id_application FROM apps_avalaible WHERE portee = 1::text))
;

RETURN idssynthese;
END;
$function$

CREATE OR REPLACE FUNCTION gn_synthese.import_json_row(datain jsonb, datageojson text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
      DECLARE
        insert_columns text;
        select_columns text;
        update_columns text;

        geom geometry;
        geom_data jsonb;

       postgis_maj_num_version int;
    BEGIN


      -- Import des données dans une table temporaire pour faciliter le traitement
      DROP TABLE IF EXISTS tmp_process_import;
      CREATE TABLE tmp_process_import (
          id_synthese int,
          datain jsonb,
          action char(1)
      );
      INSERT INTO tmp_process_import (datain)
      SELECT datain;

      postgis_maj_num_version := (SELECT split_part(version, '.', 1)::int FROM pg_available_extension_versions WHERE name = 'postgis' AND installed = true);

      -- Cas ou la geométrie est passée en geojson
      IF NOT datageojson IS NULL THEN
        geom := (SELECT ST_setsrid(ST_GeomFromGeoJSON(datageojson), 4326));
        geom_data := (
            SELECT json_build_object(
                'the_geom_4326',geom,
                'the_geom_point',(SELECT ST_centroid(geom)),
                'the_geom_local',(SELECT ST_transform(geom, Find_SRID('gn_synthese', 'synthese', 'the_geom_local')))
            )
        );

        UPDATE tmp_process_import d
          SET datain = d.datain || geom_data;
      END IF;

    -- ############ TEST

      -- colonne unique_id_sinp exists
      IF EXISTS (
            SELECT 1 FROM jsonb_object_keys(datain) column_name WHERE column_name =  'unique_id_sinp'
        ) IS FALSE THEN
            RAISE NOTICE 'Column unique_id_sinp is mandatory';
            RETURN FALSE;
      END IF ;

    -- ############ mapping colonnes

      WITH import_col AS (
        SELECT jsonb_object_keys(datain) AS column_name
      ), synt_col AS (
          SELECT column_name, column_default, CASE WHEN data_type = 'USER-DEFINED' THEN udt_name ELSE data_type END as data_type
          FROM information_schema.columns
          WHERE table_schema || '.' || table_name = 'gn_synthese.synthese'
      )
      SELECT
          string_agg(s.column_name, ',')  as insert_columns,
          string_agg(
              CASE
                  WHEN NOT column_default IS NULL THEN
                  'COALESCE(' || gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version) || ', ' || column_default || ') as ' || i.column_name
              ELSE gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version)
              END, ','
          ) as select_columns ,
          string_agg(
              s.column_name || '=' ||
              CASE
                WHEN NOT column_default IS NULL
                    THEN  'COALESCE(' || gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version) || ', ' || column_default || ') '
                ELSE gn_synthese.import_json_row_format_insert_data(i.column_name, data_type::varchar, postgis_maj_num_version)
              END
          , ',')
      INTO insert_columns, select_columns, update_columns
      FROM synt_col s
      JOIN import_col i
      ON i.column_name = s.column_name;

      -- ############# IMPORT DATA
      IF EXISTS (
          SELECT 1
          FROM   gn_synthese.synthese
          WHERE  unique_id_sinp = (datain->>'unique_id_sinp')::uuid
      ) IS TRUE THEN
        -- Update
        EXECUTE ' WITH i_row AS (
              UPDATE gn_synthese.synthese s SET ' || update_columns ||
              ' FROM  tmp_process_import
              WHERE s.unique_id_sinp =  (datain->>''unique_id_sinp'')::uuid
              RETURNING s.id_synthese, s.unique_id_sinp
              )
              UPDATE tmp_process_import d SET id_synthese = i_row.id_synthese
              FROM i_row
              WHERE unique_id_sinp = i_row.unique_id_sinp
              ' ;
      ELSE
        -- Insert
        EXECUTE 'WITH i_row AS (
              INSERT INTO gn_synthese.synthese ( ' || insert_columns || ')
              SELECT ' || select_columns ||
              ' FROM tmp_process_import
              RETURNING id_synthese, unique_id_sinp
              )
              UPDATE tmp_process_import d SET id_synthese = i_row.id_synthese
              FROM i_row
              WHERE unique_id_sinp = i_row.unique_id_sinp
              ' ;
      END IF;

      -- Import des cor_observers
      DELETE FROM gn_synthese.cor_observer_synthese
      USING tmp_process_import
      WHERE cor_observer_synthese.id_synthese = tmp_process_import.id_synthese;

      IF jsonb_typeof(datain->'ids_observers') = 'array' THEN
        INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role)
        SELECT DISTINCT id_synthese, (jsonb_array_elements(t.datain->'ids_observers'))::text::int
        FROM tmp_process_import t;
      END IF;

      RETURN TRUE;
      END;
    $function$

CREATE OR REPLACE FUNCTION gn_synthese.import_json_row_format_insert_data(column_name character varying, data_type character varying, postgis_maj_num_version integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	col_srid int;
BEGIN
	-- Gestion de postgis 3
	IF ((postgis_maj_num_version > 2) AND (data_type = 'geometry')) THEN
		col_srid := (SELECT find_srid('gn_synthese', 'synthese', column_name));
		RETURN '(st_setsrid(ST_GeomFromGeoJSON(datain->>''' || column_name  || '''), ' || col_srid::text || '))' || COALESCE('::' || data_type, '');
	ELSE
		RETURN '(datain->>''' || column_name  || ''')' || COALESCE('::' || data_type, '');
	END IF;

END;
$function$

CREATE OR REPLACE FUNCTION gn_synthese.import_row_from_table(select_col_name character varying, select_col_val character varying, tbl_name character varying, limit_ integer, offset_ integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
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
    $function$

CREATE OR REPLACE FUNCTION gn_synthese.update_sensitivity()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
            DECLARE
                affected_rows_count int;
            BEGIN
                WITH cte AS (
                    SELECT
                        id_synthese,
                        id_nomenclature_sensitivity AS old_sensitivity,
                        gn_sensitivity.get_id_nomenclature_sensitivity(
                          date_min::date,
                          taxonomie.find_cdref(cd_nom),
                          the_geom_local,
                          jsonb_build_object(
                            'STATUT_BIO', id_nomenclature_bio_status,
                            'OCC_COMPORTEMENT', id_nomenclature_behaviour
                          )
                        ) AS new_sensitivity
                    FROM
                        gn_synthese.synthese
                    WHERE
                        id_nomenclature_sensitivity IS NULL
                    OR
                        id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0') -- non sensible
                    OR
                        taxonomie.find_cdref(cd_nom) IN (SELECT DISTINCT cd_ref FROM gn_sensitivity.t_sensitivity_rules_cd_ref)
                )
                UPDATE
                    gn_synthese.synthese s
                SET
                    id_nomenclature_sensitivity = new_sensitivity
                FROM
                    cte
                WHERE
                        s.id_synthese = cte.id_synthese
                    AND (
                        old_sensitivity IS NULL
                        OR
                        old_sensitivity != new_sensitivity
                    );
                GET DIAGNOSTICS affected_rows_count = ROW_COUNT;
                RETURN affected_rows_count;
            END;
        $function$

