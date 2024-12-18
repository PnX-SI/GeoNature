"""[monitoring] add id_import column for each entity

Revision ID: df277299fdda
Revises: 6734d8f7eb2a
Create Date: 2024-11-28 18:20:49.512808

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "df277299fdda"
down_revision = "a94bea44ab56"
branch_labels = None
depends_on = None

import_column_name = "id_import"
schema = "gn_monitoring"
entity_tables = ["t_base_sites", "t_base_visits", "t_observations"]


def upgrade():
    for table in entity_tables:
        op.add_column(
            schema=schema,
            table_name=table,
            column=sa.Column(import_column_name, sa.Integer, nullable=True),
        )


def downgrade():
    for table in entity_tables:
        op.drop_column(
            schema=schema,
            table_name=table,
            column_name=import_column_name,
        )
