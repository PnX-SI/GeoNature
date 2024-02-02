"""remove local srid

Revision ID: ca052245c6ec
Revises: 1dbc45309d6e
Create Date: 2022-03-11 15:11:46.640624

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "ca052245c6ec"
down_revision = "1dbc45309d6e"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
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
    ;
    """
    )
    op.execute(
        """
    DELETE FROM
        gn_commons.t_parameters
    WHERE
        parameter_name = 'local_srid'
    """
    )


def downgrade():
    op.execute(
        """
    INSERT INTO
        gn_commons.t_parameters (
            id_organism,
            parameter_name,
            parameter_desc,
            parameter_value
        )
    VALUES (
        (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'ALL'),
        'local_srid',
        'Valeur du SRID local',
        Find_SRID('ref_geo', 'l_areas', 'geom')
    )
    """
    )
    op.execute(
        """
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
        local_srid int;

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
        local_srid := (SELECT parameter_value FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid');
        geom_data := (
            SELECT json_build_object(
                'the_geom_4326',geom,
                'the_geom_point',(SELECT ST_centroid(geom)),
                'the_geom_local',(SELECT ST_transform(geom, local_srid))
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
    ;
    """
    )
