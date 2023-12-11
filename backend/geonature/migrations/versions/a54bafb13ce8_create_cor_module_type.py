"""create_cor_module_type

Revision ID: a54bafb13ce8
Revises: ce54ba49ce5c
Create Date: 2022-12-06 16:18:24.512562

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "a54bafb13ce8"
down_revision = "ce54ba49ce5c"
branch_labels = None
depends_on = None

monitorings_schema = "gn_monitoring"
referent_schema = "gn_commons"


def upgrade():
    op.create_table(
        "cor_module_type",
        sa.Column(
            "id_type_site",
            sa.Integer(),
            sa.ForeignKey(
                f"{monitorings_schema}.bib_type_site.id_nomenclature_type_site",
                name="fk_cor_module_type_id_nomenclature",
                ondelete="CASCADE",
                onupdate="CASCADE",
            ),
            nullable=False,
        ),
        sa.Column(
            "id_module",
            sa.Integer(),
            sa.ForeignKey(
                f"{referent_schema}.t_modules.id_module",
                name="fk_cor_module_type_id_module",
                ondelete="CASCADE",
                onupdate="CASCADE",
            ),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id_type_site", "id_module", name="pk_cor_module_type"),
        schema=monitorings_schema,
    )

    # Insertion des données a partir de cor_site_module
    op.execute(
        """
        INSERT INTO gn_monitoring.cor_module_type (id_module, id_type_site )
        SELECT DISTINCT csm.id_module, cts.id_type_site
        FROM gn_monitoring.cor_site_module AS csm
        JOIN gn_monitoring.cor_type_site AS cts
        ON Cts.id_base_site = csm.id_base_site ;
    """
    )


def downgrade():
    op.drop_table("cor_module_type", schema=monitorings_schema)
