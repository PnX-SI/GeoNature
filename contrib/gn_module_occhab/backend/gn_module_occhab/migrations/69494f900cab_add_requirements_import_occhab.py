"""add_requirements_import_occhab

Revision ID: 69494f900cab
Revises: fcf1e091b636
Create Date: 2024-06-19 14:54:51.374462

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "69494f900cab"
down_revision = "295861464d84"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    meta = sa.MetaData(bind=conn)
    destination = sa.Table("bib_destinations", meta, autoload_with=conn, schema="gn_imports")
    id_dest_occhab = (
        op.get_bind()
        .execute(sa.select([destination.c.id_destination]).where(destination.c.code == "occhab"))
        .scalar()
    )
    field = sa.Table("bib_fields", meta, autoload_with=conn, schema="gn_imports")

    inter_fields_conditions = [
        ["id_station_source", dict(optional_conditions=["unique_id_sinp_station"], mandatory=True)],
        ["unique_id_sinp_station", dict(optional_conditions=["id_station_source"], mandatory=True)],
        ["WKT", dict(optional_conditions=["longitude", "latitude"], mandatory=True)],
        [
            "latitude",
            dict(mandatory_conditions=["longitude"], optional_conditions=["WKT"], mandatory=True),
        ],
        [
            "longitude",
            dict(mandatory_conditions=["latitude"], optional_conditions=["WKT"], mandatory=True),
        ],
        ["altitude_min", dict(mandatory_conditions=["altitude_max"], mandatory=False)],
        ["depth_min", dict(mandatory_conditions=["depth_max"], mandatory=False)],
    ]
    for name_field, update_values in inter_fields_conditions:
        op.execute(
            sa.update(field)
            .where(field.c.name_field == name_field, field.c.id_destination == id_dest_occhab)
            .values(**update_values)
        )


def downgrade():
    pass
