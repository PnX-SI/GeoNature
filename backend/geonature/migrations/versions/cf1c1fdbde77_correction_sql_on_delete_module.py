"""correction-sql-on-delete-module

Revision ID: cf1c1fdbde77
Revises: 9e9218653d6c
Create Date: 2023-04-11 11:22:39.603084

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "cf1c1fdbde77"
down_revision = "9e9218653d6c"
branch_labels = None
depends_on = None


def upgrade():
    # Removing rows in 'cor_role_action_filter_module_object' which have non-valid values for 'id_module' field :
    #   values that are not in 'gn_commons.t_modules'
    op.execute(
        """
        DELETE
        FROM
        	gn_permissions.cor_role_action_filter_module_object cr
        WHERE
        	NOT EXISTS (
        	SELECT
        		NULL
        	FROM
        		gn_commons.t_modules m
        	WHERE
        		cr.id_module = m.id_module); 
    """
    )

    # Adding FK 'fk_cor_r_a_f_m_o_id_module'
    op.execute(
        """
        ALTER TABLE gn_permissions.cor_role_action_filter_module_object 
        ADD CONSTRAINT fk_cor_r_a_f_m_o_id_module FOREIGN KEY (id_module) 
        REFERENCES gn_commons.t_modules (id_module) 
        ON DELETE CASCADE
        ON UPDATE CASCADE; 
    """
    )

    # Modifying FK 'fk_t_base_visits_id_module'
    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_visits 
        DROP CONSTRAINT fk_t_base_visits_id_module;
        ALTER TABLE gn_monitoring.t_base_visits 
        ADD CONSTRAINT fk_t_base_visits_id_module FOREIGN KEY (id_module) 
        REFERENCES gn_commons.t_modules (id_module) 
        ON DELETE NO ACTION -- previously 'ON DELETE CASCADE'
        ON UPDATE CASCADE;  -- previously 'ON UPDATE CASCADE'
    """
    )

    # Modifying FK 'fk_cor_filter_module_id_module'
    op.execute(
        """
        ALTER TABLE gn_permissions.cor_filter_type_module 
        DROP CONSTRAINT fk_cor_filter_module_id_module;
        ALTER TABLE gn_permissions.cor_filter_type_module 
        ADD CONSTRAINT fk_cor_filter_module_id_module FOREIGN KEY (id_module) 
        REFERENCES gn_commons.t_modules (id_module) 
        ON DELETE CASCADE   -- previously 'ON DELETE NO ACTION'
        ON UPDATE CASCADE;  -- previously 'ON UPDATE CASCADE'
    """
    )

    # Modifying FK 'fk_cor_site_module_id_module'
    op.execute(
        """
        ALTER TABLE gn_monitoring.cor_site_module 
        DROP CONSTRAINT fk_cor_site_module_id_module;
        ALTER TABLE gn_monitoring.cor_site_module 
        ADD CONSTRAINT fk_cor_site_module_id_module FOREIGN KEY (id_module) 
        REFERENCES gn_commons.t_modules (id_module) 
        ON DELETE CASCADE   -- previously 'ON DELETE NO ACTION'
        ON UPDATE CASCADE;  -- previously 'ON DELETE NO ACTION'
    """
    )


def downgrade():
    # Removing FK 'fk_cor_r_a_f_m_o_id_module'
    op.execute(
        """
        ALTER TABLE gn_permissions.cor_role_action_filter_module_object 
        DROP CONSTRAINT fk_cor_r_a_f_m_o_id_module;
    """
    )

    # Modifying back FK 'fk_t_base_visits_id_module'
    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_visits 
        DROP CONSTRAINT fk_t_base_visits_id_module;
        ALTER TABLE gn_monitoring.t_base_visits 
        ADD CONSTRAINT fk_t_base_visits_id_module FOREIGN KEY (id_module) 
        REFERENCES gn_commons.t_modules (id_module) 
        ON DELETE CASCADE
        ON UPDATE CASCADE;
    """
    )

    # Modifying back FK 'fk_cor_filter_module_id_module'
    op.execute(
        """
        ALTER TABLE gn_permissions.cor_filter_type_module 
        DROP CONSTRAINT fk_cor_filter_module_id_module;
        ALTER TABLE gn_permissions.cor_filter_type_module 
        ADD CONSTRAINT fk_cor_filter_module_id_module FOREIGN KEY (id_module) 
        REFERENCES gn_commons.t_modules (id_module) 
        ON DELETE NO ACTION
        ON UPDATE CASCADE;
    """
    )

    # Modifying back FK 'fk_cor_site_module_id_module'
    op.execute(
        """
        ALTER TABLE gn_monitoring.cor_site_module 
        DROP CONSTRAINT fk_cor_site_module_id_module;
        ALTER TABLE gn_monitoring.cor_site_module 
        ADD CONSTRAINT fk_cor_site_module_id_module FOREIGN KEY (id_module) 
        REFERENCES gn_commons.t_modules (id_module) 
        ON DELETE NO ACTION
        ON UPDATE NO ACTION;
    """
    )
