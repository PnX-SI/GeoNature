"""add phyto data

Revision ID: d2c12d091e14
Revises: b369d122eb35
Create Date: 2025-08-13 15:47:05.573172

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "d2c12d091e14"
down_revision = "b369d122eb35"
branch_labels = None
depends_on = None


def upgrade():

    schema = "pr_occtax"

    # --- Add new columns to cor_counting_occtax ---
    op.add_column(
        "cor_counting_occtax",
        sa.Column(
            "id_nomenclature_vegetation_stratum",
            sa.Integer(),
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
        ),
        schema=schema,
    )
    op.add_column(
        "cor_counting_occtax",
        sa.Column(
            "id_nomenclature_phytosociological_abundance",
            sa.Integer(),
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
        ),
        schema=schema,
    )

    # --- Create t_vegetation_stratum table ---
    op.create_table(
        "t_vegetation_stratum",
        sa.Column("id_vegetation_stratum", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "id_releve_occtax",
            sa.Integer(),
            sa.ForeignKey(f"{schema}.t_releves_occtax.id_releve_occtax"),
            nullable=True,
        ),
        sa.Column(
            "id_nomenclature_vegetation_stratum",
            sa.Integer(),
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
        ),
        sa.Column("min_height", sa.Numeric(5, 2), nullable=True),
        sa.Column("max_height", sa.Numeric(5, 2), nullable=True),
        sa.Column("average_height", sa.Numeric(5, 2), nullable=True),
        sa.Column("percentage_cover_vegetation_stratum", sa.Integer(), nullable=True),
        schema=schema,
    )


def downgrade():
    schema = "pr_occtax"

    op.drop_column(
        "cor_counting_occtax", "id_nomenclature_phytosociological_abundance", schema=schema
    )
    op.drop_column("cor_counting_occtax", "id_nomenclature_vegetation_stratum", schema=schema)

    op.drop_table("t_vegetation_stratum", schema=schema)
