"""set cascade on FK referencing sensitivity rules

Revision ID: 2d7edda45dd4
Revises: 4b5478df71cb
Create Date: 2022-11-25 12:58:47.583031

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "2d7edda45dd4"
down_revision = "4b5478df71cb"
branch_labels = None
depends_on = None


def replace_constraints(onupdate=None, ondelete=None):
    op.drop_constraint(
        "fk_cor_sensitivity_area_id_sensitivity_fkey",
        table_name="cor_sensitivity_area",
        schema="gn_sensitivity",
    )
    op.create_foreign_key(
        "fk_cor_sensitivity_area_id_sensitivity_fkey",
        source_schema="gn_sensitivity",
        source_table="cor_sensitivity_area",
        local_cols=["id_sensitivity"],
        referent_schema="gn_sensitivity",
        referent_table="t_sensitivity_rules",
        remote_cols=["id_sensitivity"],
        onupdate=onupdate,
        ondelete=ondelete,
    )

    op.drop_constraint(
        "criteria_id_sensitivity_fkey",
        table_name="cor_sensitivity_criteria",
        schema="gn_sensitivity",
    )
    op.create_foreign_key(
        "criteria_id_sensitivity_fkey",
        source_schema="gn_sensitivity",
        source_table="cor_sensitivity_criteria",
        local_cols=["id_sensitivity"],
        referent_schema="gn_sensitivity",
        referent_table="t_sensitivity_rules",
        remote_cols=["id_sensitivity"],
        onupdate=onupdate,
        ondelete=ondelete,
    )


def upgrade():
    op.create_index(
        "cor_sensitivity_area_id_sensitivity_idx",
        table_name="cor_sensitivity_area",
        columns=["id_sensitivity"],
        schema="gn_sensitivity",
    )
    op.create_index(
        "cor_sensitivity_criteria_id_sensitivity_idx",
        table_name="cor_sensitivity_criteria",
        columns=["id_sensitivity"],
        schema="gn_sensitivity",
    )
    replace_constraints("CASCADE", "CASCADE")


def downgrade():
    replace_constraints()
    op.drop_index(
        "cor_sensitivity_area_id_sensitivity_idx",
        table_name="cor_sensitivity_area",
        schema="gn_sensitivity",
    )
    op.drop_index(
        "cor_sensitivity_criteria_id_sensitivity_idx",
        table_name="cor_sensitivity_criteria",
        schema="gn_sensitivity",
    )
