"""create occtax schema

Revision ID: 29c199e07eaa
Revises:
Create Date: 2021-10-04 10:15:40.419932

"""

import importlib

from alembic import op
import sqlalchemy as sa
from sqlalchemy import func
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = "29c199e07eaa"
down_revision = None
branch_labels = ("occtax",)
depends_on = ("f06cc80cc8ba",)  # GeoNature 2.7.5


def upgrade():
    local_srid = op.get_bind().execute(func.Find_SRID("ref_geo", "l_areas", "geom")).scalar()
    operations = text(importlib.resources.read_text("occtax.migrations.data", "occtax.sql"))
    op.get_bind().execute(operations, {"local_srid": local_srid})


def downgrade():
    op.execute(
        """
    DELETE FROM gn_permissions.t_objects
    WHERE code_object LIKE 'OCCTAX_%'
    """
    )
    op.execute(
        """
    DELETE FROM gn_permissions.cor_object_module com
    USING gn_permissions.t_objects o, gn_commons.t_modules m
    WHERE com.id_object = o.id_object
    AND com.id_module = m.id_module
    AND code_object = 'TDatasets'
    AND module_code = 'OCCTAX'
    """
    )
    op.execute(
        """
    DELETE FROM gn_synthese.t_sources
    WHERE name_source = 'Occtax'
    """
    )
    op.execute(
        """
    DELETE FROM utilisateurs.cor_role_liste crl
    USING utilisateurs.t_listes l
    WHERE crl.id_liste = l.id_liste
    AND code_liste = 'obsocctax'
    """
    )
    op.execute(
        """
    DELETE FROM utilisateurs.t_listes
    WHERE code_liste = 'obsocctax'
    """
    )
    op.execute("DROP SCHEMA pr_occtax CASCADE")
