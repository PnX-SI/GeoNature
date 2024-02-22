"""Add id_entity in users errors

Revision ID: bfc90691737d
Revises: 2b0b3bd0248c
Create Date: 2024-02-15 16:20:57.049889

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "bfc90691737d"
down_revision = "2b0b3bd0248c"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_user_errors",
        column=sa.Column(
            "id_entity",
            sa.Integer,
        ),
    )
    op.create_foreign_key(
        constraint_name="t_user_errors_id_entity_fkey",
        source_schema="gn_imports",
        source_table="t_user_errors",
        local_cols=["id_entity"],
        referent_schema="gn_imports",
        referent_table="bib_entities",
        remote_cols=["id_entity"],
        onupdate="CASCADE",
        ondelete="CASCADE",
    )
    pass


def downgrade():
    op.drop_constraint(
        schema="gn_imports",
        table_name="t_user_errors",
        constraint_name="t_user_errors_id_entity_fkey",
    )
    op.drop_column(schema="gn_imports", table_name="t_user_errors", column_name="id_entity")
    pass
