"""add_import_missing_error

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
                "error_type": "Erreur de format booléen",
                "name": "INVALID_BOOL",
                "description": "Le champ doit être renseigné avec une valeur binaire (0 ou 1, true ou false).",
                "error_level": "ERROR",
            },
            {
                "error_type": "Données incohérentes d'une ou plusieurs entités",
                "name": "INCOHERENT_DATA",
                "description": "Les données indiquées pour une ou plusieurs entités sont incohérentes sur différentes lignes.",
                "error_level": "ERROR",
            },
            {
                "error_type": "Erreur de format nombre",
                "name": "INVALID_NUMERIC",
                "description": "Le champ doit être renseigné avec une valeur numérique (entier, flottant).",
                "error_level": "ERROR",
            },
        ],
    )


def downgrade():
    op.execute(sa.delete(ImportUserErrorType).where(ImportUserErrorType.name == "INVALID_BOOL"))
    op.execute(sa.delete(ImportUserErrorType).where(ImportUserErrorType.name == "INCOHERENT_DATA"))
    op.execute(sa.delete(ImportUserErrorType).where(ImportUserErrorType.name == "INVALID_NUMERIC"))
