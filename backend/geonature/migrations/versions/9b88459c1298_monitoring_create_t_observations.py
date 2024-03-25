"""[monitoring] create t_observations

Revision ID: 9b88459c1298
Revises: a54bafb13ce8
Create Date: 2024-01-16 15:41:13.331912

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9b88459c1298"
down_revision = "a54bafb13ce8"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE TABLE IF NOT EXISTS gn_monitoring.t_observations (
                id_observation SERIAL NOT NULL,
                id_base_visit INTEGER NOT NULL,
                cd_nom INTEGER NOT NULL,
                comments TEXT,
                uuid_observation UUID DEFAULT uuid_generate_v4() NOT NULL,


                CONSTRAINT pk_t_observations PRIMARY KEY (id_observation),
                CONSTRAINT fk_t_observations_id_base_visit FOREIGN KEY (id_base_visit)
                    REFERENCES gn_monitoring.t_base_visits (id_base_visit) MATCH SIMPLE
                    ON UPDATE CASCADE ON DELETE CASCADE
            );
    """
    )
    op.execute(
        """
        INSERT INTO gn_commons.bib_tables_location(table_desc, schema_name, table_name, pk_field, uuid_field_name)
        VALUES
        ('Table centralisant les observations réalisées lors d''une visite sur un site', 'gn_monitoring', 't_observations', 'id_observation', 'uuid_observation')
        ON CONFLICT(schema_name, table_name) DO NOTHING;
        """
    )


def downgrade():
    op.execute(
        """
        DELETE FROM gn_commons.bib_tables_location
        WHERE schema_name = 'gn_monitoring' AND table_name = 't_observations';
        """
    )
    op.drop_table("t_observations", schema="gn_monitoring")
