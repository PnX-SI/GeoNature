"""fill ngmodule in t_modules

Revision ID: 3902129a52b3
Revises: 42040535a20e
Create Date: 2022-04-06 16:33:14.888900

"""
from pathlib import Path
from alembic import op
import sqlalchemy as sa
from geonature.utils.module import list_frontend_enabled_modules
from geonature.utils.env import GN_EXTERNAL_MODULE

# revision identifiers, used by Alembic.
revision = "3902129a52b3"
down_revision = "42040535a20e"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    query = """
    SELECT * FROM gn_commons.t_modules 
    WHERE active_frontend IS TRUE
    """
    for mod in conn.execute(query).fetchall():
        # ignore internal module (i.e. without symlink in external module directory)
        if not Path(GN_EXTERNAL_MODULE / mod.module_code.lower()).exists():
            continue
        conn.execute(
            sa.sql.text(
                """
            UPDATE gn_commons.t_modules
            SET ng_module = LOWER(module_code)
            WHERE module_code = :module_code
            """
            ),
            {"module_code": mod.module_code},
        )


def downgrade():
    pass
