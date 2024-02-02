"""add id_module in pr_occtax.t_releves

Revision ID: 023b0be41829
Revises: 944072911ff7
Create Date: 2022-04-06 16:19:58.971694

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "023b0be41829"
down_revision = "22c2851bc387"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        "ALTER TABLE pr_occtax.t_releves_occtax DISABLE TRIGGER tri_update_synthese_t_releve_occtax"
    )
    op.execute(
        """
            ALTER TABLE pr_occtax.t_releves_occtax
            ADD column id_module integer;
            ALTER TABLE ONLY pr_occtax.t_releves_occtax 
                ADD CONSTRAINT fk_id_module FOREIGN KEY (id_module) 
                REFERENCES gn_commons.t_modules (id_module) ON UPDATE CASCADE; 
            UPDATE pr_occtax.t_releves_occtax
            SET id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX');
        """
    )
    op.execute(
        "ALTER TABLE pr_occtax.t_releves_occtax ENABLE TRIGGER tri_update_synthese_t_releve_occtax"
    )


def downgrade():
    op.execute(
        """
            ALTER TABLE pr_occtax.t_releves_occtax
            DROP column id_module;
        """
    )
