from flask import Blueprint, current_app, g

from geonature.core.gn_commons.models import TModules

from geonature.core.imports.models import Destination
import geonature.core.imports.admin  # noqa: F401

blueprint = Blueprint("import", __name__, template_folder="templates")


@blueprint.url_value_preprocessor
def set_current_destination(endpoint, values):
    if (
        current_app.url_map.is_endpoint_expecting(endpoint, "destination")
        and "destination" in values
    ):
        g.destination = values["destination"] = Destination.query.filter(
            Destination.code == values["destination"]
        ).first_or_404()


from .routes import (
    imports,
    mappings,
    fields,
)
from .commands import fix_mappings


blueprint.cli.add_command(fix_mappings)
