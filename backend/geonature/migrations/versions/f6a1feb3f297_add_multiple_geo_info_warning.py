"""[import] add MULTIPLE_GEO_INFO_WARNING error type

Revision ID: f6a1feb3f297
Revises: cb663f039774
Create Date: 2026-04-23 10:00:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.schema import Table, MetaData

# revision identifiers, used by Alembic.
revision = "f6a1feb3f297"
down_revision = "cb663f039774"
branch_labels = None
depends_on = None


def upgrade():
    metadata = MetaData(bind=op.get_bind())
    bib_errors_types = Table("bib_errors_types", metadata, schema="gn_imports", autoload=True)
    op.execute(
        sa.insert(bib_errors_types).values(
            error_type="Géometrie",
            name="MULTIPLE_GEO_INFO_WARNING",
            description=(
                "Plusieurs informations de géoreferencement ont été remplies pour une même ligne. "
                "La plus précise a été selectionée automatiquement selon cette ordre de priorité : "
                "WKT > longitude/latitude > Maille > Commune > Departement"
            ),
            error_level="WARNING",
        )
    )


def downgrade():
    metadata = MetaData(bind=op.get_bind())
    bib_errors_types = Table("bib_errors_types", metadata, schema="gn_imports", autoload=True)
    op.execute(
        sa.delete(bib_errors_types).where(bib_errors_types.c.name == "MULTIPLE_GEO_INFO_WARNING")
    )
