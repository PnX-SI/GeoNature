"""Add id_entity in users errors

Revision ID: bfc90691737d
Revises: 2b0b3bd0248c
Create Date: 2024-02-15 16:20:57.049889

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "bfc90691737d"
down_revision = "02e9b8758709"
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
    op.drop_constraint(
        schema="gn_imports",
        table_name="t_user_errors",
        constraint_name="t_user_errors_un",
    )
    op.create_index(
        index_name="t_user_errors_un",
        schema="gn_imports",
        table_name="t_user_errors",
        columns=("id_import", "id_error", "column_error"),
        unique=True,
        postgresql_where="id_entity IS NULL",
    )
    op.create_index(
        index_name="t_user_errors_entity_un",
        schema="gn_imports",
        table_name="t_user_errors",
        columns=("id_import", "id_entity", "id_error", "column_error"),
        unique=True,
        postgresql_where="id_entity IS NOT NULL",
    )


def downgrade():
    op.drop_index(
        schema="gn_imports",
        table_name="t_user_errors",
        index_name="t_user_errors_entity_un",
    )
    op.drop_index(
        schema="gn_imports",
        table_name="t_user_errors",
        index_name="t_user_errors_un",
    )
    op.create_unique_constraint(
        constraint_name="t_user_errors_un",
        schema="gn_imports",
        table_name="t_user_errors",
        columns=("id_import", "id_error", "column_error"),
    )
    op.drop_constraint(
        schema="gn_imports",
        table_name="t_user_errors",
        constraint_name="t_user_errors_id_entity_fkey",
    )
    op.drop_column(schema="gn_imports", table_name="t_user_errors", column_name="id_entity")
