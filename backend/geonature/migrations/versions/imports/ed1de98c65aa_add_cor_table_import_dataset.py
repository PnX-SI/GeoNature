"""add corr table import dataset

Revision ID: ed1de98c65aa
Revises: bc060d4f55ce
Create Date: 2026-05-05 10:49:49.973738

"""

from alembic import op
import sqlalchemy as sa

revision = "ed1de98c65aa"
down_revision = "bc060d4f55ce"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "cor_import_datasets",
        sa.Column(
            "id_import",
            sa.Integer(),
            sa.ForeignKey(
                "gn_imports.t_imports.id_import",
                ondelete="CASCADE",
                name="fk_cor_import_datasets_id_import",
            ),
            primary_key=True,
            nullable=False,
        ),
        sa.Column(
            "id_dataset",
            sa.Integer(),
            sa.ForeignKey(
                "gn_meta.t_datasets.id_dataset",
                ondelete="CASCADE",
                name="fk_cor_import_datasets_id_dataset",
            ),
            primary_key=True,
            nullable=False,
        ),
        schema="gn_imports",
    )
    # Fill the table for existing synthese imports
    op.execute(
        """
        INSERT INTO gn_imports.cor_import_datasets (id_import, id_dataset)
        SELECT DISTINCT s.id_import, s.id_dataset
        FROM gn_synthese.synthese s
        WHERE s.id_import IS NOT NULL
          AND s.id_dataset IS NOT NULL
    """
    )


def downgrade():
    op.drop_table("cor_import_datasets", schema="gn_imports")
