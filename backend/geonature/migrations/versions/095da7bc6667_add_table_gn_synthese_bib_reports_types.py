"""add table gn_synthese.bib_reports_types

Revision ID: 095da7bc6667
Revises: ca052245c6ec
Create Date: 2022-03-17 10:57:34.730596

"""
from alembic import op
import sqlalchemy as sa
from utils_flask_sqla.migrations.utils import logger

# revision identifiers, used by Alembic.
revision = "095da7bc6667"
down_revision = "ca052245c6ec"
branch_labels = None
depends_on = None


def upgrade():
    logger.info("Create bib_reports_types table...")
    op.execute(
        """
    CREATE TABLE gn_synthese.bib_reports_types (
        id_type SERIAL NOT NULL PRIMARY KEY,
        type VARCHAR NOT NULL
    )
    """
    )
    op.execute(
        """
    INSERT INTO gn_synthese.bib_reports_types (type)
    VALUES 
        ('discussion'),
        ('alert'),
        ('pin')
    """
    )
    pass


def downgrade():
    logger.info("Drop table bib_reports_types...")
    op.execute("DROP TABLE IF EXISTS gn_synthese.bib_reports_types")
    pass
