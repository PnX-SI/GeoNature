"""replace_is_complex_with_habitat_complexity

Revision ID: c1a6b0793360
Revises: 295861464d84
Create Date: 2024-07-18 15:52:38.695575

"""

from alembic import op
from gn_module_occhab.models import Station
from pypnnomenclature.models import TNomenclatures
import sqlalchemy as sa
from sqlalchemy.orm.session import Session


# revision identifiers, used by Alembic.
revision = "c1a6b0793360"
down_revision = "295861464d84"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "t_stations",
        sa.Column(
            "id_nomenclature_habitat_complexity",
            sa.Integer(),
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
        ),
        schema="pr_occhab",
    )
    session = Session(bind=op.get_bind())
    id_habitat_complexity_true = session.scalar(
        sa.select(TNomenclatures.id_nomenclature).where(
            TNomenclatures.mnemonique == "Mosaïque mixte"
        )
    )
    session.close()
    op.execute(
        sa.update(Station)
        .where(sa.text("pr_occhab.t_stations.is_habitat_complex = true"))
        .values(id_nomenclature_habitat_complexity=id_habitat_complexity_true)
    )
    op.drop_column("t_stations", "is_habitat_complex", schema="pr_occhab")
    op.execute(
        """
        ALTER TABLE pr_occhab.t_stations ADD CONSTRAINT 
        check_t_stations_habitat_complexity CHECK
        (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_habitat_complexity, 'MOSAIQUE_HAB'::character varying)) NOT VALID
        """
    )


def downgrade():
    op.drop_constraint("check_t_stations_habitat_complexity", "t_stations", schema="pr_occhab")
    op.drop_column("t_stations", "id_nomenclature_habitat_complexity", schema="pr_occhab")
    op.add_column(
        "t_stations",
        sa.Column("is_habitat_complex", sa.Boolean(), nullable=True),
        schema="pr_occhab",
    )
