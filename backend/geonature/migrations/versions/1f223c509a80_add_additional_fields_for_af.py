"""add additional_fields support for acquisition frameworks

Revision ID: 1f223c509a80
Revises: cad98c048b5e
Create Date: 2025-10-01 15:38:19.615874

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision = "1f223c509a80"
down_revision = "cad98c048b5e"
branch_labels = None
depends_on = None


def upgrade():
    # Ajout d'une entrée 'METADATA_CADRE_ACQUISITION' dans la table `gn_permissions.objects`
    #   nécessaire pour l'ajout et la gestion de champs additionels pour le module Métadonnées
    op.execute(
        """
        INSERT INTO 
            gn_permissions.t_objects 
                (
                code_object, 
                description_object
                )
        VALUES
                (
                'METADATA_CADRE_ACQUISITION',
                'Représente la table gn_meta.t_acquisition_frameworks'
                )
        ;
    """
    )


def downgrade():
    # Suppression de l'entrée 'METADATA_CADRE_ACQUISITION'
    op.execute(
        """
        DELETE FROM
            gn_permissions.t_objects
        WHERE
            code_object = 'METADATA_CADRE_ACQUISITION'
        ;
    """
    )
