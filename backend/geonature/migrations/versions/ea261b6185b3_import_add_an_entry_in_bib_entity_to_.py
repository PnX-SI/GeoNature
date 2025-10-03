"""[import] Add an entry in bib_entity to indicate the uuid name

Revision ID: ea261b6185b3
Revises: 33881d849b2b
Create Date: 2025-08-14 11:45:48.936704

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "ea261b6185b3"
down_revision = "33881d849b2b"
branch_labels = None
depends_on = None

data = [
    ("unique_id_sinp_station", "station", "occhab"),
    ("unique_id_sinp_habitat", "habitat", "occhab"),
    ("unique_id_sinp", "observation", "synthese"),
]


def upgrade():
    op.add_column(
        "bib_entities",
        sa.Column(
            "id_uuid_column",
            sa.Integer,
            sa.ForeignKey("gn_imports.bib_fields.id_field"),
            nullable=True,
        ),
        schema="gn_imports",
    )
    for name_field, entity_code, dest_code in data:
        op.execute(
            f"""
        with destinations as (select dest.id_destination as id_dest
        from gn_imports.bib_destinations dest
        where dest.code = '{dest_code}')
        UPDATE gn_imports.bib_entities ent
        set id_uuid_column = field.id_field
        from gn_imports.bib_fields field, destinations
        where field.name_field = '{name_field}' and ent.code = '{entity_code}' and ent.id_destination  = destinations.id_dest;

    """
        )


def downgrade():
    op.drop_column("bib_entities", "id_uuid_column", schema="gn_imports")
