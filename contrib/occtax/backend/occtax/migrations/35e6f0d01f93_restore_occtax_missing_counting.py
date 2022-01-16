"""restore occtax missing counting
 
Revision ID: 35e6f0d01f93
Revises: 944072911ff7
Create Date: 2022-01-07 15:46:58.634720
 
"""
from alembic import op
import sqlalchemy as sa
 
 
# revision identifiers, used by Alembic.
revision = '35e6f0d01f93'
down_revision = '944072911ff7'
branch_labels = None
depends_on = None
 
 
def upgrade():
    op.execute("""
        WITH
            occ_id (id_occ) as (
                SELECT DISTINCT o.id_occurrence_occtax
                FROM pr_occtax.t_occurrences_occtax o
                INNER JOIN gn_commons.t_history_actions h_create ON o.unique_id_occurence_occtax = h_create.uuid_attached_row AND h_create.operation_type = 'I'
                INNER JOIN gn_commons.bib_tables_location bt ON bt.id_table_location = h_create.id_table_location AND bt.schema_name = 'pr_occtax' AND bt.table_name = 't_occurrences_occtax'
                WHERE NOT EXISTS (SELECT NULL FROM pr_occtax.cor_counting_occtax c WHERE o.id_occurrence_occtax = c.id_occurrence_occtax)
                --au besoin par rapport à la requête initiale, ajouter un filtre sur la date
                --AND h_create.operation_date > '2022-01-12'
            ),
            --exclude last commit on old counting execute with new counting insert
            exclude_history (id_occ, id_history_action) as (
                SELECT o.id_occ, max(id_history_action), count((h_c.table_content->>'id_occurrence_occtax')::integer)
                FROM occ_id o
                JOIN gn_commons.t_history_actions h_c ON (h_c.table_content->>'id_occurrence_occtax')::integer = o.id_occ
                JOIN gn_commons.bib_tables_location bt ON bt.id_table_location = h_c.id_table_location AND bt.schema_name = 'pr_occtax' AND bt.table_name = 'cor_counting_occtax'
                GROUP BY o.id_occ
                HAVING count((h_c.table_content->>'id_occurrence_occtax')::integer) > 1
            ),
            restauration_occ (id_occ, table_content) as (
                SELECT DISTINCT ON (id_occ) o.id_occ, h_c.table_content
                FROM occ_id o
                JOIN gn_commons.t_history_actions h_c ON (h_c.table_content->>'id_occurrence_occtax')::integer = o.id_occ
                JOIN gn_commons.bib_tables_location bt ON bt.id_table_location = h_c.id_table_location AND bt.schema_name = 'pr_occtax' AND bt.table_name = 'cor_counting_occtax'
                WHERE NOT EXISTS (
                    SELECT NULL FROM exclude_history WHERE exclude_history.id_history_action = h_c.id_history_action
                )
                ORDER BY id_occ, h_c.id_history_action DESC
            )
        INSERT INTO pr_occtax.cor_counting_occtax (
            id_occurrence_occtax,
            id_nomenclature_life_stage,
            id_nomenclature_sex,
            id_nomenclature_obj_count,
            id_nomenclature_type_count,
            count_min,
            count_max,
            additional_fields
        )
        SELECT
            (table_content->>'id_occurrence_occtax')::bigint,
            (table_content->>'id_nomenclature_life_stage')::integer,
            (table_content->>'id_nomenclature_sex')::integer,
            (table_content->>'id_nomenclature_obj_count')::integer,
            (table_content->>'id_nomenclature_type_count')::integer,
            (table_content->>'count_min')::integer,
            (table_content->>'count_max')::integer,
            (table_content->>'additional_fields')::jsonb
        FROM restauration_occ
    """)
 
    op.execute("""
        WITH 
        observers (id_releve_occtax, observers) as (
            SELECT r.id_releve_occtax, array_to_string(array_agg(concat_ws(' ', obs.nom_role, obs.prenom_role)), ', ')
            FROM pr_occtax.t_releves_occtax r
            INNER JOIN pr_occtax.cor_role_releves_occtax r_obs ON r.id_releve_occtax = r_obs.id_releve_occtax
            INNER JOIN utilisateurs.t_roles obs ON r_obs.id_role = obs.id_role
            GROUP BY r.id_releve_occtax
        )
 
        UPDATE gn_synthese.synthese SET
        unique_id_sinp = counting.unique_id_sinp_occtax,
        unique_id_sinp_grp = rel.unique_id_sinp_grp,
        id_dataset = rel.id_dataset,
        id_digitiser = rel.id_digitiser,
        id_nomenclature_grp_typ = rel.id_nomenclature_grp_typ,
        date_min = date_trunc('day',rel.date_min)+COALESCE(rel.hour_min,'00:00:00'::time),
        date_max = date_trunc('day',rel.date_max)+COALESCE(rel.hour_max,'00:00:00'::time),
        altitude_min = rel.altitude_min,
        altitude_max = rel.altitude_max,
        comment_context = rel.comment,
        the_geom_local = rel.geom_local,
        the_geom_point = ST_CENTROID(rel.geom_4326),
        the_geom_4326 = rel.geom_4326,
        precision = rel.precision,
        id_nomenclature_geo_object_nature = rel.id_nomenclature_geo_object_nature,
        depth_min = rel.depth_min,
        depth_max = rel.depth_max,
        place_name = rel.place_name,
        cd_hab = rel.cd_hab,
        grp_method = rel.grp_method,
        id_nomenclature_obs_technique = occ.id_nomenclature_obs_technique,
        id_nomenclature_bio_condition = occ.id_nomenclature_bio_condition,
        id_nomenclature_bio_status = occ.id_nomenclature_bio_status,
        id_nomenclature_naturalness = occ.id_nomenclature_naturalness,
        id_nomenclature_exist_proof = occ.id_nomenclature_exist_proof,
        id_nomenclature_diffusion_level = occ.id_nomenclature_diffusion_level,
        id_nomenclature_observation_status = occ.id_nomenclature_observation_status,
        id_nomenclature_blurring = occ.id_nomenclature_blurring,
        id_nomenclature_source_status = occ.id_nomenclature_source_status,
        determiner = occ.determiner,
        id_nomenclature_determination_method = occ.id_nomenclature_determination_method,
        cd_nom = occ.cd_nom,
        nom_cite = occ.nom_cite,
        meta_v_taxref = occ.meta_v_taxref,
        sample_number_proof = occ.sample_number_proof,
        digital_proof = occ.digital_proof,
        non_digital_proof = occ.non_digital_proof,
        comment_description = occ.comment,
        id_nomenclature_behaviour = occ.id_nomenclature_behaviour,
        id_nomenclature_life_stage = counting.id_nomenclature_life_stage,
        id_nomenclature_sex = counting.id_nomenclature_sex,
        id_nomenclature_obj_count = counting.id_nomenclature_obj_count,
        id_nomenclature_type_count = counting.id_nomenclature_type_count,
        count_min = counting.count_min,
        count_max = counting.count_max,
        observers = COALESCE (observers.observers, rel.observers_txt),
        additional_data = COALESCE(rel.additional_fields, '{}'::jsonb) || COALESCE(occ.additional_fields, '{}'::jsonb) || COALESCE(counting.additional_fields, '{}'::jsonb)
        FROM pr_occtax.cor_counting_occtax counting
        INNER JOIN pr_occtax.t_occurrences_occtax occ ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
        INNER JOIN pr_occtax.t_releves_occtax rel ON occ.id_releve_occtax = rel.id_releve_occtax
        LEFT JOIN observers ON rel.id_releve_occtax = observers.id_releve_occtax
        WHERE synthese.unique_id_sinp = counting.unique_id_sinp_occtax AND synthese.cd_nom <> occ.cd_nom;
    """)
 
    op.execute("""
        DROP FUNCTION IF EXISTS pr_occtax.insert_in_synthese(integer);
 
        CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(
            my_id_counting integer)
            RETURNS integer[]
            LANGUAGE 'plpgsql'
            COST 100
            VOLATILE PARALLEL UNSAFE
        AS $BODY$
          DECLARE
          new_count RECORD;
          occurrence RECORD;
          releve RECORD;
          id_source integer;
          id_module integer;
          id_nomenclature_source_status integer;
          myobservers RECORD;
          id_role_loop integer;
 
          BEGIN
          --recupération du counting à partir de son ID
          SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;
 
          -- Récupération de l'occurrence
          SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;
 
          -- Récupération du relevé
          SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;
 
          -- Récupération de la source
          SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source ILIKE 'occtax';
 
          -- Récupération de l'id_module
          SELECT INTO id_module gn_commons.get_id_module_bycode('OCCTAX');
 
          -- Récupération du status_source depuis le JDD
          SELECT INTO id_nomenclature_source_status d.id_nomenclature_source_status FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;
 
          --Récupération et formatage des observateurs
          SELECT INTO myobservers array_to_string(array_agg(concat_ws(' ', rol.nom_role, rol.prenom_role)), ', ') AS observers_name,
          array_agg(rol.id_role) AS observers_id
          FROM pr_occtax.cor_role_releves_occtax cor
          JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
          WHERE cor.id_releve_occtax = releve.id_releve_occtax;
 
          -- insertion dans la synthese
          INSERT INTO gn_synthese.synthese (
          unique_id_sinp,
          unique_id_sinp_grp,
          id_source,
          entity_source_pk_value,
          id_dataset,
          id_module,
          id_nomenclature_geo_object_nature,
          id_nomenclature_grp_typ,
          grp_method,
          id_nomenclature_obs_technique,
          id_nomenclature_bio_status,
          id_nomenclature_bio_condition,
          id_nomenclature_naturalness,
          id_nomenclature_exist_proof,
          id_nomenclature_diffusion_level,
          id_nomenclature_life_stage,
          id_nomenclature_sex,
          id_nomenclature_obj_count,
          id_nomenclature_type_count,
          id_nomenclature_observation_status,
          id_nomenclature_blurring,
          id_nomenclature_source_status,
          id_nomenclature_info_geo_type,
          id_nomenclature_behaviour,
          count_min,
          count_max,
          cd_nom,
          cd_hab,
          nom_cite,
          meta_v_taxref,
          sample_number_proof,
          digital_proof,
          non_digital_proof,
          altitude_min,
          altitude_max,
          depth_min,
          depth_max,
          place_name,
          precision,
          the_geom_4326,
          the_geom_point,
          the_geom_local,
          date_min,
          date_max,
          observers,
          determiner,
          id_digitiser,
          id_nomenclature_determination_method,
          comment_context,
          comment_description,
          last_action,
          additional_data
          )
          VALUES(
            new_count.unique_id_sinp_occtax,
            releve.unique_id_sinp_grp,
            id_source,
            new_count.id_counting_occtax,
            releve.id_dataset,
            id_module,
            releve.id_nomenclature_geo_object_nature,
            releve.id_nomenclature_grp_typ,
            releve.grp_method,
            occurrence.id_nomenclature_obs_technique,
            occurrence.id_nomenclature_bio_status,
            occurrence.id_nomenclature_bio_condition,
            occurrence.id_nomenclature_naturalness,
            occurrence.id_nomenclature_exist_proof,
            occurrence.id_nomenclature_diffusion_level,
            new_count.id_nomenclature_life_stage,
            new_count.id_nomenclature_sex,
            new_count.id_nomenclature_obj_count,
            new_count.id_nomenclature_type_count,
            occurrence.id_nomenclature_observation_status,
            occurrence.id_nomenclature_blurring,
            -- status_source récupéré depuis le JDD
            id_nomenclature_source_status,
            -- id_nomenclature_info_geo_type: type de rattachement = non saisissable: georeferencement
            ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1'),
            occurrence.id_nomenclature_behaviour,
            new_count.count_min,
            new_count.count_max,
            occurrence.cd_nom,
            releve.cd_hab,
            occurrence.nom_cite,
            occurrence.meta_v_taxref,
            occurrence.sample_number_proof,
            occurrence.digital_proof,
            occurrence.non_digital_proof,
            releve.altitude_min,
            releve.altitude_max,
            releve.depth_min,
            releve.depth_max,
            releve.place_name,
            releve.precision,
            releve.geom_4326,
            ST_CENTROID(releve.geom_4326),
            releve.geom_local,
            date_trunc('day',releve.date_min)+COALESCE(releve.hour_min,'00:00:00'::time),
            date_trunc('day',releve.date_max)+COALESCE(releve.hour_max,'00:00:00'::time),
            COALESCE (myobservers.observers_name, releve.observers_txt),
            occurrence.determiner,
            releve.id_digitiser,
            occurrence.id_nomenclature_determination_method,
            releve.comment,
            occurrence.comment,
            'I',
            COALESCE(releve.additional_fields, '{}'::jsonb) || COALESCE(occurrence.additional_fields, '{}'::jsonb) || COALESCE(new_count.additional_fields, '{}'::jsonb)
          );
 
            RETURN myobservers.observers_id ;
          END;
           
        $BODY$;
    """)
 
 
def downgrade():
    pass