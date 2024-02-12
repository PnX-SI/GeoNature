"""Remove gn_export.t_config_exports

Revision ID: 30edd97ae582
Revises: dde31e76ce45
Create Date: 2022-01-21 10:51:15.288875

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.exc import InternalError
from psycopg2.errors import DependentObjectsStillExist

# revision identifiers, used by Alembic.
revision = "30edd97ae582"
down_revision = "dde31e76ce45"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        DROP TABLE IF EXISTS gn_exports.t_config_export;
    """
    )

    op.execute(
        """
        DO $$
        BEGIN
            DROP SCHEMA IF EXISTS gn_exports;
        EXCEPTION
            WHEN dependent_objects_still_exist THEN RAISE INFO 'Dependent objects in gn_exports';
        END;
        $$
    """
    )


def downgrade():
    pass
