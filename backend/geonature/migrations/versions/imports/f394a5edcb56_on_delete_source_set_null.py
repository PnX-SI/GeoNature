"""on delete source set null

Revision ID: f394a5edcb56
Revises: 0ff8fc0b4233
Create Date: 2022-06-22 11:40:05.678227

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f394a5edcb56"
down_revision = "5c31e356cedc"
branch_labels = None
depends_on = None


def replace_constraint(ondelete):
    op.drop_constraint(
        constraint_name="fk_gn_imports_t_import_id_source_synthese",
        schema="gn_imports",
        table_name="t_imports",
    )
    op.create_foreign_key(
        constraint_name="fk_gn_imports_t_import_id_source_synthese",
        source_schema="gn_imports",
        source_table="t_imports",
        local_cols=["id_source_synthese"],
        referent_schema="gn_synthese",
        referent_table="t_sources",
        remote_cols=["id_source"],
        onupdate="CASCADE",
        ondelete=ondelete,
    )


def upgrade():
    replace_constraint(ondelete="SET NULL")


def downgrade():
    replace_constraint(ondelete="CASCADE")
