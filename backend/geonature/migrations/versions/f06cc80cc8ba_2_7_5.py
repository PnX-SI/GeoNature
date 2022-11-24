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
    #'3842a6d800a0',  # sql utils (already covered by other dependencies)
    "72f227e37bdf",  # utilisateurs schema 1.4.7 + samples data
    #'f61f95136ec3',  # taxonomie schema 1.8.1 + inpn data (already required by nomenc with taxo)
    "a763fb554ff2",  # nomenclatures with taxonomie enabled + inpn data
    "46e91e738845",  # ref_habitats schema 0.1.6 + inpn data
    "6afe74833ed0",  # ref_geo
)


def upgrade():
    bindparams = {}
    try:
        bindparams["local_srid"] = context.get_x_argument(as_dictionary=True)["local-srid"]
    except KeyError:
        raise Exception("Missing local srid, please use -x local-srid=...")
    conn = op.get_bind()
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
    op.execute("DROP SCHEMA ref_geo CASCADE")
    op.execute("DROP SCHEMA gn_imports CASCADE")
    op.execute("DROP SCHEMA gn_synthese CASCADE")
    op.execute("DROP SCHEMA gn_exports CASCADE")
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
