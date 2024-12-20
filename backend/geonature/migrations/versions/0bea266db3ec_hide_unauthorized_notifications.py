"""hide unauthorized notifications categories

Revision ID: 0bea266db3ec
Revises: 7b6a578eccd7
Create Date: 2024-11-20 17:23:42.017660

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import column


# revision identifiers, used by Alembic.
revision = "0bea266db3ec"
down_revision = "7b6a578eccd7"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_notifications",
        table_name="bib_notifications_categories",
        column=sa.Column(
            "id_module",
            sa.Integer,
            sa.ForeignKey("gn_commons.t_modules.id_module"),
        ),
    )
    op.add_column(
        schema="gn_notifications",
        table_name="bib_notifications_categories",
        column=sa.Column(
            "id_object",
            sa.Integer,
            sa.ForeignKey("gn_permissions.t_objects.id_object"),
        ),
    )
    op.add_column(
        schema="gn_notifications",
        table_name="bib_notifications_categories",
        column=sa.Column(
            "id_action",
            sa.Integer,
            sa.ForeignKey("gn_permissions.bib_actions.id_action"),
        ),
    )
    op.execute(
        """
        UPDATE gn_notifications.bib_notifications_categories
        SET
            id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'IMPORT'),
            id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'IMPORT')
        WHERE code = 'IMPORT-DONE'
        """
    )


def downgrade():
    op.drop_column(
        table_name="bib_notifications_categories",
        column_name="id_action",
        schema="gn_notifications",
    )
    op.drop_column(
        table_name="bib_notifications_categories",
        column_name="id_object",
        schema="gn_notifications",
    )
    op.drop_column(
        table_name="bib_notifications_categories",
        column_name="id_module",
        schema="gn_notifications",
    )
