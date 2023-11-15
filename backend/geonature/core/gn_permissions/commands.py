import click
from click import UsageError
import sqlalchemy as sa
from sqlalchemy.orm import contains_eager, joinedload
from sqlalchemy.orm.exc import MultipleResultsFound, NoResultFound

from pypnusershub.db.models import User

from geonature.utils.env import db
from geonature.core.gn_permissions.models import Permission, PermissionAvailable


@click.command(
    help="Ajouter des permissions administrateurs sur tous les modules pour un utilisateur ou un groupe."
)
@click.option("--id", "id_role", type=int)
@click.option("--nom", "nom_role")
@click.option("--prenom", "prenom_role")
@click.option("--group", "groupe", flag_value=True, default=None, help="Le rôle est un groupe.")
@click.option(
    "--user", "groupe", flag_value=False, default=None, help="Le rôle est un utilisateur."
)
@click.option(
    "--skip-existing",
    is_flag=True,
    help="Ne pas ajouter de permission administrateur s’il existe déjà une permission",
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Uniquement afficher les permissions nécessaires, sans les ajouter en base",
)
@click.option(
    "--yes",
    is_flag=True,
    help="Répond automatiquement oui à la confirmation",
)
def supergrant(skip_existing, dry_run, yes, **filters):
    filters = {k: v for k, v in filters.items() if v is not None}
    if not filters:
        raise UsageError("Veuillez sélectionner le rôle à promouvoir.")
    try:
        role = User.query.filter_by(**filters).one()
    except MultipleResultsFound:
        raise UsageError("Plusieurs rôles correspondent à vos filtres, veuillez les affiner.")
    except NoResultFound:
        raise UsageError("Aucun rôle ne correspond à vos filtres, veuillez les corriger.")
    if not yes:
        if not click.confirm(
            f"Ajouter les permissions administrateur au rôle {role.id_role} ({role.nom_complet}) ?",
        ):
            raise click.Abort()

    permission_available = db.scalars(
        db.select(PermissionAvailable)
        .outerjoin(
            Permission,
            sa.and_(PermissionAvailable.permissions, Permission.id_role == role.id_role),
        )
        .options(
            contains_eager(
                PermissionAvailable.permissions,
            ),
            joinedload(PermissionAvailable.module),
            joinedload(PermissionAvailable.object),
            joinedload(PermissionAvailable.action),
        )
    ).all()

    for ap in permission_available:
        for perm in ap.permissions:
            if skip_existing or not perm.filters:
                break
        else:
            # The role does not have any permission of this type,
            # or only permissions with at least one filter.
            # We add an new permission without any filters.
            click.echo(
                f"Nouvelle permission : module '{ap.module.module_code}', "
                f"objet '{ap.object.code_object}', action '{ap.action.code_action}'"
            )
            db.session.add(Permission(availability=ap, role=role))
    if not dry_run:
        db.session.commit()
