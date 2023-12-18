"""set id_module on import sources

Revision ID: 65defbe5027b
Revises: f394a5edcb56
Create Date: 2022-07-05 18:09:53.133560

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "65defbe5027b"
down_revision = "f394a5edcb56"
branch_labels = None
depends_on = ("f4ffdc68072c",)  # add id_module in t_sources


def upgrade():
    op.execute(
        """
    UPDATE
        gn_synthese.t_sources
    SET
        id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'IMPORT')
    WHERE
        name_source LIKE 'Import(id=%)'
    """
    )


def downgrade():
    op.execute(
        """
    UPDATE
        gn_synthese.t_sources
    SET
        id_module = NULL
    WHERE
        id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'IMPORT')
    """
    )
