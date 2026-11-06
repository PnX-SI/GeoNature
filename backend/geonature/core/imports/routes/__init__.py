from flask import g, request
from sqlalchemy import select
from sqlalchemy.orm import joinedload

from geonature.core.gn_commons.models import TModules
from geonature.core.imports.models import Destination
from geonature.core.gn_permissions.decorators import login_required
from geonature.core.imports.schemas import DestinationSchema
from geonature.core.imports.blueprint import blueprint
from geonature.utils.env import db


@blueprint.route("/destinations/", methods=["GET"], defaults={"action_code": None})
@blueprint.route("/destinations/<action_code>", methods=["GET"])
@login_required
def list_all_destinations(action_code):
    """
    Return the list of all destinations. If an action code is provided, only the destinations
    that the user has permission (based on the action_code) to access are returned.
    The list can also be filtered with the `module_code` query parameter.

    Parameters
    ----------
    action_code : str
        The action code to filter destinations. Possible values are 'C', 'R', 'U', 'V', 'E', 'D'.
    module_code : str, optional (query parameter)
        Only return the destinations attached to the module with this code.

    Returns
    -------
    destinations : List of Destination
        List of all destinations.
    """

    schema = DestinationSchema()
    query = select(Destination)
    if action_code:
        query = query.where(Destination.filter_by_role(g.current_user, action_code))
    if module_code := request.args.get("module_code"):
        query = query.where(Destination.module.has(TModules.module_code == module_code))
    destinations = db.session.execute(query).scalars().all()
    return schema.dump(destinations, many=True)


@blueprint.route("/destination/<destinationCode>", methods=["GET"])
@login_required
def get_destination(destinationCode):
    schema = DestinationSchema(only=["module"])
    destination = db.session.execute(
        select(Destination)
        .options(joinedload(Destination.module))
        .where(Destination.code == destinationCode)
    ).scalar_one_or_none()
    return schema.dump(destination)
