"""add constraint to t_habitats.id_nomenclature_community_interest content type

Revision ID: fcf1e091b636
Revises: 167d69b42d25
Create Date: 2024-02-07 16:33:41.381934

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "fcf1e091b636"
down_revision = "167d69b42d25"
branch_labels = None
depends_on = None

table = "pr_occhab.t_habitats"
constraint = "check_t_habitats_community_interest"
check = "(ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_community_interest, 'HAB_INTERET_COM'::character varying))"


def upgrade():
    op.execute(
        f"""
        ALTER TABLE ONLY {table}
        ADD CONSTRAINT {constraint} CHECK {check} NOT VALID
        """
    )


def downgrade():
    op.execute(
        f"""
        ALTER TABLE {table}
        DROP CONSTRAINT {constraint};
        """
    )
