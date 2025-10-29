"""[import] set uuid_column id in station and habitat entities

Revision ID: 6f0ac37e9bc4
Revises: 832b55d40a2c
Create Date: 2025-10-29 14:50:03.076396

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "6f0ac37e9bc4"
down_revision = "832b55d40a2c"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE gn_imports.bib_entities
        set id_uuid_column = (select id_field from gn_imports.bib_fields where name_field = 'unique_id_sinp_station'
            and id_destination = (select id_destination from gn_imports.bib_destinations where code = 'occhab'))
        where code = 'station'
        """
    )
    op.execute(
        """
        UPDATE gn_imports.bib_entities
        set id_uuid_column = (select id_field from gn_imports.bib_fields where name_field = 'unique_id_sinp_habitat'
          and id_destination = (select id_destination from gn_imports.bib_destinations where code = 'occhab'))
        where code = 'habitat'
        """
    )


def downgrade():
    op.execute(
        """
        UPDATE gn_imports.bib_entities
        set id_uuid_column = null
        where code in ('station', 'habitat')
        """
    )
