"""fix_update_cd_hab_in_synthese

Revision ID: 8620acb59204
Revises: e29af5549eac
Create Date: 2023-04-05 15:31:49.623046

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8620acb59204"
down_revision = "e29af5549eac"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE gn_synthese.synthese s
        SET cd_hab =
            (
                SELECT cd_hab
                FROM pr_occtax.t_releves_occtax tro
                WHERE tro.unique_id_sinp_grp = s.unique_id_sinp_grp
            )
        FROM pr_occtax.t_releves_occtax tro
        WHERE tro.unique_id_sinp_grp = s.unique_id_sinp_grp
        AND tro.cd_hab IS DISTINCT FROM s.cd_hab 
        """
    )


def downgrade():
    pass
