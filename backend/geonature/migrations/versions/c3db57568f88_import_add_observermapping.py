"""[import] add observermapping

Revision ID: c3db57568f88
Revises: 8c31693c2183
Create Date: 2025-10-27 15:44:05.413864

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSON, JSONB


# revision identifiers, used by Alembic.
revision = "c3db57568f88"
down_revision = "8c31693c2183"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        "t_imports",
        column=sa.Column(
            "observermapping", JSON, nullable=False, server_default=sa.text("'{}'::jsonb")
        ),
        schema="gn_imports",
    )
    op.create_table(
        "t_observermappings",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("values", JSON, nullable=False, server_default=sa.text("'{}'::jsonb")),
        schema="gn_imports",
    )

    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET type_field = 'observers'
        WHERE name_field = 'observers' AND id_destination = (SELECT id_destination FROM gn_imports.bib_destinations WHERE code = 'synthese');
    """
    )


def downgrade():

    op.execute(
        """
        UPDATE gn_imports.bib_fields
        SET type_field = 'textarea'
        WHERE name_field = 'observers' AND id_destination = (SELECT id_destination FROM gn_imports.bib_destinations WHERE code = 'synthese');
    """
    )
    op.drop_table("t_observermappings", schema="gn_imports")
    op.drop_column("t_imports", column_name="observermapping", schema="gn_imports")
