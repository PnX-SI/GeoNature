"""MOBILE : Additional fields - process nomenclature

Revision ID: a22f59a3912c
Revises: b5b0d26c1fcc
Create Date: 2026-08-10 10:36:15.272438

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import text

# revision identifiers, used by Alembic.
revision = "a22f59a3912c"
down_revision = "b5b0d26c1fcc"
branch_labels = None
depends_on = None


SOURCES = [
    {
        "id_field": "id_releve_occtax",
        "table_name": "t_releves_occtax",
        "object_code": "OCCTAX_RELEVE",
    },
    {
        "id_field": "id_occurrence_occtax",
        "table_name": "t_occurrences_occtax",
        "object_code": "OCCTAX_OCCURENCE",
    },
    {
        "id_field": "id_counting_occtax",
        "table_name": "cor_counting_occtax",
        "object_code": "OCCTAX_DENOMBREMENT",
    },
]


def upgrade():
    for source in SOURCES:
        sql = generate_upgrade(
            id_field=source["id_field"],
            table_name=source["table_name"],
            object_code=source["object_code"],
        )
        op.execute(text(sql))


def downgrade():
    for source in SOURCES:
        op.execute(generate_downgrade(**source))


def generate_upgrade(id_field, table_name, object_code):
    sql = f"""
        WITH ids AS (
            SELECT
                DISTINCT tro.id_releve_occtax ,
                too.id_occurrence_occtax ,
                cco.id_counting_occtax
            FROM pr_occtax.t_releves_occtax tro
            JOIN pr_occtax.t_occurrences_occtax too
            ON tro.id_releve_occtax = too.id_releve_occtax
            JOIN pr_occtax.cor_counting_occtax cco
            ON too.id_occurrence_occtax = cco.id_occurrence_occtax
            WHERE
                tro.meta_device_entry = 'mobile'
        ),
        fields AS (
            SELECT
                taf.field_name,
                taf.code_nomenclature_type
            FROM gn_commons.t_additional_fields taf
            JOIN gn_commons.bib_widgets bw
            ON bw.id_widget = taf.id_widget
            JOIN gn_commons.cor_field_object cfo
            ON cfo.id_field = taf.id_field
            JOIN gn_permissions.t_objects t
            ON
                t.id_object = cfo.id_object
            WHERE
                bw.widget_name = 'nomenclature'
                AND t.code_object = '{object_code}'
        ),
        final_data AS (
            SELECT
                tro.{id_field},
                jsonb_object_agg(
                COALESCE(kv.key, e.key),
                COALESCE(kv.value, e.value)
                ) AS merged
            FROM pr_occtax.{table_name} tro
            JOIN ids
            ON ids.{id_field} = tro.{id_field}
            CROSS JOIN LATERAL jsonb_each(tro.additional_fields) e(key, value)
            LEFT JOIN fields f
            ON f.field_name = e.key
            LEFT JOIN ref_nomenclatures.t_nomenclatures tn
            ON tn.id_nomenclature::text  = e.value #>> '{{}}'
            AND tn.id_type =ref_nomenclatures.get_id_nomenclature_type(f.code_nomenclature_type)
            LEFT JOIN LATERAL (
                SELECT *
                FROM jsonb_each(
                    jsonb_build_object(
                        e.key, tn.id_nomenclature,
                        '_label_' || e.key, COALESCE(tn.label_default, e.value #>> '{{}}')
                    )
                )
            ) kv
            ON f.field_name IS NOT NULL
            WHERE tro.additional_fields IS NOT NULL
            GROUP BY tro.{id_field}
        )
        UPDATE pr_occtax.{table_name} tro
            SET additional_fields = d.merged
        FROM final_data d
        WHERE d.{id_field} = tro.{id_field};
    """
    return sql


def generate_downgrade(id_field, table_name, object_code):
    sql = f"""
        WITH ids AS (
                    SELECT
                        DISTINCT tro.id_releve_occtax ,
                        too.id_occurrence_occtax ,
                        cco.id_counting_occtax
                    FROM pr_occtax.t_releves_occtax tro
                    JOIN pr_occtax.t_occurrences_occtax too
                    ON tro.id_releve_occtax = too.id_releve_occtax
                    JOIN pr_occtax.cor_counting_occtax cco
                    ON too.id_occurrence_occtax = cco.id_occurrence_occtax
                    WHERE
                        tro.meta_device_entry = 'mobile'
                ),
        fields AS (
            SELECT
                taf.field_name,
                taf.code_nomenclature_type
            FROM gn_commons.t_additional_fields taf
            JOIN gn_commons.bib_widgets bw
            ON bw.id_widget = taf.id_widget
            JOIN gn_commons.cor_field_object cfo
            ON cfo.id_field = taf.id_field
            JOIN gn_permissions.t_objects t
            ON
                t.id_object = cfo.id_object
            WHERE
                bw.widget_name = 'nomenclature'
                AND t.code_object = '{object_code}'
        ),
        final_data AS (
            SELECT
            tro.{id_field},
            jsonb_object_agg(
                e.key,
                CASE
                    WHEN e.value = 'null'::jsonb AND tro.additional_fields ? ('_label_' || e.key)
                        THEN tro.additional_fields -> ('_label_' || e.key)
                ELSE e.value
                END
            ) AS merged
            FROM pr_occtax.{table_name} tro
            JOIN ids
            ON ids.{id_field} = tro.{id_field}
            CROSS JOIN LATERAL jsonb_each(tro.additional_fields) e(key, value)
            WHERE e.key NOT LIKE '_label_%'
            GROUP BY tro.{id_field}
        )
        UPDATE pr_occtax.{table_name} tro
            SET additional_fields = d.merged
        FROM final_data d
        WHERE d.{id_field} = tro.{id_field};
    """
    return sql
