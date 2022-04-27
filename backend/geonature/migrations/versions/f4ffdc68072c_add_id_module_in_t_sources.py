"""add id_module in t_sources

Revision ID: f4ffdc68072c
Revises: 3902129a52b3
Create Date: 2022-04-27 13:42:51.851067

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f4ffdc68072c"
down_revision = "3902129a52b3"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        ALTER TABLE gn_synthese.t_sources
        ADD COLUMN id_module integer;
        ALTER TABLE gn_synthese.t_sources
        ADD CONSTRAINT fk_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module);
        UPDATE gn_synthese.t_sources
        SET id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX')
        WHERE name_source ILIKE 'occtax%';
        """
    )


def downgrade():
    op.execute(
        """
        ALTER TABLE gn_synthese.t_sources
        DROP COLUMN id_module;
        """
    )
