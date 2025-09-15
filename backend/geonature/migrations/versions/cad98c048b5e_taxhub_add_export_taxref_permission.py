"""Taxhub add export taxref permission

Revision ID: cad98c048b5e
Revises: a7f95c66819a
Create Date: 2025-09-15 11:32:26.833275

"""

from alembic import op
import sqlalchemy as sa

from geonature.utils.config import config


# revision identifiers, used by Alembic.
revision = "cad98c048b5e"
down_revision = "a7f95c66819a"
branch_labels = None
depends_on = None


def upgrade():
    op.get_bind().execute(
        sa.text(
            """
            INSERT INTO
                gn_permissions.t_permissions_available (
                    id_module,
                    id_object,
                    id_action,
                    scope_filter,
                    label
                )
            SELECT
                (SELECT id_module FROM gn_commons.t_modules m WHERE m.module_code = 'TAXHUB') AS id_module,
                (SELECT o.id_object FROM gn_permissions.t_objects o WHERE o.code_object = 'TAXONS') AS id_object,
                (SELECT a.id_action FROM gn_permissions.bib_actions a WHERE a.code_action = 'E') AS id_action,
                False AS scope_filter,
                'Exporter les taxons' AS label;
        """
        )
    )
    # rapatriement des permissions de l'application TaxHub

    op.execute(
        """
        INSERT INTO gn_permissions.t_permissions (id_role, id_action, id_module, id_object)
        SELECT tp.id_role,
            (SELECT a.id_action FROM gn_permissions.bib_actions a WHERE a.code_action = 'E') AS id_action,
            tp.id_module ,
            tp.id_object
        FROM gn_permissions.t_permissions tp
        WHERE
            id_module = (SELECT id_module FROM gn_commons.t_modules m WHERE m.module_code = 'TAXHUB')
            AND id_object = (SELECT o.id_object FROM gn_permissions.t_objects o WHERE o.code_object = 'TAXONS')
            AND id_action = (SELECT a.id_action FROM gn_permissions.bib_actions a WHERE a.code_action = 'R');
        """
    )


def downgrade():
    op.execute(
        """
        DELETE FROM gn_permissions.t_permissions
        WHERE
            id_module  = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'TAXHUB')
            AND id_object = (SELECT o.id_object FROM gn_permissions.t_objects o WHERE o.code_object = 'TAXONS')
            AND id_action = (SELECT a.id_action FROM gn_permissions.bib_actions a WHERE a.code_action = 'E');
        DELETE FROM gn_permissions.t_permissions_available
        WHERE
            id_module  = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'TAXHUB')
            AND id_object = (SELECT o.id_object FROM gn_permissions.t_objects o WHERE o.code_object = 'TAXONS')
            AND id_action = (SELECT a.id_action FROM gn_permissions.bib_actions a WHERE a.code_action = 'E');
        """
    )
