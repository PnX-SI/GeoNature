"""add_requirements_import_occhab

Revision ID: 69494f900cab
Revises: fcf1e091b636
Create Date: 2024-06-19 14:54:51.374462

"""

from alembic import op
import sqlalchemy as sa
from geonature.core.imports.models import BibFields, Destination
from sqlalchemy.orm.session import Session


# revision identifiers, used by Alembic.
revision = "69494f900cab"
down_revision = "fcf1e091b636"
branch_labels = None
depends_on = None


def upgrade():
    session = Session(bind=op.get_bind())
    occhab_dest_id = session.scalar(
        sa.select(Destination.id_destination).where(Destination.code == "occhab")
    )
    session.close()

    inter_fields_conditions = [
        ["id_station_source", dict(optional_conditions=["unique_id_sinp_station"], mandatory=True)],
        ["unique_id_sinp_station", dict(optional_conditions=["id_station_source"], mandatory=True)],
        ["WKT", dict(optional_conditions=["longitude", "latitude"], mandatory=True)],
    ]
    for name_field, update_values in inter_fields_conditions:
        op.execute(
            sa.update(BibFields)
            .where(BibFields.name_field == name_field, BibFields.id_destination == occhab_dest_id)
            .values(**update_values)
        )


def downgrade():
    pass
