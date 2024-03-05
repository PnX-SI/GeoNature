"""[monitoring] add multi observers to sites

Revision ID: 058fe92948df
Revises: 6734d8f7eb2a
Create Date: 2024-03-05 11:23:26.083757

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "058fe92948df"
down_revision = "6734d8f7eb2a"
branch_labels = None
depends_on = None


def upgrade():

    op.execute(
        """
    CREATE TABLE gn_monitoring.cor_site_observer (
        id_base_site integer NOT NULL,
        id_role integer NOT NULL,
        unique_id_core_site_observer uuid  NOT NULL DEFAULT public.uuid_generate_v4()
    );
        """
    )

    op.execute(
        """
    ALTER TABLE ONLY gn_monitoring.cor_site_observer
    ADD CONSTRAINT pk_cor_site_observer PRIMARY KEY (id_base_site, id_role);
        """
    )

    op.execute(
        """
    ALTER TABLE ONLY gn_monitoring.cor_site_observer
    ADD CONSTRAINT fk_cor_site_observer_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites (id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;
        """
    )

    op.execute(
        """
    ALTER TABLE ONLY gn_monitoring.cor_site_observer
    ADD CONSTRAINT fk_cor_site_observer_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles (id_role) ON UPDATE CASCADE;
        """
    )


def downgrade():
    op.execute(
        """
        DROP TABLE gn_monitoring.cor_site_observer;
        """
    )
