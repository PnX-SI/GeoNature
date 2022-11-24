"""declare available permissions

Revision ID: f9cf673d657a
Revises: 2984569d5df6
Create Date: 2021-10-08 10:23:39.085867

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f9cf673d657a"
down_revision = "2984569d5df6"
branch_labels = None
depends_on = ("3b2f3de760dc",)  # geonature with permissions managment


def upgrade():
    for action, label in [("C", "Créer"), ("R", "Lire"), ("E", "Exporter"), ("D", "Supprimer")]:
        op.execute(
            sa.text(
                """
        INSERT INTO gn_permissions.cor_module_action_object_filter (
            id_module, id_action, id_object, id_filter_type, code, label, description
        ) VALUES (
            gn_commons.get_id_module_bycode('OCCHAB'),
            gn_permissions.get_id_action(:action),
            gn_permissions.get_id_object('ALL'),
            gn_permissions.get_id_filter_type('SCOPE'),
            'OCCHAB-' || :action || '-ALL-SCOPE',
            :label || ' des données',
            :label || ' des données dans OccHab en étant limité par l''appartenance.'
        )
        """
            ).bindparams(action=action, label=label)
        )


def downgrade():
    op.execute(
        """
    DELETE FROM gn_permissions.cor_module_action_object_filter
        WHERE id_module = gn_commons.get_id_module_bycode('OCCHAB')
    """
    )
