"""drop import_count column

Revision ID: 7b6a578eccd7
Revises: c49474d2f1f7
Create Date: 2024-10-18 16:24:44.145501

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "7b6a578eccd7"
down_revision = "c49474d2f1f7"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE gn_imports.t_imports
        SET statistics = statistics::jsonb || jsonb_build_object('import_count', import_count);
    """
    )
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="import_count",
    )


def downgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "import_count",
            sa.Integer,
        ),
    )

    op.execute(
        """
        WITH count_ AS (
            SELECT
                id_import as id_import,
                (statistics->>'import_count')::integer as import_count
            FROM
                gn_imports.t_imports
            WHERE
                statistics->>'import_count' IS NOT NULL
        )
        UPDATE gn_imports.t_imports as GN
        SET import_count = count_.import_count
        FROM count_
        where GN.id_import = count_.id_import;
    """
    )
    op.execute(
        """
        UPDATE gn_imports.t_imports as GN
        SET statistics = statistics::jsonb #- '{import_count}';
    """
    )
