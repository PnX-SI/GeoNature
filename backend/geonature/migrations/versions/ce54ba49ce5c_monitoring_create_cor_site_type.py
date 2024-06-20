"""[monitoring] create_cor_site_type

Revision ID: ce54ba49ce5c
Revises: b53bafb13ce8
Create Date: 2022-12-06 16:18:24.512562

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "ce54ba49ce5c"
down_revision = "b53bafb13ce8"
branch_labels = None
depends_on = None

monitorings_schema = "gn_monitoring"


def upgrade():
    op.create_table(
        "cor_site_type",
        sa.Column(
            "id_type_site",
            sa.Integer(),
            sa.ForeignKey(
                f"{monitorings_schema}.bib_type_site.id_nomenclature_type_site",
                name="fk_cor_site_type_id_nomenclature_type_site",
                ondelete="CASCADE",
                onupdate="CASCADE",
            ),
            nullable=False,
        ),
        sa.Column(
            "id_base_site",
            sa.Integer(),
            sa.ForeignKey(
                f"{monitorings_schema}.t_base_sites.id_base_site",
                name="fk_cor_site_type_id_base_site",
                ondelete="CASCADE",
                onupdate="CASCADE",
            ),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id_type_site", "id_base_site", name="pk_cor_site_type"),
        schema=monitorings_schema,
    )
    op.create_table_comment(
        "cor_site_type",
        "Table d'association entre les sites et les types de sites",
        schema=monitorings_schema,
    )

    op.execute(
        """
        INSERT INTO  gn_monitoring.cor_site_type
        SELECT id_nomenclature_type_site , id_base_site d
        FROM gn_monitoring.t_base_sites ;
    """
    )

    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_sites
        DROP CONSTRAINT check_t_base_sites_type_site;
    """
    )
    op.execute(
        """
        DROP INDEX gn_monitoring.idx_t_base_sites_type_site;
    """
    )
    op.drop_column(
        table_name="t_base_sites",
        column_name="id_nomenclature_type_site",
        schema=monitorings_schema,
    )


def downgrade():
    op.add_column(
        table_name="t_base_sites",
        column=sa.Column(
            "id_nomenclature_type_site",
            sa.Integer(),
            sa.ForeignKey(
                "ref_nomenclatures.t_nomenclatures.id_nomenclature",
                name="fk_t_base_sites_type_site",
                onupdate="CASCADE",
            ),
        ),
        schema=monitorings_schema,
    )

    op.execute(
        """
        WITH ts AS (
            SELECT DISTINCT ON (id_base_site) id_base_site, id_type_site
            FROM gn_monitoring.cor_site_type AS cts
            ORDER BY id_base_site, id_type_site
        )
        UPDATE gn_monitoring.t_base_sites tbs
            SET id_nomenclature_type_site = id_type_site
        FROM ts
        WHERE ts.id_base_site = tbs.id_base_site;
    """
    )

    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_sites
        ADD CONSTRAINT check_t_base_sites_type_site
        CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_site,'TYPE_SITE'))
        NOT VALID;
    """
    )

    op.execute(
        """
        CREATE INDEX idx_t_base_sites_type_site ON gn_monitoring.t_base_sites USING btree (id_nomenclature_type_site);
    """
    )
    op.execute(
        """
        ALTER TABLE gn_monitoring.t_base_sites ALTER COLUMN id_nomenclature_type_site SET NOT NULL;
    """
    )

    op.drop_table("cor_site_type", schema=monitorings_schema)
