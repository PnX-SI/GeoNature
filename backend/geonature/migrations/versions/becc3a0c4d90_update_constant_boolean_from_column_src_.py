"""update constant boolean from column_src to constant_value in mappings

Revision ID: becc3a0c4d90
Revises: f59ccdee8f86
Create Date: 2025-03-26 15:32:24.939266

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "becc3a0c4d90"
down_revision = "f59ccdee8f86"
branch_labels = None
depends_on = None


KEYS = ["unique_id_sinp_generate", "altitudes_generate"]
VALUES = ["true", "false"]


def upgrade():
    for key in KEYS:
        for value in VALUES:
            op.execute(
                f"""
                UPDATE gn_imports.t_fieldmappings tf
                SET values =
                    (
                        SELECT json_object_agg(
                            key,
                            CASE
                                WHEN key = '{key}' THEN
                                    json_build_object('constant_value', {value})
                                ELSE
                                value
                            END
                        )
                        FROM json_each(values)
                    )
                WHERE
                    (values->>'{key}')::json->>'column_src' = '{value}';
                """
            )


def downgrade():
    for key in KEYS:
        for value in VALUES:
            op.execute(
                f"""
                UPDATE gn_imports.t_fieldmappings tf
                SET values =
                    (
                        SELECT json_object_agg(
                            key,
                            CASE
                                WHEN key = '{key}' THEN
                                    json_build_object('column_src', {value})
                                ELSE
                                value
                            END
                        )
                        FROM json_each(values)
                    )
                WHERE
                    (values->>'{key}')::json->>'constant_value' = '{value}';
                """
            )
