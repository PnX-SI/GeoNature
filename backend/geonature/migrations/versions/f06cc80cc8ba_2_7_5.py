"""geonature schemas 2.7.5

Revision ID: f06cc80cc8ba
Create Date: 2021-08-10 14:23:55.144250

"""

import importlib

from alembic import op, context
import sqlalchemy as sa
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = "f06cc80cc8ba"
down_revision = None
branch_labels = ("geonature",)
depends_on = (
    # "3842a6d800a0",  # sql utils (already covered by other dependencies)
    # "fa35dfe5ff27",  # utilisateurs schema (already covered by others dependencies)
    "72f227e37bdf",  # utilisateurs samples data
    # "9c2c0254aadc",  # taxonomie schema 1.8.1 (already covered by nomenclatures_taxonomie)
    # "6015397d686a",  # nomenclatures (already covered by nomenclatures_taxonomie)
    "f5436084bf17",  # nomenclatures_taxonomie
    "96a713739fdd",  # nomenclatures_inpn_data
    "46e91e738845",  # ref_habitats schema 0.1.6 + inpn data
    "6afe74833ed0",  # ref_geo
)


def upgrade():
    conn = op.get_bind()
    local_srid = conn.execute("SELECT Find_SRID('ref_geo', 'l_areas', 'geom')").scalar()
    bindparams = {"local_srid": local_srid}
    for path, filename in [
        ("geonature.migrations.data.utilisateurs", "adds_for_usershub.sql"),
        ("geonature.migrations.data.core", "commons.sql"),
        ("geonature.migrations.data.core", "meta.sql"),
        ("geonature.migrations.data.core", "imports.sql"),
        ("geonature.migrations.data.core", "synthese.sql"),
        ("geonature.migrations.data.core", "synthese_default_values.sql"),
        ("geonature.migrations.data.core", "monitoring.sql"),
        ("geonature.migrations.data.core", "permissions.sql"),
        ("geonature.migrations.data.core", "permissions_data.sql"),
        ("geonature.migrations.data.core", "sensitivity.sql"),
        ("geonature.migrations.data.core", "commons_after.sql"),
    ]:
        conn.execute(text(importlib.resources.read_text(path, filename)), bindparams)


def downgrade():
    op.execute("DROP SCHEMA gn_commons CASCADE")
    op.execute("DROP SCHEMA gn_meta CASCADE")
    op.execute("DROP SCHEMA gn_imports CASCADE")
    op.execute("DROP SCHEMA gn_synthese CASCADE")
    op.execute("DROP SCHEMA IF EXISTS gn_exports CASCADE")
    op.execute("DROP SCHEMA gn_monitoring CASCADE")
    op.execute("DROP SCHEMA gn_permissions CASCADE")
    op.execute("DROP SCHEMA gn_sensitivity CASCADE")

    op.execute(
        """
    DELETE FROM utilisateurs.cor_profil_for_app cor
    USING utilisateurs.t_applications app
    WHERE cor.id_application = app.id_application
    AND app.code_application = 'GN'
    """
    )
    op.execute("DELETE FROM utilisateurs.t_applications WHERE code_application = 'GN'")
