"""add sensitivity filter

Revision ID: f1dd984bff97
Revises: f051b88a57fd
Create Date: 2023-04-19 16:24:57.945428

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import Column, Boolean


# revision identifiers, used by Alembic.
revision = "f1dd984bff97"
down_revision = "f051b88a57fd"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_permissions",
        table_name="t_permissions",
        column=Column(
            "sensitivity_filter",
            Boolean,
            server_default=sa.false(),
        ),
    )
    op.add_column(
        schema="gn_permissions",
        table_name="t_permissions_available",
        column=Column(
            "sensitivity_filter",
            Boolean,
            server_default=sa.false(),
        ),
    )
    op.execute(
        """
        UPDATE
            gn_permissions.t_permissions_available pa
        SET
            sensitivity_filter = True
        FROM
            gn_commons.t_modules m,
            gn_permissions.t_objects o,
            gn_permissions.bib_actions a
        WHERE
            pa.id_module = m.id_module
            AND
            pa.id_object = o.id_object
            AND
            pa.id_action = a.id_action
            AND
            m.module_code = 'SYNTHESE' AND o.code_object = 'ALL' and a.code_action = 'R'
        """
    )


def downgrade():
    op.drop_column(
        schema="gn_permissions", table_name="t_permissions", column_name="sensitivity_filter"
    )
    op.drop_column(
        schema="gn_permissions",
        table_name="t_permissions_available",
        column_name="sensitivity_filter",
    )
