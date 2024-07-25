"""[monitoring] create cor_sites_group_module

Revision ID: 33b385368af3
Revises: 6734d8f7eb2a
Create Date: 2024-07-23 15:44:16.973789

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "33b385368af3"
down_revision = "6734d8f7eb2a"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    CREATE TABLE gn_monitoring.cor_sites_group_module (
        id_site_group int4 NOT NULL,
        id_module int4 NOT NULL,
        CONSTRAINT pk_cor_sites_group_module PRIMARY KEY (id_site_group, id_module),
        CONSTRAINT fk_cor_sites_group_module_id_site_group FOREIGN KEY (id_site_group) REFERENCES gn_monitoring.t_sites_groups(id_sites_group) ON DELETE CASCADE ON UPDATE CASCADE,
        CONSTRAINT fk_cor_sites_group_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON DELETE CASCADE ON UPDATE CASCADE
    );
    """
    )


def downgrade():
    op.execute(
        """
    DROP TABLE gn_monitoring.cor_sites_group_module;
    """
    )
