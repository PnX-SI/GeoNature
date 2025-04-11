"""restore occtax missing counting

Revision ID: 9624348fea40
Revises: 22c2851bc387
Create Date: 2022-10-12 16:19:18.065398

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9624348fea40"
down_revision = "c26c770b00ae"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        WITH
            occ_id (id_occ) as (
                SELECT DISTINCT o.id_occurrence_occtax
                FROM pr_occtax.t_occurrences_occtax o
                INNER JOIN gn_commons.t_history_actions h_create ON o.unique_id_occurence_occtax = h_create.uuid_attached_row AND h_create.operation_type = 'I'
                INNER JOIN gn_commons.bib_tables_location bt ON bt.id_table_location = h_create.id_table_location AND bt.schema_name = 'pr_occtax' AND bt.table_name = 't_occurrences_occtax'
                WHERE NOT EXISTS (SELECT NULL FROM pr_occtax.cor_counting_occtax c WHERE o.id_occurrence_occtax = c.id_occurrence_occtax)
                AND h_create.operation_date > '2021-06-29'
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
    """
    )

    op.execute(
        """
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
    """
    )


def downgrade():
    pass
