"""
    Module pour l'api post synthese et pour les fonctionalité d'échanges de données plus général
"""

from flask import Blueprint, request, current_app
from utils_flask_sqla.response import json_resp
from geonature.utils.env import DB, ROOT_DIR
from geonature.core.gn_permissions import decorators as permissions

from .repository import (
    get_synthese,
    create_or_update_synthese,
    delete_synthese,
    get_source,
    get_sources,
    create_or_update_source,
    delete_source,
)

from .util import pre_process_synthese_data, post_process_synthese_data, ApiSyntheseException


routes = Blueprint("gn_exchanges", __name__)


@routes.route(
    "/synthese/<int:id_synthese>",
    methods=["GET"],
    defaults={"unique_id_sinp": None, "id_source": None, "entity_source_pk_value": None},
)
@routes.route(
    "/synthese/<string:unique_id_sinp>",
    methods=["GET"],
    defaults={"id_synthese": None, "id_source": None, "entity_source_pk_value": None},
)
@routes.route(
    "/synthese/<int:id_source>/<entity_source_pk_value>",
    methods=["GET"],
    defaults={"id_synthese": None, "unique_id_sinp": None},
)
@permissions.check_cruved_scope("R", module_code="SYNTHESE")
@json_resp
def get_exchanges_synthese(id_synthese, unique_id_sinp, id_source, entity_source_pk_value):
    """
    get synthese for exchange
    """

    try:
        synthese = get_synthese(id_synthese, unique_id_sinp, id_source, entity_source_pk_value)
        return post_process_synthese_data(synthese.as_geofeature("the_geom_4326", "id_synthese"))

    except Exception as e:
        return f"Erreur {str(e)}", 500


def patch_or_post_exchange_synthese(
    is_post, id_synthese=None, unique_id_sinp=None, id_source=None, entity_source_pk_value=None
):
    """
    post or patch synthese for exchange

    post_data:
        nomenclature by code (code_type is supposed to be known)

    """

    try:
        post_data = request.json
        # check data
        # nomenclature code to synthese
        # etc...
        synthese_data = pre_process_synthese_data(post_data, is_post)
        synthese = create_or_update_synthese(
            synthese_data, id_synthese, unique_id_sinp, id_source, entity_source_pk_value
        )
        return post_process_synthese_data(synthese.as_geofeature("the_geom_4326", "id_synthese"))

    except ApiSyntheseException as e:
        return e.as_dict(), 500
    except Exception as e:
        return str(e), 500


@routes.route("/synthese/", methods=["POST"])
@permissions.check_cruved_scope("C", module_code="SYNTHESE")
@json_resp
def post_exchanges_synthese():
    """
    post put synthese for exchange
    """

    return patch_or_post_exchange_synthese(True)


# @routes.route("/synthese/<int:id_synthese>", methods=["PATCH", 'PUT'], defaults={'unique_id_sinp':None, 'id_source':None, 'entity_source_pk_value':None})
# @routes.route("/synthese/<string:unique_id_sinp>", methods=["PATCH", 'PUT'], defaults={'id_synthese':None, 'id_source':None, 'entity_source_pk_value':None})
@routes.route(
    "/synthese/<int:id_source>/<entity_source_pk_value>",
    methods=["PATCH", "PUT"],
    defaults={"id_synthese": None, "unique_id_sinp": None},
)
@permissions.check_cruved_scope("U", module_code="SYNTHESE")
@json_resp
def patch_exchanges_synthese(id_synthese, unique_id_sinp, id_source, entity_source_pk_value):
    """
    patch put synthese for exchange
    """

    return patch_or_post_exchange_synthese(
        False, id_synthese, unique_id_sinp, id_source, entity_source_pk_value
    )


# @routes.route("/synthese/<int:id_synthese>", methods=["DELETE"], defaults={'unique_id_sinp':None, 'id_source':None, 'entity_source_pk_value':None})
# @routes.route("/synthese/<string:unique_id_sinp>", methods=["DELETE"], defaults={'id_synthese':None, 'id_source':None, 'entity_source_pk_value':None})
@routes.route(
    "/synthese/<int:id_source>/<entity_source_pk_value>",
    methods=["DELETE"],
    defaults={"id_synthese": None, "unique_id_sinp": None},
)
@permissions.check_cruved_scope("D", module_code="SYNTHESE")
@json_resp
def delete_exchanges_synthese(id_synthese, unique_id_sinp, id_source, entity_source_pk_value):
    """
    delete synthese for exchange
    """

    id_synthese = None

    try:
        synthese = get_synthese(id_synthese, unique_id_sinp, id_source, entity_source_pk_value)
        id_synthese = synthese.id_synthese
        delete_synthese(synthese.id_synthese)
    except ApiSyntheseException as e:
        return e.as_dict(), 500
    except Exception as e:
        return str(e), 500

    return id_synthese


@routes.route("/sources", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SYNTHESE")
@json_resp
def api_get_sources():
    """
    api get source
    """
    try:
        sources = get_sources()
    except:
        return "Pas de sources définies", 500

    return [source.as_dict() for source in sources]


@routes.route("/source/<int:id_source>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SYNTHESE")
@json_resp
def api_get_source(id_source):
    """
    api get source
    """
    try:
        source = get_source(id_source)
    except:
        return "Pas de source défine pour (id_source={})".format(id_source), 500

    return source.as_dict()


def patch_or_post_exchange_source():
    """
    post or patchsource for exchange

    """

    post_data = request.json

    source = create_or_update_source(post_data)

    return source.as_dict()


@routes.route("/source/", methods=["PATCH"])
@permissions.check_cruved_scope("U", module_code="SYNTHESE")
@json_resp
def api_patch_source():
    """
    api patch source
    """

    return patch_or_post_exchange_source()


@routes.route("/source/", methods=["POST"])
@permissions.check_cruved_scope("C", module_code="SYNTHESE")
@json_resp
def api_post_source():
    """
    api post source
    """

    return patch_or_post_exchange_source()


@routes.route("/source/<int:id_source>", methods=["DELETE"])
@permissions.check_cruved_scope("D", module_code="SYNTHESE")
@json_resp
def api_delete_source(id_source):
    """
    api delete source
    """

    return delete_source(id_source)
