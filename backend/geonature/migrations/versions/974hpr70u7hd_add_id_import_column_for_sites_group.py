"""[monitoring] add id_import column for sites group

Revision ID: 974hpr70u7hd
Revises: c3db57568f88
Create Date: 2026-02-11 16:00:05.425708

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "974hpr70u7hd"
down_revision = "c3db57568f88"
branch_labels = None
depends_on = None

import_column_name = "id_import"
schema = "gn_monitoring"
table = "t_sites_groups"


def upgrade():
    op.add_column(
        schema=schema,
        table_name=table,
        column=sa.Column(import_column_name, sa.Integer, nullable=True),
    )


def downgrade():
    op.drop_column(
        schema=schema,
        table_name=table,
        column_name=import_column_name,
    )
