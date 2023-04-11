"""correction-sql-on-delete-module

Revision ID: cf1c1fdbde77
Revises: 9e9218653d6c
Create Date: 2023-04-11 11:22:39.603084

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'cf1c1fdbde77'
down_revision = '9e9218653d6c'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        DELETE FROM gn_permissions.cor_role_action_filter_module_object cr WHERE NOT EXISTS (SELECT NULL FROM gn_commons.t_modules m WHERE cr.id_module = m.id_module); 
    """
    )
    op.execute(
        """
        ALTER TABLE gn_permissions.cor_role_action_filter_module_object DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_module;
        ALTER TABLE gn_permissions.cor_role_action_filter_module_object ADD CONSTRAINT fk_cor_r_a_f_m_o_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module) ON DELETE CASCADE;
    """
    )
    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_visits DROP CONSTRAINT IF EXISTS fk_t_base_visits_id_module;
        ALTER TABLE gn_monitoring.t_base_visits ADD CONSTRAINT fk_t_base_visits_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module) ON DELETE NO ACTION;
    """
    )
    op.execute(
        """
        ALTER TABLE gn_permissions.cor_filter_type_module DROP CONSTRAINT IF EXISTS fk_cor_filter_module_id_module;
        ALTER TABLE gn_permissions.cor_filter_type_module ADD CONSTRAINT fk_cor_filter_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module) ON DELETE CASCADE;
    """
    )
    op.execute(
        """
        ALTER TABLE gn_monitoring.cor_site_module DROP CONSTRAINT IF EXISTS fk_cor_site_module_id_module;
        ALTER TABLE gn_monitoring.cor_site_module ADD CONSTRAINT fk_cor_site_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules (id_module) ON UPDATE CASCADE ON DELETE CASCADE;
    """
    )


def downgrade():
    pass
