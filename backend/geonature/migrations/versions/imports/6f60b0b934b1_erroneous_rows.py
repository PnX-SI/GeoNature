"""erroneous rows

Revision ID: 6f60b0b934b1
Revises: 0ff8fc0b4233
Create Date: 2022-06-20 17:48:33.848166

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.types import ARRAY


# revision identifiers, used by Alembic.
revision = "6f60b0b934b1"
down_revision = "cadfdaa42430"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "erroneous_rows",
            ARRAY(sa.Integer),
        ),
    )
    op.execute(
        """
    WITH cte AS (
        SELECT
            id_import,
            array_agg(line_no ORDER BY line_no) erroneous_rows
        FROM
            gn_imports.t_imports_synthese
        WHERE
            valid = FALSE
        GROUP BY
            id_import
    )
    UPDATE
        gn_imports.t_imports i
    SET
        erroneous_rows = cte.erroneous_rows
    FROM
        cte
    WHERE
        i.id_import = cte.id_import
        AND
        i.processing = TRUE
    """
    )


def downgrade():
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="erroneous_rows",
    )
