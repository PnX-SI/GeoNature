"""[import] add permissions by entities

Revision ID: f59ccdee8f86
Revises: 51ee1572f71f
Create Date: 2025-03-24 14:59:08.659272

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f59ccdee8f86"
down_revision = "51ee1572f71f"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    all_default_value = conn.execute(
        "SELECT id_object FROM gn_permissions.t_objects where code_object = 'ALL'"
    ).fetchall()[0][0]

    op.add_column(
        schema="gn_imports",
        table_name="bib_entities",
        column=sa.Column(
            "id_object",
            sa.Integer,
            sa.ForeignKey("gn_permissions.t_objects.id_object"),
            nullable=True,
            server_default=str(all_default_value),
        ),
    )
    op.execute(
        "ALTER TABLE gn_imports.bib_entities ADD CONSTRAINT bib_entities_t_objects_fk FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object);"
    )


def downgrade():
    op.drop_column(
        schema="gn_imports",
        table_name="bib_entities",
        column_name="id_object",
    )
