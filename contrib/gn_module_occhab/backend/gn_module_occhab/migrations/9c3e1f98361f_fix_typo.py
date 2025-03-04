"""fix_typo

Revision ID: 9c3e1f98361f
Revises: c1a6b0793360
Create Date: 2025-01-20 16:09:12.490217

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9c3e1f98361f"
down_revision = "c1a6b0793360"
branch_labels = None
depends_on = None

OLD_NAME_MAPPING = "Occhab"
NEW_NAME_MAPPING = "Occhab GeoNature"


def get_table():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    bib_fields = sa.Table("bib_fields", metadata, schema="gn_imports", autoload_with=op.get_bind())
    destinations = sa.Table(
        "bib_destinations", metadata, schema="gn_imports", autoload_with=op.get_bind()
    )
    t_mappings = sa.Table("t_mappings", metadata, schema="gn_imports", autoload_with=op.get_bind())
    return bib_fields, destinations, t_mappings


def get_id_dest_occhab():
    _, destinations, _ = get_table()
    id_destination_occhab = (
        op.get_bind()
        .execute(sa.select(destinations.c.id_destination).where(destinations.c.code == "occhab"))
        .scalar()
    )
    return id_destination_occhab


def upgrade():
    bib_fields, destinations, t_mappings = get_table()
    op.execute(
        sa.update(bib_fields)
        .where(
            bib_fields.c.name_field == "depth_max",
            bib_fields.c.id_destination == get_id_dest_occhab(),
        )
        .values(dest_field="depth_max")
    )

    op.execute(
        sa.update(t_mappings)
        .where(t_mappings.c.label == OLD_NAME_MAPPING)
        .values(label=NEW_NAME_MAPPING)
    )


def downgrade():
    bib_fields, _, t_mappings = get_table()
    op.execute(
        sa.update(bib_fields)
        .where(
            bib_fields.c.name_field == "depth_max",
            bib_fields.c.id_destination == get_id_dest_occhab(),
        )
        .values(dest_field="depth_min")
    )
    op.execute(
        sa.update(t_mappings)
        .where(t_mappings.c.label == NEW_NAME_MAPPING)
        .values(label=OLD_NAME_MAPPING)
    )
