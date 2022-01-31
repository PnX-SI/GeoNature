"""Add id_module in pr_occtacax.t_releves

Revision ID: 86d48653a07b
Revises: 0d89c5978fa2
Create Date: 2022-01-31 12:24:11.746349

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '86d48653a07b'
down_revision = '0d89c5978fa2'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        AlTER TABLE pr_occtax.t_releves_occtax 
        ADD COLUMN id_module integer;
        AlTER TABLE pr_occtax.t_releves_occtax 
        ADD CONSTRAINT fk_t_releves_occtax_id_module FOREIGN KEY (id_module)
        REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE
        """
    )
    op.execute(
    """
        UPDATE pr_occtax.t_releves_occtax 
        SET id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX')
    """
    )

def downgrade():
    op.execute(
    """
        AlTER TABLE pr_occtax.t_releves_occtax 
        DROP COLUMN id_module
    """
    )