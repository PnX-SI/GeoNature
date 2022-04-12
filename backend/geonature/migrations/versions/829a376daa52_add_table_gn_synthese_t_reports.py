"""add table gn_synthese.t_reports

Revision ID: 829a376daa52
Revises: 095da7bc6667
Create Date: 2022-03-17 10:57:55.989648

"""
from alembic import op
import sqlalchemy as sa
from utils_flask_sqla.migrations.utils import logger

# revision identifiers, used by Alembic.
revision = "829a376daa52"
down_revision = "095da7bc6667"
branch_labels = None
depends_on = None


def upgrade():
    logger.info("Create t_reports table...")
    op.execute(
        """
    CREATE TABLE gn_synthese.t_reports (
        id_report SERIAL NOT NULL PRIMARY KEY,
        id_synthese INT NOT NULL,
        id_role INT NOT NULL,
        id_type INT,
        content VARCHAR NOT NULL,
        creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        deleted BOOLEAN DEFAULT FALSE,
        CONSTRAINT fk_report_type
            FOREIGN KEY(id_type) 
            REFERENCES gn_synthese.bib_reports_types(id_type)
            ON UPDATE CASCADE ON DELETE CASCADE,
        CONSTRAINT fk_report_role
            FOREIGN KEY(id_role)
            REFERENCES utilisateurs.t_roles(id_role)
            ON UPDATE CASCADE ON DELETE CASCADE,
        CONSTRAINT fk_report_synthese
            FOREIGN KEY(id_synthese)
            REFERENCES gn_synthese.synthese(id_synthese)
            ON UPDATE CASCADE ON DELETE CASCADE
    )
    """
    )
    pass


def downgrade():
    logger.info("Drop table t_reports...")
    op.execute("DROP TABLE IF EXISTS gn_synthese.t_reports")
    pass
