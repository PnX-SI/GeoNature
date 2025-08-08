"""add phyto data

Revision ID: b369d122eb35
Revises: b66d30f4e3d1
Create Date: 2025-08-01 10:58:32.347820

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import text


# revision identifiers, used by Alembic.
revision = "b369d122eb35"
down_revision = "b66d30f4e3d1"
branch_labels = None
depends_on = None


def _backup_view(conn, schema: str, view: str):
    """Return (definition, list of GRANTs) for the specified view."""
    view_def = conn.execute(
        text(f"SELECT pg_get_viewdef('{schema}.{view}'::regclass, true)")
    ).scalar()

    grants = conn.execute(
        text(
            f"""
            SELECT array_agg('GRANT ' || privilege_type || ' ON {schema}.{view} TO ' || grantee)
            FROM information_schema.role_table_grants
            WHERE table_schema = :schema AND table_name = :view
        """
        ),
        {"schema": schema, "view": view},
    ).scalar()

    if grants is None:
        grants = []
    else:
        grants = list(grants)

    return view_def, grants


def _restore_view(conn, schema: str, view: str, view_def: str, grants: list):
    """Recreate the view and reapply its GRANTs."""
    conn.execute(text(f"CREATE VIEW {schema}.{view} AS {view_def};"))
    for grant in grants:
        conn.execute(text(grant))


def upgrade():

    conn = op.get_bind()

    schema = "pr_occtax"
    view = "v_export_occtax"

    # --- Add new columns to t_releves_occtax ---
    op.add_column(
        "t_releves_occtax",
        sa.Column("code_releve", sa.String(length=50), nullable=True),
        schema=schema,
    )
    op.add_column(
        "t_releves_occtax", sa.Column("slope", sa.Numeric(4, 2), nullable=True), schema=schema
    )
    op.add_column(
        "t_releves_occtax", sa.Column("area", sa.Numeric(20, 2), nullable=True), schema=schema
    )
    op.add_column(
        "t_releves_occtax",
        sa.Column("id_nomenclature_exposure", sa.Integer(), nullable=True),
        schema=schema,
    )

    # --- Change column type of field precision ---
    # Backup view definition and GRANTs
    view_def, grants = _backup_view(conn, schema, view)
    # Drop the view temporarily
    op.execute(f"DROP VIEW {schema}.{view};")
    # Alter the precision column type
    op.alter_column(
        "t_releves_occtax",
        "precision",
        type_=sa.Numeric(10, 2),
        schema=schema,
        postgresql_using="precision::NUMERIC(10,2)",
    )
    # Restore the view with the new column type
    _restore_view(conn, schema, view, view_def, grants)

    # --- Add new columns to cor_counting_occtax ---
    op.add_column(
        "cor_counting_occtax",
        sa.Column("id_nomenclature_vegetation_stratum", sa.Integer(), nullable=True),
        schema=schema,
    )
    op.add_column(
        "cor_counting_occtax",
        sa.Column("id_nomenclature_phytosociological_abundance", sa.Integer(), nullable=True),
        schema=schema,
    )

    # --- Create t_vegetation_stratum table ---
    op.create_table(
        "t_vegetation_stratum",
        sa.Column("id_vegetation_stratum", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("id_releve_occtax", sa.Integer(), nullable=True),
        sa.Column("id_nomenclature_vegetation_stratum", sa.Integer(), nullable=True),
        sa.Column("min_height", sa.Numeric(5, 2), nullable=True),
        sa.Column("max_height", sa.Numeric(5, 2), nullable=True),
        sa.Column("average_height", sa.Numeric(5, 2), nullable=True),
        sa.Column("percentage_cover_vegatation_stratum", sa.Integer(), nullable=True),
        schema=schema,
    )


def downgrade():
    conn = op.get_bind()

    schema = "pr_occtax"
    view = "v_export_occtax"

    # --- Remove new columns from t_releves_occtax ---
    op.drop_column("t_releves_occtax", "code_releve", schema=schema)
    op.drop_column("t_releves_occtax", "slope", schema=schema)
    op.drop_column("t_releves_occtax", "area", schema=schema)
    op.drop_column("t_releves_occtax", "id_nomenclature_exposure", schema=schema)

    # --- Revert field precision column type ---
    # Backup view definition and GRANTs
    view_def, grants = _backup_view(conn, schema, view)
    # Drop the view
    op.execute(f"DROP VIEW {schema}.{view};")
    # Alter the precision column type back to Integer
    op.alter_column(
        "t_releves_occtax",
        "precision",
        type_=sa.Integer(),
        schema=schema,
        postgresql_using="precision::INTEGER",
    )
    # Restore the view
    _restore_view(conn, schema, view, view_def, grants)

    # --- Remove new columns from cor_counting_occtax ---
    op.drop_column(
        "cor_counting_occtax", "id_nomenclature_phytosociological_abundance", schema=schema
    )
    op.drop_column("cor_counting_occtax", "id_nomenclature_vegetation_stratum", schema=schema)

    # --- Drop t_vegetation_stratum table ---
    op.drop_table("t_vegetation_stratum", schema=schema)
