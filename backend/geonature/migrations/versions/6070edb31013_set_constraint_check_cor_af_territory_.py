"""Set constraint check_cor_af_territory NOT VALID

Revision ID: 5b8f2929a18e
Revises: d80835fb13c8
Create Date: 2022-06-16 15:26:52.658472

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "6070edb31013"
down_revision = "d80835fb13c8"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_constraint(
        "check_cor_af_territory",
        table_name="cor_acquisition_framework_territory",
        schema="gn_meta",
    )

    op.execute(
        """
        ALTER TABLE gn_meta.cor_acquisition_framework_territory ADD CONSTRAINT check_cor_af_territory
            CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory, 'TERRITOIRE'::character varying))
        NOT VALID;
        """
    )


def downgrade():
    op.drop_constraint(
        "check_cor_af_territory",
        table_name="cor_acquisition_framework_territory",
        schema="gn_meta",
    )

    op.execute(
        """
        ALTER TABLE gn_meta.cor_acquisition_framework_territory ADD CONSTRAINT check_cor_af_territory
            CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory, 'TERRITOIRE'::character varying));
        """
    )
