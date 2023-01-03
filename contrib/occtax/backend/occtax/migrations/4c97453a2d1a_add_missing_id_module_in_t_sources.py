"""add missing id module in t_sources

Revision ID: 4c97453a2d1a
Revises: df088920b2f3
Create Date: 2022-12-14 11:43:46.873045

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "4c97453a2d1a"
down_revision = "df088920b2f3"
branch_labels = None
depends_on = ("f4ffdc68072c",)  # add id_module column in t_sources


def upgrade():
    op.execute(
        """
        UPDATE gn_synthese.t_sources 
        SET id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX')
        WHERE name_source ILIKE 'Occtax'
        ;
        """
    )


def downgrade():
    pass
