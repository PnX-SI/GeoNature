"""Migrate bibliographical references to publications

Revision ID: 570a8b7a030c

Revises: cc469410feeb
Create Date: 2026-08-17 16:38:44.564373

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "570a8b7a030c"
down_revision = "cc469410feeb"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(sa.text("""
            WITH src AS (
                SELECT
                    id_bibliographic_reference,
                    id_acquisition_framework,
                    gen_random_uuid() AS new_publication_id,
                    COALESCE(publication_url, '') AS publication_url,
                    COALESCE(publication_reference, '') AS publication_reference
                FROM gn_meta.t_bibliographical_references
            ),
            ins_pub AS (
                INSERT INTO gn_meta.datatype_publications (
                    unique_publication_id,
                    publication_url,
                    publication_reference,
                    description_publication
                )
                SELECT
                    new_publication_id,
                    publication_url,
                    publication_reference,
                    NULL
                FROM src
                RETURNING unique_publication_id, id_publication
            )
            INSERT INTO gn_meta.cor_acquisition_framework_publication (
                id_acquisition_framework,
                id_publication
            )
            SELECT
                src.id_acquisition_framework,
                ins_pub.id_publication
            FROM src
            JOIN ins_pub ON ins_pub.unique_publication_id = src.new_publication_id
            WHERE src.id_acquisition_framework IS NOT NULL
        """))

    op.drop_table("t_bibliographical_references", schema="gn_meta")


def downgrade():
    # Recreate the old table but without populating it (we don't know which publication comes from t_bibliographical_references)
    op.create_table(
        "t_bibliographical_references",
        sa.Column("id_bibliographic_reference", sa.Integer(), nullable=False),
        sa.Column("id_acquisition_framework", sa.Integer(), nullable=True),
        sa.Column("publication_url", sa.Unicode(), nullable=True),
        sa.Column("publication_reference", sa.Unicode(), nullable=True),
        sa.ForeignKeyConstraint(
            ("id_acquisition_framework",),
            ["gn_meta.t_acquisition_frameworks.id_acquisition_framework"],
            onupdate="CASCADE",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id_bibliographic_reference"),
        schema="gn_meta",
    )
