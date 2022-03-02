"""add table gn_synthese.t_discussion

Revision ID: 5094d05780ac
Revises: 1dbc45309d6e
Create Date: 2022-03-02 15:22:16.032792

"""
from alembic import op
import sqlalchemy as sa
from utils_flask_sqla.migrations.utils import logger

# revision identifiers, used by Alembic.
revision = '5094d05780ac'
down_revision = '1dbc45309d6e'
branch_labels = None
depends_on = None


def upgrade():
    logger.info("Create t_discussion table...")
    op.execute("""
    CREATE TABLE gn_synthese.t_discussions (
        id_discussion SERIAL NOT NULL PRIMARY KEY,
        id_synthese integer NOT NULL,
        id_role integer NOT NULL,
        content json NOT NULL,
        content_date DATE NOT NULL DEFAULT CURRENT_DATE
    )
    """)
    pass


def downgrade():
    logger.info("Drop table t_discussion...")
    op.execute("DROP TABLE IF EXISTS gn_SYNTHESE.t_discussion")
    pass
