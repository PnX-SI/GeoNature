"""add support_additional_fields column

Revision ID: 0444c425fa27
Revises: dc153c5b1cec
Create Date: 2026-08-10 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "0444c425fa27"
down_revision = "1ca1e8ec50f4"
branch_labels = None
depends_on = None

DEFAULT_IMPLEMENTED_MODULES = ("OCCTAX", "METADATA")
DEFAULT_IMPLEMENTED_OBJECTS = (
    "OCCTAX_RELEVE",
    "OCCTAX_OCCURENCE",
    "OCCTAX_DENOMBREMENT",
    "METADATA_CADRE_ACQUISITION",
    "METADATA_JEU_DE_DONNEES",
)


def upgrade():
    op.add_column(
        "t_modules",
        sa.Column("support_additional_fields", sa.Boolean, nullable=True, server_default="false"),
        schema="gn_commons",
    )
    op.add_column(
        "t_objects",
        sa.Column("support_additional_fields", sa.Boolean, nullable=True, server_default="false"),
        schema="gn_permissions",
    )
    bind = op.get_bind()
    bind.execute(
        sa.text(
            "UPDATE gn_commons.t_modules SET support_additional_fields = true "
            "WHERE module_code IN :module_codes or ng_module = 'occtax'"
        ).bindparams(sa.bindparam("module_codes", expanding=True)),
        {"module_codes": DEFAULT_IMPLEMENTED_MODULES},
    )
    bind.execute(
        sa.text(
            "UPDATE gn_permissions.t_objects SET support_additional_fields = true "
            "WHERE code_object IN :object_codes"
        ).bindparams(sa.bindparam("object_codes", expanding=True)),
        {"object_codes": DEFAULT_IMPLEMENTED_OBJECTS},
    )


def downgrade():
    op.drop_column("t_objects", "support_additional_fields", schema="gn_permissions")
    op.drop_column("t_modules", "support_additional_fields", schema="gn_commons")
