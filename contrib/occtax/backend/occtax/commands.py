import click

from geonature.utils.env import db


@click.command()
@click.argument("module_code", required=True)
def add_submodule_permissions(module_code):
    q = """
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
                     (:module_code, 'ALL', 'C', True, 'Créer des relevés')
                    ,(:module_code, 'ALL', 'R', True, 'Voir les relevés')
                    ,(:module_code, 'ALL', 'U', True, 'Modifier les relevés')
                    ,(:module_code, 'ALL', 'E', True, 'Exporter les relevés')
                    ,(:module_code, 'ALL', 'D', True, 'Supprimer des relevés')
            ) AS v (module_code, object_code, action_code, scope_filter, label)
        JOIN
            gn_commons.t_modules m ON m.module_code = v.module_code
        JOIN
            gn_permissions.t_objects o ON o.code_object = v.object_code
        JOIN
            gn_permissions.bib_actions a ON a.code_action = v.action_code
        """
    db.session.execute(q, {"module_code": module_code})
    db.session.commit()
    click.secho("DONE", fg="green")
