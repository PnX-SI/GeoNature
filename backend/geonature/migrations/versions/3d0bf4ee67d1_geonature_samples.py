"""geonature samples

Revision ID: 3d0bf4ee67d1
Create Date: 2021-09-27 18:00:45.818766

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "3d0bf4ee67d1"
down_revision = None
branch_labels = ("geonature-samples",)
depends_on = ("geonature",)


def upgrade():
    op.execute(
        """
    INSERT INTO gn_meta.sinp_datatype_protocols (
         unique_protocol_id,
         protocol_name,
         protocol_desc,
         id_nomenclature_protocol_type,
         protocol_url)
    VALUES (
        '9ed37cb1-803b-4eec-9ecd-31880475bbe9',
        'hors protocole',
        'observation réalisées hors protocole',
        ref_nomenclatures.get_id_nomenclature('TYPE_PROTOCOLE','1'),
        null)
    """
    )


def downgrade():
    op.execute(
        """
    DELETE FROM gn_meta.sinp_datatype_protocols
    WHERE unique_protocol_id = '9ed37cb1-803b-4eec-9ecd-31880475bbe9'
    """
    )
