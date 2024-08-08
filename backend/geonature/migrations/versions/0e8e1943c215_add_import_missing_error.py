"""add_import_missing_error

Revision ID: 0e8e1943c215
Revises: 8b149244d586
Create Date: 2024-05-03 14:22:20.773467

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "0e8e1943c215"
down_revision = "6e1852ecfea2"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    error_type = sa.Table("bib_errors_types", metadata, schema="gn_imports", autoload_with=conn)
    op.bulk_insert(
        error_type,
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
            {
                "error_type": "Ignorer les données existantes",
                "name": "SKIP_EXISTING_UUID",
                "description": "Les entitiés existantes selon UUID sont ignorees.",
                "error_level": "WARNING",
            },
        ],
    )


def downgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    error_type = sa.Table("bib_errors_types", metadata, schema="gn_imports", autoload_with=conn)
    op.execute(sa.delete(error_type).where(error_type.c.name == "INVALID_BOOL"))
    op.execute(sa.delete(error_type).where(error_type.c.name == "INCOHERENT_DATA"))
    op.execute(sa.delete(error_type).where(error_type.c.name == "INVALID_NUMERIC"))
