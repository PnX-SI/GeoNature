"""Make nom_cite mandatory in import

Revision ID: 5fe452b34a79
Revises: 65f77e9d4c6f
Create Date: 2025-03-24 12:30:24.820902

"""

from alembic import op
import sqlalchemy as sa
from geonature.core.imports.models import BibFields, Destination

# revision identifiers, used by Alembic.
revision = "5fe452b34a79"
down_revision = "b4e1e402ece1"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    t_bib_destinations = sa.Table(
        "bib_destinations", metadata, schema="gn_imports", autoload_with=conn
    )
    occhab_dest_id = conn.scalar(
        sa.select(t_bib_destinations.c.id_destination).where(t_bib_destinations.c.code == "occhab")
    )
    t_bib_fields = sa.Table("bib_fields", metadata, schema="gn_imports", autoload_with=conn)
    op.execute(
        sa.update(t_bib_fields)
        .where(
            t_bib_fields.c.name_field == "nom_cite", t_bib_fields.c.id_destination == occhab_dest_id
        )
        .values(
            mandatory=True,
        )
    )


def downgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    t_bib_destinations = sa.Table(
        "bib_destinations", metadata, schema="gn_imports", autoload_with=conn
    )
    occhab_dest_id = conn.scalar(
        sa.select(t_bib_destinations.c.id_destination).where(t_bib_destinations.c.code == "occhab")
    )
    t_bib_fields = sa.Table("bib_fields", metadata, schema="gn_imports", autoload_with=conn)
    op.execute(
        sa.update(t_bib_fields)
        .where(
            t_bib_fields.c.name_field == "nom_cite", t_bib_fields.c.id_destination == occhab_dest_id
        )
        .values(
            mandatory=False,
        )
    )
