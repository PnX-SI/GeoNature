"""clean synthese data (bug in occtax trigger)

Revision ID: 6b11f29dc1b5
Revises: 5f4c4b644844
Create Date: 2021-10-07 16:09:57.024876

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '6b11f29dc1b5'
down_revision = '5f4c4b644844'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE gn_synthese.synthese s
        SET id_nomenclature_behaviour = sub.id_nomenclature_behaviour
        FROM (
            SELECT occ.id_nomenclature_behaviour, rel.unique_id_sinp_grp
            FROM pr_occtax.t_releves_occtax rel 
            JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = occ.id_releve_occtax
        ) sub
        WHERE s.unique_id_sinp_grp = sub.unique_id_sinp_grp
        """
    )


def downgrade():
    pass
