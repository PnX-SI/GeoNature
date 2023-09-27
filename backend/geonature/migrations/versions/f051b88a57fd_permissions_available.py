"""permissions available

Revision ID: f051b88a57fd
Revises: 7fe46b0e4729
Create Date: 2023-04-14 17:19:36.490766

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.types import Integer, Boolean, Unicode


# revision identifiers, used by Alembic.
revision = "f051b88a57fd"
down_revision = "7fe46b0e4729"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "t_permissions_available",
        sa.Column(
            "id_module",
            Integer,
            sa.ForeignKey("gn_commons.t_modules.id_module"),
            primary_key=True,
        ),
        sa.Column(
            "id_object",
            Integer,
            sa.ForeignKey("gn_permissions.t_objects.id_object"),
            primary_key=True,
        ),
        sa.Column(
            "id_action",
            Integer,
            sa.ForeignKey("gn_permissions.bib_actions.id_action"),
            primary_key=True,
        ),
        sa.Column(
            "label",
            Unicode,
        ),
        sa.Column(
            "scope_filter",
            Boolean,
            server_default=sa.false(),
        ),
        schema="gn_permissions",
    )
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_permissions_available (
                id_module,
                id_object,
                id_action,
                label,
                scope_filter
            )
        SELECT
            m.id_module,
            o.id_object,
            a.id_action,
            v.label,
            v.scope_filter
        FROM
            (
                VALUES
                     ('ADMIN', 'PERMISSIONS', 'C', False, 'Créer des permissions')
                    ,('ADMIN', 'PERMISSIONS', 'R', False, 'Voir les permissions')
                    ,('ADMIN', 'PERMISSIONS', 'U', False, 'Modifier les permissions')
                    ,('ADMIN', 'PERMISSIONS', 'E', False, 'Exporter les permissions')
                    ,('ADMIN', 'PERMISSIONS', 'D', False, 'Supprimer des permissions')
                    ,('ADMIN', 'NOMENCLATURES', 'C', False, 'Créer des nomenclatures')
                    ,('ADMIN', 'NOMENCLATURES', 'R', False, 'Voir les nomenclatures')
                    ,('ADMIN', 'NOMENCLATURES', 'U', False, 'Modifier les nomenclatures')
                    ,('ADMIN', 'NOMENCLATURES', 'E', False, 'Exporter les nomenclatures')
                    ,('ADMIN', 'NOMENCLATURES', 'D', False, 'Supprimer des nomenclatures')
                    ,('ADMIN', 'NOTIFICATIONS', 'C', False, 'Créer des entrées dans l’administration des notifications')
                    ,('ADMIN', 'NOTIFICATIONS', 'R', False, 'Voir les entrées dans l’administration des notifications')
                    ,('ADMIN', 'NOTIFICATIONS', 'U', False, 'Modifier des entrées dans l’administration des notifications')
                    ,('ADMIN', 'NOTIFICATIONS', 'E', False, 'Exporter les entrées dans l’administration des notifications')
                    ,('ADMIN', 'NOTIFICATIONS', 'D', False, 'Supprimer des entrées dans l’administration des notifications')
                    ,('ADMIN', 'ADDITIONAL_FIELDS', 'C', False, 'Créer des champs additionnels')
                    ,('ADMIN', 'ADDITIONAL_FIELDS', 'R', False, 'Voir les champs additionnels')
                    ,('ADMIN', 'ADDITIONAL_FIELDS', 'U', False, 'Modifier les champs additionnels')
                    ,('ADMIN', 'ADDITIONAL_FIELDS', 'E', False, 'Exporter les champs additionnels')
                    ,('ADMIN', 'ADDITIONAL_FIELDS', 'D', False, 'Supprimer des champs additionnels')
                    ,('ADMIN', 'MODULES', 'R', False, 'Voir les modules')
                    ,('ADMIN', 'MODULES', 'U', False, 'Modifier les modules')
                    ,('ADMIN', 'MODULES', 'E', False, 'Exporter les modules')
                    ,('ADMIN', 'MOBILE_APPS', 'C', False, 'Déclarer des applications mobiles')
                    ,('ADMIN', 'MOBILE_APPS', 'R', False, 'Voir les applications mobiles')
                    ,('ADMIN', 'MOBILE_APPS', 'U', False, 'Modifier les applications mobiles')
                    ,('ADMIN', 'MOBILE_APPS', 'E', False, 'Exporter les applications mobiles')
                    ,('ADMIN', 'MOBILE_APPS', 'D', False, 'Supprimer des applications mobiles')
                    ,('METADATA', 'ALL', 'C', False, 'Créer des métadonnées')
                    ,('METADATA', 'ALL', 'R', True, 'Voir les métadonnées')
                    ,('METADATA', 'ALL', 'U', True, 'Modifier les métadonnées')
                    ,('METADATA', 'ALL', 'E', True, 'Exporter les métadonnées')
                    ,('METADATA', 'ALL', 'D', True, 'Supprimer des métadonnées')
                    ,('SYNTHESE', 'ALL', 'R', True, 'Voir les observations')
                    ,('SYNTHESE', 'ALL', 'E', True, 'Exporter les observations')
            ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN
            gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN
            gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN
            gn_permissions.bib_actions a ON a.code_action = v.action_code
        """
    )
    op.execute(
        """
        WITH bad_permissions AS (
            SELECT
                p.id_permission
            FROM
                gn_permissions.t_permissions p
            JOIN gn_commons.t_modules m
                    USING (id_module)
            WHERE
                m.module_code IN ('GEONATURE', 'ADMIN', 'METADATA', 'SYNTHESE')
            EXCEPT
            SELECT
                p.id_permission
            FROM
                gn_permissions.t_permissions p
            JOIN gn_permissions.t_permissions_available pa ON
                (p.id_module = pa.id_module
                    AND p.id_object = pa.id_object
                    AND p.id_action = pa.id_action)
        )
        DELETE
        FROM
            gn_permissions.t_permissions p
                USING bad_permissions bp
        WHERE
            bp.id_permission = p.id_permission;
        """
    )


def downgrade():
    op.drop_table(schema="gn_permissions", table_name="t_permissions_available")
