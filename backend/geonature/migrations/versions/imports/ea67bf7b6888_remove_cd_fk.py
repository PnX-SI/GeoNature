"""remove cd fk

Revision ID: ea67bf7b6888
Revises: d6bf8eaf088c
Create Date: 2023-09-27 15:37:19.286693

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "ea67bf7b6888"
down_revision = "d6bf8eaf088c"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_constraint(
        schema="gn_imports",
        table_name="t_imports_synthese",
        constraint_name="t_imports_synthese_cd_nom_fkey",
    )
    op.drop_constraint(
        schema="gn_imports",
        table_name="t_imports_synthese",
        constraint_name="t_imports_synthese_cd_hab_fkey",
    )


def downgrade():
    op.create_foreign_key(
        constraint_name="t_imports_synthese_cd_nom_fkey",
        source_schema="gn_imports",
        source_table="t_imports_synthese",
        local_cols=["cd_nom"],
        referent_schema="taxonomie",
        referent_table="taxref",
        remote_cols=["cd_nom"],
    )
    op.create_foreign_key(
        constraint_name="t_imports_synthese_cd_hab_fkey",
        source_schema="gn_imports",
        source_table="t_imports_synthese",
        local_cols=["cd_hab"],
        referent_schema="ref_habitats",
        referent_table="habref",
        remote_cols=["cd_hab"],
    )
