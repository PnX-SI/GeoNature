"""[phyto] add module, source, permission

Revision ID: edba8d03ec71
Revises: d2c12d091e14
Create Date: 2026-05-19 14:18:22.862896

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "edba8d03ec71"
down_revision = None
branch_labels = ("occtax-phyto",)
depends_on = ("d2c12d091e14",)


def upgrade():
    op.execute(
        sa.text(
            """
                INSERT INTO gn_commons.t_modules (
                    module_code, module_label, module_picto, module_desc, module_path,
                    active_frontend, active_backend, ng_module
                ) VALUES (
                    'PHYTO', 'Phyto', 'fa-leaf', 'Module de saisie des relevés phytosociologiques (sous module Occtax)', 'phyto', TRUE, FALSE, 'occtax'
                );

                -- Création de la source dans la synthèse
                INSERT INTO gn_synthese.t_sources (
                    name_source, desc_source, entity_source_pk_field, url_source, id_module
                ) VALUES (
                    'Phyto (sous-module Occtax)', 'Données issues des relevés phytosociologiques',
                    'pr_occtax.cor_counting_occtax.id_counting_occtax', '#/phyto/info/id_counting', gn_commons.get_id_module_bycode('PHYTO')
                );

                INSERT INTO gn_permissions.t_permissions_available (
                    id_module, id_object, id_action, label, scope_filter
                )
                SELECT
                    m.id_module, o.id_object, a.id_action, v.label, v.scope_filter
                FROM (
                    VALUES
                        ('PHYTO', 'ALL', 'C', TRUE, 'Créer des relevés'),
                        ('PHYTO', 'ALL', 'R', TRUE, 'Voir les relevés'),
                        ('PHYTO', 'ALL', 'U', TRUE, 'Modifier les relevés'),
                        ('PHYTO', 'ALL', 'E', TRUE, 'Exporter les relevés'),
                        ('PHYTO', 'ALL', 'D', TRUE, 'Supprimer des relevés')
                ) AS v (module_code, object_code, action_code, scope_filter, label)
                JOIN gn_commons.t_modules m ON m.module_code = v.module_code
                JOIN gn_permissions.t_objects o ON o.code_object = v.object_code
                JOIN gn_permissions.bib_actions a ON a.code_action = v.action_code;
    """
        )
    )


def downgrade():
    op.execute(
        sa.text(
            """
                DELETE FROM gn_permissions.t_permissions_available
                WHERE id_module = gn_commons.get_id_module_bycode('PHYTO');

                DELETE FROM gn_synthese.t_sources
                WHERE id_module = gn_commons.get_id_module_bycode('PHYTO');

                DELETE FROM gn_commons.t_modules
                WHERE module_code = 'PHYTO';
    """
        )
    )
