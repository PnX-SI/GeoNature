"""add_missing_error

Revision ID: 0e8e1943c215
Revises: 8b149244d586
Create Date: 2024-05-03 14:22:20.773467

"""

from alembic import op
import sqlalchemy as sa
from geonature.core.imports.models import ImportUserErrorType

# revision identifiers, used by Alembic.
revision = "0e8e1943c215"
down_revision = "8b149244d586"
branch_labels = None
depends_on = None


def upgrade():
    op.bulk_insert(
        ImportUserErrorType.__table__,
        [
            {
                "error_type": "Erreur de format",
                "name": "INVALID_BOOL",
                "description": "Le champ doit être renseigne avec une valeur binaire (0 ou 1, true ou false).",
            },
        ],
    )


def downgrade():
    op.execute(sa.delete(ImportUserErrorType).where(ImportUserErrorType.name == "INVALID_BOOL"))
