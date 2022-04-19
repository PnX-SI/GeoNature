"""fill ngmodule in t_modules

Revision ID: 3902129a52b3
Revises: 42040535a20e
Create Date: 2022-04-06 16:33:14.888900

"""
from alembic import op
import sqlalchemy as sa
from geonature.utils.module import list_frontend_enabled_modules


# revision identifiers, used by Alembic.
revision = "3902129a52b3"
down_revision = "42040535a20e"
branch_labels = None
depends_on = None


def upgrade():
    for m in list_frontend_enabled_modules():
        # WORK in local but not in the CI ?
        # v = {"module_code": m.module_code}
        # op.get_bind().execute(
        #     sa.sql.text(
        #         """
        #     UPDATE gn_commons.t_modules
        #     SET ng_module = LOWER(module_code)
        #     WHERE module_code = :module_code
        #     """
        #     ),
        #     **v
        # )

        # alternativ but not acceptable..(sql injection)
        op.execute(
            f"""
            UPDATE gn_commons.t_modules
            SET ng_module = LOWER(module_code)
            WHERE module_code = '{m.module_code}'
            """
        )


def downgrade():
    pass
