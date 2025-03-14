"""fieldmapping default values

Revision ID: e43b01a18850
Revises: 5cf0ce9e669c
Create Date: 2024-11-28 17:33:06.243150

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "e43b01a18850"
down_revision = "4e6ce32305f0"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """UPDATE gn_imports.t_fieldmappings 
        SET "values" = (
            SELECT json_object_agg(key, json_build_object('column_src', value))
            FROM json_each("values")
        )
        WHERE "values" IS NOT NULL;"""
    )
    op.execute(
        """UPDATE gn_imports.t_imports
        SET fieldmapping = (
            SELECT json_object_agg(key, json_build_object('column_src', value))
            FROM json_each(fieldmapping)
        )
        WHERE fieldmapping IS NOT NULL;"""
    )


def downgrade():
    op.execute(
        """UPDATE gn_imports.t_fieldmappings
        SET "values" = (
            SELECT json_object_agg(key, value->'column_src')
            FROM json_each("values")
        )
        WHERE "values" IS NOT NULL;"""
    )
    op.execute(
        """UPDATE gn_imports.t_imports
        SET fieldmapping = (
            SELECT json_object_agg(key, value->'column_src')
            FROM json_each(fieldmapping)
        )
        WHERE fieldmapping IS NOT NULL;"""
    )
