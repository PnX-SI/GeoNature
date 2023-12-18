from geonature.core.gn_permissions.decorators import login_required

from geonature.core.imports.models import Destination
from geonature.core.imports.schemas import DestinationSchema
from geonature.core.imports.blueprint import blueprint


@blueprint.route("/destinations/", methods=["GET"])
@login_required
def list_destinations():
    schema = DestinationSchema()
    destinations = Destination.query.all()
    # FIXME: filter with C permissions?
    return schema.dump(destinations, many=True)
