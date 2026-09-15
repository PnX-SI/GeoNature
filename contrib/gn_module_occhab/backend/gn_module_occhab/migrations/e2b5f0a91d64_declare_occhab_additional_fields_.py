"""declare occhab additional fields support

Revision ID: e2b5f0a91d64
Revises: c4d8e1a7b93f
Create Date: 2026-08-31 10:31:07.904215

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "e2b5f0a91d64"
down_revision = "c4d8e1a7b93f"
branch_labels = None
depends_on = "0444c425fa27"  # geonature@0444c425fa27 - "add support_additional_fields column"


def upgrade():
    # Les deux niveaux du formulaire Occhab auxquels un champ additionnel peut être rattaché.
    # Ce sont des objets de rattachement, sans permission associée : ils ne sont donc pas
    # déclarés dans gn_permissions.t_permissions_available (cf. METADATA_JEU_DE_DONNEES).
    op.execute("""
        INSERT INTO gn_permissions.t_objects
            (code_object, description_object, support_additional_fields)
        VALUES
            ('OCCHAB_STATION', 'Représente la table pr_occhab.t_stations', true),
            ('OCCHAB_HABITAT', 'Représente la table pr_occhab.t_habitats', true)
        ;
    """)
    op.execute("""
        UPDATE gn_commons.t_modules
        SET support_additional_fields = true
        WHERE module_code = 'OCCHAB'
        ;
    """)


def downgrade():
    # Les champs additionnels rattachés à ces objets perdraient leur rattachement :
    # on supprime les associations avant les objets eux-mêmes.
    op.execute("""
        DELETE FROM gn_commons.cor_field_object
        WHERE id_object IN (
            SELECT id_object
            FROM gn_permissions.t_objects
            WHERE code_object IN ('OCCHAB_STATION', 'OCCHAB_HABITAT')
        )
        ;
    """)
    op.execute("""
        DELETE FROM gn_permissions.t_objects
        WHERE code_object IN ('OCCHAB_STATION', 'OCCHAB_HABITAT')
        ;
    """)
    op.execute("""
        UPDATE gn_commons.t_modules
        SET support_additional_fields = false
        WHERE module_code = 'OCCHAB'
        ;
    """)
