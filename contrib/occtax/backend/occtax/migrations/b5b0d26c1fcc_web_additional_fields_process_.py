"""WEB : Additional fields - process nomenclature

Revision ID: b5b0d26c1fcc
Revises: 174f0d2fc3a4
Create Date: 2026-08-06 17:04:32.446593

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import text

# revision identifiers, used by Alembic.
revision = "b5b0d26c1fcc"
down_revision = "174f0d2fc3a4"
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
    return f"""
    WITH ids AS (
        SELECT DISTINCT tro.id_releve_occtax , too.id_occurrence_occtax , cco.id_counting_occtax
        FROM pr_occtax.t_releves_occtax tro
        JOIN pr_occtax.t_occurrences_occtax too
        ON tro.id_releve_occtax = too.id_releve_occtax
        JOIN pr_occtax.cor_counting_occtax cco
        ON too.id_occurrence_occtax = cco.id_occurrence_occtax
        WHERE tro.meta_device_entry = 'web' OR tro.meta_device_entry IS NULL
    ), fields AS (
        SELECT taf.field_name, taf.code_nomenclature_type
        FROM gn_commons.t_additional_fields taf
        JOIN gn_commons.bib_widgets bw
        ON bw.id_widget = taf.id_widget
        JOIN gn_commons.cor_field_object cfo
        ON cfo.id_field = taf.id_field
        JOIN gn_permissions.t_objects t
        ON t.id_object = cfo.id_object
        WHERE bw.widget_name = 'nomenclature' AND t.code_object = '{object_code}'
    ), r AS (
        SELECT tro.{id_field} , tro.additional_fields  ,  jsonb_object_keys(additional_fields) AS k
        FROM pr_occtax.{table_name} tro
        WHERE NOT tro.additional_fields IS NULL
    ), d AS (
        SELECT r.{id_field} ,
            jsonb_build_object(
            '_label_' || k,
            r.additional_fields->>k ,
            k,
            tn.id_nomenclature
            ) AS n
        FROM r
        JOIN fields ON fields.field_name = k
        LEFT JOIN ref_nomenclatures.t_nomenclatures tn
        ON tn.label_default  = r.additional_fields->>fields.field_name
            AND tn.id_type = ref_nomenclatures.get_id_nomenclature_type(fields.code_nomenclature_type)
    ), con AS (
        SELECT tro.additional_fields - f.names  || d.n AS d, d.{id_field}
        FROM d
        JOIN pr_occtax.{table_name} tro
        ON tro.{id_field} = d.{id_field}
        JOIN (SELECT array_agg(field_name) names FROM fields) f ON true
        WHERE NOT tro.additional_fields IS NULL
    ) , final_data AS (
        SELECT a.{id_field},
            jsonb_object_agg(key, value) AS merged
        FROM (
            SELECT {id_field}, key, value
            FROM con
            CROSS JOIN LATERAL jsonb_each(con.d)
        ) as a
        JOIN ids
        ON a.{id_field} = ids.{id_field}
        GROUP BY a.{id_field}
    )
    UPDATE pr_occtax.{table_name} tro
        SET additional_fields = d.merged
    FROM final_data d
    WHERE d.{id_field} = tro.{id_field};
"""


def generate_downgrade(id_field, table_name, object_code):
    return f"""
    WITH ids AS (
        SELECT DISTINCT tro.id_releve_occtax , too.id_occurrence_occtax , cco.id_counting_occtax
        FROM pr_occtax.t_releves_occtax tro
        JOIN pr_occtax.t_occurrences_occtax too
        ON tro.id_releve_occtax = too.id_releve_occtax
        JOIN pr_occtax.cor_counting_occtax cco
        ON too.id_occurrence_occtax = cco.id_occurrence_occtax
        WHERE tro.meta_device_entry = 'web' OR tro.meta_device_entry IS NULL
    ), fields AS (
        SELECT taf.field_name, taf.code_nomenclature_type
        FROM gn_commons.t_additional_fields taf
        JOIN gn_commons.bib_widgets bw
        ON bw.id_widget = taf.id_widget
        JOIN gn_commons.cor_field_object cfo
        ON cfo.id_field = taf.id_field
        JOIN gn_permissions.t_objects t
        ON t.id_object = cfo.id_object
        WHERE bw.widget_name = 'nomenclature' AND t.code_object = '{object_code}'
    ), r AS (
        SELECT tro.{id_field} , tro.additional_fields ,  jsonb_object_keys(additional_fields) AS k
        FROM pr_occtax.{table_name} tro
        WHERE NOT tro.additional_fields IS NULL
    ), d AS (
        SELECT r.{id_field} ,
            jsonb_build_object(
            k,
            tn.label_default
            ) AS n
        FROM r
        JOIN fields ON fields.field_name = k
        LEFT JOIN ref_nomenclatures.t_nomenclatures tn
        ON tn.id_nomenclature::text = r.additional_fields->>fields.field_name
    ), new_value AS (SELECT {id_field},
            jsonb_object_agg(key, value) AS merged
        FROM (
            SELECT {id_field}, key, value
            FROM d
            CROSS JOIN LATERAL jsonb_each(d.n)
        ) as a
        GROUP BY {id_field}
        ), remove_key AS (
        SELECT tro.{id_field} , tro.additional_fields -  names as n_data
        FROM pr_occtax.{table_name} tro
        JOIN LATERAL (
            SELECT array_agg(jsonb_object_keys) names
                FROM jsonb_object_keys(additional_fields)  WHERE jsonb_object_keys ILIKE '_label_%'
            )  k
        ON true
        WHERE NOT tro.additional_fields IS NULL
    ) , final_data AS (
        SELECT r.{id_field} , n_data || merged  AS merged
        FROM remove_key r
        JOIN new_value n
        ON r.{id_field} = n.{id_field}
        JOIN ids
        ON r.{id_field} = ids.{id_field}
    )
    UPDATE pr_occtax.{table_name} tro
        SET additional_fields = d.merged
    FROM final_data d
    WHERE d.{id_field} = tro.{id_field};
    """
