from geonature.core.gn_permissions.decorators import login_required

from geonature.core.imports.models import Destination
from sqlalchemy.orm import joinedload
from geonature.core.imports.schemas import DestinationSchema
from geonature.core.imports.blueprint import blueprint
from geonature.utils.env import db


@blueprint.route("/destinations/", methods=["GET"])
@login_required
def list_destinations():
    schema = DestinationSchema()
    destinations = Destination.query.all()
    # FIXME: filter with C permissions?
    return schema.dump(destinations, many=True)


@blueprint.route("/destination/<destinationCode>", methods=["GET"])
@login_required
def get_destination(destinationCode):
    schema = DestinationSchema(only=["module"])
    destination = db.session.execute(
        db.select(Destination)
        .options(joinedload("module"))
        .where(Destination.code == destinationCode)
    ).scalar_one_or_none()
    return schema.dump(destination)
