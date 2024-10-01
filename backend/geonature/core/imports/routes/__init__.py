from geonature.core.gn_permissions.decorators import login_required

from geonature.core.imports.models import Destination
from sqlalchemy.orm import joinedload
from geonature.core.imports.schemas import DestinationSchema
from geonature.core.imports.blueprint import blueprint
from geonature.utils.env import db
from flask_login import current_user


@blueprint.route("/destinations/", methods=["GET"])
@login_required
def list_destinations():
    schema = DestinationSchema()
    destinations = Destination.filter_by_permissions(current_user)
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
