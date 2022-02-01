"""Add id_module in gn_commons.t_source

Revision ID: 31f4fab360c1
Revises: 30edd97ae582
Create Date: 2022-01-31 12:15:41.714849

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '31f4fab360c1'
down_revision = '30edd97ae582'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
    """
        ALTER TABLE gn_synthese.t_sources 
        ADD COLUMN id_module integer;
        ALTER TABLE gn_synthese.t_sources 
        ADD CONSTRAINT fk_t_sources_id_module FOREIGN KEY (id_module)
        REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE
    """
    )
    op.execute(
    """
        UPDATE gn_synthese.t_sources s
        SET id_module = (SELECT id_module FROM gn_synthese.synthese WHERE id_source = s.id_source LIMIT 1)
    """
    )


def downgrade():
    op.execute(
    """
        AlTER TABLE gn_synthese.t_sources 
        DROP COLUMN id_module 
    """
    )