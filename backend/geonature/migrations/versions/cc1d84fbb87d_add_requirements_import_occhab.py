"""add_requirements_import_occhab

Revision ID: cc1d84fbb87d
Revises: 0e8e1943c215
Create Date: 2024-05-29 10:04:08.070925

"""

from alembic import op
import sqlalchemy as sa
from geonature.core.imports.models import BibFields, Destination
from sqlalchemy.orm.session import Session


# revision identifiers, used by Alembic.
revision = "cc1d84fbb87d"
down_revision = "0e8e1943c215"
branch_labels = None
depends_on = "2b0b3bd0248c"


def upgrade():
    session = Session(bind=op.get_bind())
    occhab_dest_id = session.scalar(
        sa.select(Destination.id_destination).where(Destination.code == "occhab")
    )

    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "id_station_source", BibFields.id_destination == occhab_dest_id
        )
        .values(optional_conditions=["unique_id_sinp_station"], mandatory=True)
    )
    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "unique_id_sinp_station",
            BibFields.id_destination == occhab_dest_id,
        )
        .values(optional_conditions=["id_station_source"], mandatory=True)
    )

    op.execute(
        sa.update(BibFields)
        .where(
            BibFields.name_field == "WKT",
            BibFields.id_destination == occhab_dest_id,
        )
        .values(optional_conditions=["longitude", "latitude"], mandatory=True)
    )

    session.close()


def downgrade():
    pass
