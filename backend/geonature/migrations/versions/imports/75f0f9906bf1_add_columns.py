"""add_columns

Revision ID: 75f0f9906bf1
Revises: 2ed6a7ee5250
Create Date: 2021-04-27 10:02:53.798753

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.types import ARRAY


# revision identifiers, used by Alembic.
revision = "75f0f9906bf1"
down_revision = "2ed6a7ee5250"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        table_name="t_imports",
        column=sa.Column(
            "columns",
            ARRAY(sa.Unicode),
        ),
        schema="gn_imports",
    )
    op.execute(
        """
        UPDATE gn_imports.t_user_error_list
        SET id_rows = ARRAY(SELECT generate_series(1, gn_imports.t_imports.source_count))
        FROM gn_imports.t_imports
        WHERE
            gn_imports.t_user_error_list.id_import = gn_imports.t_imports.id_import
            AND gn_imports.t_user_error_list.id_rows=ARRAY['ALL'];
        """
    )
    op.execute(
        """
        ALTER TABLE gn_imports.t_user_error_list
        ALTER COLUMN id_rows TYPE integer[] USING id_rows::integer[]
    """
    )
    op.drop_column(
        table_name="t_mappings_fields",
        column_name="is_added",
        schema="gn_imports",
    )
    op.drop_column(
        table_name="t_mappings_fields",
        column_name="is_selected",
        schema="gn_imports",
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_imports.t_mappings_fields
        ADD COLUMN is_selected BOOLEAN NOT NULL DEFAULT TRUE
    """
    )
    op.execute(
        """
        ALTER TABLE gn_imports.t_mappings_fields
        ADD COLUMN is_added BOOLEAN NOT NULL DEFAULT FALSE
    """
    )
    op.execute(
        """
        ALTER TABLE gn_imports.t_user_error_list
        ALTER COLUMN id_rows TYPE text[] USING id_rows::text[]
    """
    )
    op.drop_column(
        table_name="t_imports",
        column_name="columns",
        schema="gn_imports",
    )
