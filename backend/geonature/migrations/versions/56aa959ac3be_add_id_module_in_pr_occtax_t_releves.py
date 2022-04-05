"""add id_module in pr_occtax.t_releves

Revision ID: 56aa959ac3be
Revises: 42040535a20e
Create Date: 2022-04-05 17:36:54.528861

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "56aa959ac3be"
down_revision = "42040535a20e"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
            ALTER TABLE pr_occtax.t_releves_occtax
            ADD column id_module integer;
            ALTER TABLE ONLY pr_occtax.t_releves_occtax 
                ADD CONSTRAINT fk_id_module FOREIGN KEY (id_module) 
                REFERENCES gn_commons.t_modules (id_module) ON UPDATE CASCADE; 
        """
    )


def downgrade():
    op.execute(
        """
            ALTER TABLE pr_occtax.t_releves_occtax
            DROP column id_module;
        """
    )
