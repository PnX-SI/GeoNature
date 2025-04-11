"""invert count default

Revision ID: 43ecf0836b4a
Revises: e170d1902137
Create Date: 2024-01-23 09:36:40.189931

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "43ecf0836b4a"
down_revision = "e170d1902137"
branch_labels = None
depends_on = None


def upgrade():
    op.alter_column(
        "cor_counting_occtax",
        "id_nomenclature_sex",
        server_default=sa.func.pr_occtax.get_default_nomenclature_value("SEXE"),
        schema="pr_occtax",
    )
    op.alter_column(
        "cor_counting_occtax",
        "id_nomenclature_obj_count",
        server_default=sa.func.pr_occtax.get_default_nomenclature_value("OBJ_DENBR"),
        schema="pr_occtax",
    )


def downgrade():
    op.alter_column(
        "cor_counting_occtax",
        "id_nomenclature_sex",
        server_default=sa.func.pr_occtax.get_default_nomenclature_value("OBJ_DENBR"),
        schema="pr_occtax",
    )
    op.alter_column(
        "cor_counting_occtax",
        "id_nomenclature_obj_count",
        server_default=sa.func.pr_occtax.get_default_nomenclature_value("SEXE"),
        schema="pr_occtax",
    )
