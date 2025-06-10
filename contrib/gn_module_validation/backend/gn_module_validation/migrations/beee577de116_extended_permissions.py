"""extended permissions

Revision ID: beee577de116
Revises: 9a4b4b6f8fe6
Create Date: 2025-06-04 15:24:19.739377

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "beee577de116"
down_revision = "9a4b4b6f8fe6"
branch_labels = None
depends_on = ("707390c722fe",)


def set_available_filters(taxons_filter, areas_filter):
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    module = sa.Table("t_modules", metadata, schema="gn_commons", autoload_with=conn)
    id_module_validation = conn.execute(
        sa.select(module.c.id_module).where(module.c.module_code == "VALIDATION")
    ).scalar_one()
    obj = sa.Table("t_objects", metadata, schema="gn_permissions", autoload_with=conn)
    id_object_all = conn.execute(
        sa.select(obj.c.id_object).where(obj.c.code_object == "ALL")
    ).scalar_one()
    action = sa.Table("bib_actions", metadata, schema="gn_permissions", autoload_with=conn)
    id_action_create = conn.execute(
        sa.select(action.c.id_action).where(action.c.code_action == "C")
    ).scalar_one()
    permissions_available = sa.Table(
        "t_permissions_available", metadata, schema="gn_permissions", autoload_with=conn
    )
    op.execute(
        sa.update(permissions_available)
        .where(
            permissions_available.c.id_module == id_module_validation,
            permissions_available.c.id_object == id_object_all,
            permissions_available.c.id_action == id_action_create,
        )
        .values(taxons_filter=taxons_filter, areas_filter=areas_filter)
    )


def upgrade():
    set_available_filters(True, True)


def downgrade():
    set_available_filters(False, False)
