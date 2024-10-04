"""add import module

Revision ID: 75e78027227d
Revises: 
Create Date: 2023-12-18

"""

from alembic import op


# revision identifiers, used by Alembic.
revision = "75e78027227d"
down_revision = None
branch_labels = ("import",)
depends_on = None


schema = "gn_imports"
archive_schema = "gn_import_archives"


def upgrade():
    op.execute(
        """
        INSERT INTO
            gn_commons.t_modules (
                module_code,
                module_label,
                module_picto,
                module_path,
                module_target,
                active_frontend,
                active_backend
            )
        VALUES (
            'IMPORT',
            'Import',
            'fa-upload',
            'import',
            '_self',
            TRUE,
            TRUE
        )
        """
    )


def downgrade():
    op.execute("DELETE FROM gn_commons.t_modules WHERE module_code = 'IMPORT'")
