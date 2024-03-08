"""remove t_imports.is_finished

Revision ID: 74058f69828a
Revises: 61e11414f177
Create Date: 2022-04-27 13:51:46.622094

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "74058f69828a"
down_revision = "61e11414f177"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="is_finished",
    )


def downgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "is_finished",
            sa.Boolean,
        ),
    )
    op.execute(
        """
    UPDATE
        gn_imports.t_imports i
    SET
        is_finished = EXISTS (
            SELECT *
            FROM gn_synthese.synthese synthese
            JOIN gn_synthese.t_sources source ON synthese.id_source = source.id_source
            WHERE source.name_source = 'Import(id=' || i.id_import || ')'
        )
    """
    )
