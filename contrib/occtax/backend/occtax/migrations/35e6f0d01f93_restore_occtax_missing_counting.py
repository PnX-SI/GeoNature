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
            --AND h_create.operation_date > '2021-05-31'
        ),
        restauration_occ (id_occ, table_content) as (
            SELECT DISTINCT ON (id_occ) o.id_occ, h_c.table_content
            FROM occ_id o
            JOIN gn_commons.t_history_actions h_c ON (h_c.table_content->>'id_occurrence_occtax')::integer = o.id_occ
            JOIN gn_commons.bib_tables_location bt ON bt.id_table_location = h_c.id_table_location AND bt.schema_name = 'pr_occtax' AND bt.table_name = 'cor_counting_occtax'
            ORDER BY id_occ, h_c.operation_date DESC
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


def downgrade():
    pass
