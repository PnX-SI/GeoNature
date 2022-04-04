"""update synthese data (bug occtax trigger)

Revision ID: 944072911ff7
Revises: 494cb2245a43
Create Date: 2021-10-07 16:24:09.029496

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "944072911ff7"
down_revision = "494cb2245a43"
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
            JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
            WHERE NOT id_nomenclature_behaviour IS NULL
        ) sub
        WHERE s.unique_id_sinp_grp = sub.unique_id_sinp_grp
        """
    )


def downgrade():
    pass
