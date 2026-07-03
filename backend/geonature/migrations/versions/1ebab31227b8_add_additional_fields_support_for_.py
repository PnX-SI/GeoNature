"""add additional fields support for datasets

Revision ID: 1ebab31227b8
Revises: f6a1feb3f297
Create Date: 2026-07-03 13:01:49.387061

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "1ebab31227b8"
down_revision = "f6a1feb3f297"
branch_labels = None
depends_on = None


def upgrade():
    # Ajout d'une entrée 'METADATA_JEU_DE_DONNEES' dans la table `gn_permissions.objects`
    #   nécessaire pour l'ajout et la gestion de champs additionels pour les jeux de données
    op.execute("""
        INSERT INTO 
            gn_permissions.t_objects 
                (
                code_object, 
                description_object
                )
        VALUES
                (
                'METADATA_JEU_DE_DONNEES',
                'Représente la table gn_meta.t_datasets'
                )
        ;
    """)


def downgrade():
    # Suppression de l'entrée 'METADATA_JEU_DE_DONNEES'
    op.execute("""
        DELETE FROM
            gn_permissions.t_objects
        WHERE
            code_object = 'METADATA_JEU_DE_DONNEES'
        ;
    """)
