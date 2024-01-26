"""add ng_module column in t_modules

Revision ID: 42040535a20e
Revises: ca0fe5d21ea2
Create Date: 2022-04-05 16:22:57.078076

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "42040535a20e"
down_revision = "07f10bbb4f3b"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_commons",
        table_name="t_modules",
        column=sa.Column(
            "ng_module",
            sa.Unicode(length=500),
        ),
    )
    monitoring_present = (
        op.get_bind()
        .execute(
            """
    SELECT EXISTS (
        SELECT FROM pg_tables
        WHERE  schemaname = 'gn_monitoring'
        AND    tablename  = 't_module_complements'
    )
    """
        )
        .scalar()
    )
    if monitoring_present:
        op.execute(
            """
            UPDATE gn_commons.t_modules m
            SET ng_module = LOWER(m.module_code)
            FROM gn_commons.t_modules mod
            LEFT JOIN gn_monitoring.t_module_complements modcomp USING(id_module)
            WHERE
                m.id_module = mod.id_module
                AND
                mod.module_code NOT IN ('GEONATURE', 'ADMIN', 'METADATA', 'SYNTHESE')
                AND
                modcomp.id_module IS NULL
            """
        )
    else:
        op.execute(
            """
            UPDATE gn_commons.t_modules
            SET ng_module = LOWER(module_code)
            WHERE module_code NOT IN ('GEONATURE', 'ADMIN', 'METADATA', 'SYNTHESE')
            """
        )


def downgrade():
    op.drop_column(
        schema="gn_commons",
        table_name="t_modules",
        column_name="ng_module",
    )
