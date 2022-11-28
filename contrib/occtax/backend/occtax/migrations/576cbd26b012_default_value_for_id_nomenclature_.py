"""default value for id_nomenclature_observations_status

Revision ID: 576cbd26b012
Revises: 9624348fea40
Create Date: 2022-11-02 10:45:57.851612

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "576cbd26b012"
down_revision = "9624348fea40"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE pr_occtax.t_occurrences_occtax  
        SET id_nomenclature_observation_status = (
            SELECT id_nomenclature FROM pr_occtax.defaults_nomenclatures_value def WHERE  def.mnemonique_type = 'STATUT_OBS'
        )
        WHERE id_nomenclature_observation_status IS NULL;  
        """
    )


def downgrade():
    pass
