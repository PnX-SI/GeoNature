"""notify synthese creation/update

Revision ID: 00a884207f90
Revises: cb663f039774
Create Date: 2026-05-08 11:46:46.128668

"""

from string import Template
from itertools import product
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "00a884207f90"
down_revision = "f6a1feb3f297"
branch_labels = None
depends_on = None

EMAIL_CONTENT = Template(
    "<p>Bonjour <i>{{{{ role.nom_complet }}}}</i> !</p>"
    "<p>{{% if observations|length > 1 %}}observations ont été {action}s{{% else %}} a été {action}{{% endif %}}</p>"
    "<table>"
    "{{% for observation in observations %}}"
    "<tr><td>{{{ observation.id_synthese }}}</td><td>{{{ observation.nom_cite }}}</td></tr>"
    "{{% endfor %}}"
    "</table>"
    '<p>Vous pouvez y accéder directement <a href="{{{ url }}}">ici</a></p>'
    "<p><i>Vous recevez cet email automatiquement via le service de notification de GeoNature.</i></p>"
)
DB_CONTENT = Template(
    "{{ observations|length }} {% if observations|length > 1 %}observations ont été ${action}s{% else %} observation a été ${action}{% endif %}"
)
CREATED_EMAIL_CONTENT = EMAIL_CONTENT.substitute({"action": "créée"})
CREATED_DB_CONTENT = DB_CONTENT.substitute({"action": "créée"})
UPDATED_EMAIL_CONTENT = EMAIL_CONTENT.substitute({"action": "modifié"})
UPDATED_DB_CONTENT = DB_CONTENT.substitute({"action": "modifié"})


def upgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)

    # We associate these categories to permission R on SYNTHESE/ALL
    module = sa.Table("t_modules", metadata, schema="gn_commons", autoload_with=conn)
    module_synthese_id = conn.scalar(
        sa.select(module.c.id_module).where(module.c.module_code == "SYNTHESE")
    )
    object = sa.Table("t_objects", metadata, schema="gn_permissions", autoload_with=conn)
    object_all_id = conn.scalar(sa.select(object.c.id_object).where(object.c.code_object == "ALL"))
    action = sa.Table("bib_actions", metadata, schema="gn_permissions", autoload_with=conn)
    action_read_id = conn.scalar(sa.select(action.c.id_action).where(action.c.code_action == "R"))

    # Add category
    notification_category = sa.Table(
        "bib_notifications_categories", metadata, schema="gn_notifications", autoload_with=conn
    )
    op.execute(
        sa.insert(notification_category).values(
            [
                {
                    "code": "SYNTHESE-OBS-CREATED",
                    "label": "Création d’une observation",
                    "description": "Se déclenche lorsqu'une observation est créée dans la synthèse.",
                    "id_module": module_synthese_id,
                    "id_object": object_all_id,
                    "id_action": action_read_id,
                },
                {
                    "code": "SYNTHESE-OBS-UPDATED",
                    "label": "Modification d’une observation",
                    "description": "Se déclenche lorsqu'une observation est modifiée dans la synthèse.",
                    "id_module": module_synthese_id,
                    "id_object": object_all_id,
                    "id_action": action_read_id,
                },
            ]
        )
    )

    notification_template = sa.Table(
        "bib_notifications_templates", metadata, schema="gn_notifications", autoload_with=conn
    )
    op.execute(
        sa.insert(notification_template).values(
            [
                {
                    "code_category": "SYNTHESE-OBS-CREATED",
                    "code_method": "EMAIL",
                    "content": CREATED_EMAIL_CONTENT,
                },
                {
                    "code_category": "SYNTHESE-OBS-CREATED",
                    "code_method": "DB",
                    "content": CREATED_DB_CONTENT,
                },
                {
                    "code_category": "SYNTHESE-OBS-UPDATED",
                    "code_method": "EMAIL",
                    "content": UPDATED_EMAIL_CONTENT,
                },
                {
                    "code_category": "SYNTHESE-OBS-UPDATED",
                    "code_method": "DB",
                    "content": UPDATED_DB_CONTENT,
                },
            ]
        )
    )

    notification_rule = sa.Table(
        "t_notifications_rules", metadata, schema="gn_notifications", autoload_with=conn
    )
    op.execute(
        sa.insert(notification_rule).values(
            [
                {"code_category": category, "code_method": method, "subscribed": False}
                for category, method in product(
                    ["SYNTHESE-OBS-CREATED", "SYNTHESE-OBS-UPDATED"], ["EMAIL", "DB"]
                )
            ]
        )
    )

    op.add_column(
        schema="gn_synthese",
        table_name="synthese",
        column=sa.Column(
            "meta_notification_date",
            sa.DateTime,
        ),
    )
    op.execute("""
        UPDATE gn_synthese.synthese
        SET meta_notification_date = now()
    """)


def downgrade():
    op.drop_column(
        schema="gn_synthese",
        table_name="synthese",
        column_name="meta_notification_date",
    )

    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    notification_category = sa.Table(
        "bib_notifications_categories", metadata, schema="gn_notifications", autoload_with=conn
    )
    notification_template = sa.Table(
        "bib_notifications_templates", metadata, schema="gn_notifications", autoload_with=conn
    )
    notification_rule = sa.Table(
        "t_notifications_rules", metadata, schema="gn_notifications", autoload_with=conn
    )
    categories_codes = list(
        conn.execute(
            sa.select(notification_category.c.code).where(
                notification_category.c.code.like("SYNTHESE-OBS-%")
            )
        ).scalars()
    )
    op.execute(
        sa.delete(notification_rule).where(notification_rule.c.code_category.in_(categories_codes))
    )
    op.execute(
        sa.delete(notification_template).where(
            notification_template.c.code_category.in_(categories_codes)
        )
    )
    op.execute(
        sa.delete(notification_category).where(notification_category.c.code.like("SYNTHESE-OBS-%"))
    )
