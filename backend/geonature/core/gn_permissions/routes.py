"""
Routes of the gn_permissions blueprint
"""

import copy
import datetime
import json
import locale
import logging
import random
import uuid

from flask import (
    Blueprint,
    request,
    Response,
    render_template,
    session,
    current_app,
    url_for,
    redirect,
    jsonify
)
from sqlalchemy import (and_, cast, Date, distinct, func, or_)
from sqlalchemy.orm import (aliased, noload, exc)
from utils_flask_sqla.response import json_resp
from pypnusershub.db.models import (User, AppRole)

from geonature.core.gn_commons.models import TModules
from geonature.core.ref_geo.models import LAreas, BibAreasTypes
from geonature.core.taxonomie.models import Taxref
from geonature.core.users.models import (BibOrganismes, CorRole)
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.models import (
    BibFiltersType,
    BibFiltersValues,
    CorModuleActionObjectFilter,
    CorObjectModule,
    CorRoleActionFilterModuleObject,
    TActions,
    TFilters,
    TObjects,
    TRequests,
    RequestStates,
)
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.utils.env import DB
from geonature.utils.utilsmails import send_mail

# TODO : see how to define locale globaly => bug with python 3.7?
print(f"Current locale: {locale.getlocale(locale.LC_TIME)}")
locale.setlocale(locale.LC_TIME, "fr_FR.UTF-8")

log = logging.getLogger(__name__)

routes = Blueprint("gn_permissions", __name__, template_folder="templates")


@routes.route("/cruved", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_cruved(info_role):
    """
    Get the cruved for a user

    .. :quickref: Permissions;

    Params:
    :param user: the user who ask the route, auto kwargs via @check_cruved_scope
    :type user: User
    :param module_code: the code of the requested module, or multiples codes comma separated - as querystring
    :type module_code: str

    :returns: dict of the CRUVED
    """
    params = request.args.to_dict()

    # get modules
    q = DB.session.query(TModules)
    if "module_code" in params:
        codes = params["module_code"].split(',')
        q = q.filter(TModules.module_code.in_(codes))
    modules = q.all()

    # for each modules get its cruved
    # then get its related object and their cruved
    modules_with_cruved = {}
    for mod in modules:
        mod_as_dict = mod.as_dict()
        # get mod objects
        module_objects = (
            DB.session.query(TObjects)
            .join(CorObjectModule, CorObjectModule.id_object == TObjects.id_object)
            .filter_by(id_module=mod_as_dict["id_module"])
            .all()
        )

        module_cruved, herited = cruved_scope_for_user_in_module(
            id_role=info_role.id_role, module_code=mod_as_dict["module_code"]
        )
        mod_as_dict["cruved"] = module_cruved

        module_objects_as_dict = {}
        # get cruved for each object
        for _object in module_objects:
            object_as_dict = _object.as_dict()
            object_cruved, herited = cruved_scope_for_user_in_module(
                id_role=info_role.id_role,
                module_code=mod_as_dict["module_code"],
                object_code=_object.code_object,
            )
            object_as_dict["cruved"] = object_cruved
            module_objects_as_dict[object_as_dict["code_object"]] = object_as_dict

            mod_as_dict["module_objects"] = module_objects_as_dict

        modules_with_cruved[mod_as_dict["module_code"]] = mod_as_dict

    return modules_with_cruved


@routes.route("/logout_cruved", methods=["GET"])
def logout():
    """
    Route to logout with cruved

    .. :quickref: Permissions;

    To avoid multiples server call, we store the cruved in the session
    when the user logout we need clear the session to get the new cruved session
    """
    copy_session_key = copy.copy(session)
    for key in copy_session_key:
        session.pop(key)
    return Response("Logout", 200)


@routes.route("/access_requests", methods=["POST"])
@permissions.check_cruved_scope(action='R', get_role=True)
@json_resp
def post_access_request(info_role):
    """
    Post an access request.

    .. :quickref: Permissions;
    """
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Transform received data
    data = dict(request.get_json())
    end_access_date = format_end_access_date(data["end_access_date"])
    geographic_filter = build_value_filter_from_list(unduplicate_values(data["areas"]))
    taxonomic_filter = build_value_filter_from_list(unduplicate_values(data["taxa"]))
    user_id = info_role.id_role

    # Prepare TRequests
    trequest = TRequests(**{
        "id_role": user_id,
        "end_date": end_access_date,
        "processed_state": RequestStates.pending,
        "additional_data": data["additional_data"],
        "geographic_filter": geographic_filter,
        "taxonomic_filter": taxonomic_filter,
        "sensitive_access": data["sensitive_access"],
    })

    # Write request_data in database
    DB.session.add(trequest)
    DB.session.commit()

    # Inform about new access request by email
    send_email_after_access_request(
        data=data,
        user_id=user_id,
        request_token=trequest.token,
    )

    #return request.as_dict(True)
    response = {
        "message": "Succès de l'ajout de la demande d'accès.",
        "status": "success"
    }
    return response, 200


def format_end_access_date(end_date, date_format="%Y-%m-%d"):
    formated_end_date = None
    if (end_date):
        date = datetime.date(end_date["year"], end_date["month"], end_date["day"])
        formated_end_date = date.strftime(date_format)
    return formated_end_date


def unduplicate_values(data: list) -> list:
    unduplicated_data = []
    [unduplicated_data.append(x) for x in data if x not in unduplicated_data]
    return unduplicated_data


def send_email_after_access_request(data, user_id, request_token):
    recipients = current_app.config["PERMISSION_MANAGEMENT"]["VALIDATOR_EMAIL"]
    app_name = current_app.config["appName"]
    subject = f"Demande de permissions d'accès {app_name}"
    msg_html = render_request_approval_tpl(user_id, data, request_token)
    send_mail(recipients, subject, msg_html)


def render_request_approval_tpl(user_id, data, request_token):
    template = "email_admin_request_approval.html"
    approval_url = url_for(
        "gn_permissions.manage_access_request_by_link",
        token=request_token,
        action="approve",
    )
    refusal_url = url_for(
        "gn_permissions.manage_access_request_by_link",
        token=request_token,
        action="refuse",
    )
    return render_template(
        template,
        app_name=current_app.config["appName"],
        end_date=format_end_access_date(data["end_access_date"], date_format="%x"),
        user=get_user_infos(user_id),
        geographic_filter_values=format_geographic_filter_values(data["areas"]),
        taxonomic_filter_values=format_taxonomic_filter_values(data["taxa"]),
        sensitive_permission=data["sensitive_access"],
        additional_fields=format_additional_fields(data["additional_data"]),
        approval_url=approval_url,
        refusal_url=refusal_url,
        app_url = current_app.config["URL_APPLICATION"] + "/#/permissions/requests/pending",
    )


def get_user_infos(user_id):
    user = (DB
        .session.query(User)
        .filter(User.id_role == user_id)
        .first()
        .as_dict()
    )
    return user


def format_geographic_filter_values(areas: [int]):
    formated_geo = []
    if len(areas) > 0:
        for area in get_areas_infos(areas):
            name = area["area_name"]
            code = area["area_code"]
            if area["type_code"] == "DEP":
                name = f"{name} [{code}]"
            elif area["type_code"] == "COM":
                name = f"{name} [{code[:2]}]"
            formated_geo.append(name)
    return formated_geo


def get_areas_infos(area_ids: [int]):
    data = (DB
        .session.query(
            LAreas.area_name,
            LAreas.area_code,
            BibAreasTypes.type_code
        )
        .join(LAreas, LAreas.id_type == BibAreasTypes.id_type)
        .filter(LAreas.id_area.in_(tuple(area_ids)))
        .all()
    )
    return [row._asdict() for row in data]


def format_taxonomic_filter_values(taxa: [int]):
    formated_taxonomic = []
    if len(taxa) > 0:
        for taxon in get_taxons_infos(taxa):
            name = taxon["nom_complet_html"]
            code = taxon["cd_nom"]
            formated_taxonomic.append(f"{name} [{code}]")
    return formated_taxonomic


def get_taxons_infos(taxon_ids: [int]):
    data = (DB
        .session.query(Taxref)
        .filter(Taxref.cd_nom.in_(tuple(taxon_ids)))
        .all()
    )
    return [row.as_dict() for row in data]


def format_additional_fields(data):
    if data is None:
        return []

    attr_infos = build_dynamic_request_form_infos()
    attr_keys = attr_infos.keys()
    formated_fields = []
    for key, value in (data or {}).items():
        if key in attr_keys:
            cfg = {
                "key": key,
                "label": attr_infos.get(key)["label"],
                "value": value,
            }
            for attr_infos_key, attr_infos_value in attr_infos.get(key).items():
                cfg[attr_infos_key] = attr_infos_value
            formated_fields.append(cfg)
    return formated_fields


def build_dynamic_request_form_infos():
    attr_infos = {}
    form_cfg = current_app.config["PERMISSION_MANAGEMENT"]["REQUEST_FORM"]
    for cfg in form_cfg:
        if all(key in cfg for key in ("type_widget", "attribut_name", "attribut_label")):
            attr_infos[cfg["attribut_name"]] = {
                "type": cfg["type_widget"],
                "label": cfg["attribut_label"],
            }
        if "icon" in cfg:
            attr_infos[cfg["attribut_name"]]["icon"] = cfg["icon"]
        if "icon_set" in cfg:
            attr_infos[cfg["attribut_name"]]["iconSet"] = cfg["icon_set"]

    return attr_infos


@routes.route("/access_requests/<token>/<action>", methods=["GET"])
def manage_access_request_by_link(token, action):
    """
        Approuve/Refuse une demande de permissions d'accès.
        ATTENTION : ce webservice modifie une demande d'accès via la
        méthode HTTP GET.
        Dénormalisation permettant de lancer ces actions via un lien
        envoyé par email.
    """
    # Check if permission management is enable on this GeoNature instance
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Check "action" URL parameter values
    accepted_actions = ["approve", "refuse"]
    if action not in accepted_actions:
        accepted_values_msg = f"Valeurs acceptées : {', '.join(accepted_actions)}."
        response = {
            "message": f"Type d'action '{action}' inconnu. {accepted_values_msg}",
            "status": "error"
        }
        return response, 400

    # Check access request token was defined
    if token is None:
        response = {
            "message": "Token de demande de permission non défini.",
            "status": "error"
        }
        return response, 404

    # Check access request token exists in DB
    request = get_request_by_token(token)
    if not request:
        response = {
            "message": "Token de demande de permission introuvable.",
            "status": "error"
        }
        return response, 404

    # Check if access request was not already approved or refused
    if request["processed_date"]:
        date = request["processed_date"]
        status = get_status(request["processed_state"])
        msg = f"Demande de permission déjà {status} le {date}. Utiliser l'interface d'administration.",
        response = {"message": msg, "status": "error"}
        return response, 400

    # Update access request
    request["processed_state"] = (
        RequestStates.accepted if action == "approve" else RequestStates.refused
    )
    request["processed_date"] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    result = (DB.session
        .query(TRequests)
        .filter(TRequests.token == token)
        .update({
            TRequests.processed_state: request["processed_state"],
            TRequests.processed_date: request["processed_date"],
        })
    )

    # Add asked permissions to authorized permissions table if request approve
    if action == "approve":
        add_permission(request)

    # Commit DB session
    DB.session.commit()

    # Send email to user
    send_email_after_managing_request(request)

    # Redirect to GeoNature app home page
    return redirect(current_app.config["URL_APPLICATION"], code=302)


def get_request_by_token(token):
    try:
        data = (DB
            .session.query(TRequests)
            .filter(TRequests.token == token)
            .one()
            .as_dict()
        )
    except exc.NoResultFound:
        return False
    return data

def get_status(state):
    if state == RequestStates.accepted :
        return "acceptée"
    if state == RequestStates.pending :
        return "mise en attente"
    if state ==RequestStates.refused :
        return "refusée"


def add_permission(request):
    # Build default permissions for access request
    default_permissions = get_access_request_default_permissions(request)
    
    # Add additional data to each permission
    for perm in default_permissions:
        perm["id_request"] = request["id_request"]
        perm["gathering"] = uuid.uuid4()

    # Get new permission with filters added
    new_permissions = get_permissions_with_filters(request, default_permissions)

    # TODO: check if this permission with all this specific filters already exist

    # Persists permissions in database
    for permission in new_permissions:
        if not permission.is_already_exist():
            # TODO: remove permission_filter managment !
            permission_filter = get_filter(
                id_filter_type=permission.id_filter_type,
                value_filter=permission.value_filter,
            )
            if not permission_filter:
                filter_type_label = get_filter_type_label(permission.id_filter_type)
                permission_filter = TFilters(
                    label_filter=f"{filter_type_label} : {permission.value_filter}",
                    id_filter_type=permission.id_filter_type,
                    value_filter=permission.value_filter,
                )
            permission.filter.append(permission_filter)

            DB.session.add(permission)


def get_access_request_default_permissions(request):
    default_permissions = [
        {
            "module_code": "SYNTHESE", 
            "action_code": "R", 
            "object_code": "PRIVATE_OBSERVATION",
        },
        {
            "module_code": "SYNTHESE", 
            "action_code": "E", 
            "object_code": "PRIVATE_OBSERVATION",
        },
        {
            "module_code": "VALIDATION", 
            "action_code": "R", 
            "object_code": "PRIVATE_OBSERVATION",
        },
    ]
    
    # Add new permissions for sensitive observations
    if (request["sensitive_access"] is True):
        default_sensitive_permissions = copy.deepcopy(default_permissions)
        for permission in default_sensitive_permissions:
            permission["object_code"] = "SENSITIVE_OBSERVATION" 
        default_permissions.extend(default_sensitive_permissions)
    
    return default_permissions



def get_permissions_with_filters(request, default_permissions):
    permissions_with_filters = []

    # Add mandatory PROPERTY (=SCOPE) filter
    permissions = get_property_permissions(default_permissions)
    for perm in permissions:
        perm.id_role = request["id_role"]
        perm.end_date = request["end_date"]
        perm.value_filter = "3"# À tous le monde
        permissions_with_filters.append(perm)

    # Add Geo and Taxo filters to each permission
    if (request["geographic_filter"]):
        areas = split_value_filter(request["geographic_filter"])
        permissions = get_geographic_permissions(default_permissions)
        for perm in permissions:
            perm.id_role = request["id_role"]
            perm.end_date = request["end_date"]
            perm.value_filter = build_value_filter_from_list(areas)
            permissions_with_filters.append(perm)

    if (request["taxonomic_filter"]):
        taxa = split_value_filter(request["taxonomic_filter"])
        permissions = get_taxonomic_permissions(default_permissions)
        for perm in permissions:
            perm.id_role = request["id_role"]
            perm.end_date = request["end_date"]
            perm.value_filter = build_value_filter_from_list(taxa)
            permissions_with_filters.append(perm)

    # Precision filter
    permissions = get_precision_permissions(default_permissions)
    for perm in permissions:
        perm.id_role = request["id_role"]
        perm.end_date = request["end_date"]
        perm.value_filter = "exact"
        permissions_with_filters.append(perm)
    
    return permissions_with_filters


def split_value_filter(data: str):
    values = data.split(',')
    unduplicated_data = unduplicate_values(values)
    return unduplicated_data


def get_geographic_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "GEOGRAPHIC"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_taxonomic_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "TAXONOMIC"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_precision_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "PRECISION"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions

def get_property_permissions(default_permissions):
    permissions = []
    for new_perm in default_permissions:
        new_perm["filter_type_code"] = "SCOPE" # TODO: rename to PROPERTY...
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_fresh_permission(filter_type_code, module_code, action_code, object_code, gathering=None, id_request=None):
    permission_module = DB.session.query(TModules).filter(TModules.module_code == module_code).one()
    permission_action = DB.session.query(TActions).filter(TActions.code_action == action_code).one()
    permission_object = DB.session.query(TObjects).filter(TObjects.code_object == object_code).one()
    permission_filter_type = (DB.session
        .query(BibFiltersType)
        .filter(BibFiltersType.code_filter_type == filter_type_code)
        .one()
    )
    
    # Prepare fresh permission
    permission = CorRoleActionFilterModuleObject(
        id_module=permission_module.id_module,
        id_action=permission_action.id_action,
        id_object=permission_object.id_object,
        id_filter=0,# TODO: remove this line !
        id_filter_type=permission_filter_type.id_filter_type,
    )
    
    # Add gathering and id_request only if defined
    if gathering:
        permission.gathering = gathering
    if id_request:
        permission.id_request = id_request

    return permission


def build_value_filter_from_list(data: list):
    unduplicated_data = unduplicate_values(data)
    return ",".join(map(str, unduplicated_data))


def get_filter(id_filter_type, value_filter):
    try:
        permission_filter = (DB
            .session.query(TFilters)
            .filter(TFilters.id_filter_type == id_filter_type)
            .filter(TFilters.value_filter == value_filter)
            .one()
        )
    except exc.NoResultFound:
        return False
    return permission_filter


def get_filter_type_label(id_filter_type):
    try:
        label = (DB
            .session.query(BibFiltersType.label_filter_type)
            .filter(BibFiltersType.id_filter_type == id_filter_type)
            .one()[0]
        )
    except exc.NoResultFound:
        return False
    return label


def send_email_after_managing_request(request):
    user = get_user_infos(request["id_role"])
    recipient = user["email"]
    app_name = current_app.config["appName"]
    if request["processed_state"] == RequestStates.accepted:
        subject = f"Acceptation de demande de permissions d'accès {app_name}"
        msg_html = render_accepted_request_tpl(user, request)
    elif request["processed_state"] == RequestStates.pending:
        subject = f"Mise en attente de la demande de permissions d'accès {app_name}"
        msg_html = render_pending_request_tpl(user, request)
    else:
        subject = f"Refus de demande de permissions d'accès {app_name}"
        msg_html = render_refused_request_tpl(user, request)
    send_mail(recipient, subject, msg_html)


def render_accepted_request_tpl(user, request):
    areas = split_value_filter(request["geographic_filter"])
    taxa = split_value_filter(request["taxonomic_filter"])
    date = datetime.datetime.strptime(request["end_date"], "%Y-%m-%d")
    end_date = date.strftime("%x")
    return render_template(
        "email_user_request_accepted.html",
        app_name=current_app.config["appName"],
        user=user,
        validators=get_validators(),
        sensitive_permission=request["sensitive_access"],
        geographic_filter_values=format_geographic_filter_values(areas),
        taxonomic_filter_values=format_taxonomic_filter_values(taxa),
        end_date=end_date,
        app_url=current_app.config["URL_APPLICATION"],
    )


def render_pending_request_tpl(user, request):
    areas = split_value_filter(request["geographic_filter"])
    taxa = split_value_filter(request["taxonomic_filter"])
    date = datetime.datetime.strptime(request["end_date"], "%Y-%m-%d")
    end_date = date.strftime("%x")
    return render_template(
        "email_user_request_pending.html",
        app_name=current_app.config["appName"],
        user=user,
        validators=get_validators(),
        sensitive_permission=request["sensitive_access"],
        geographic_filter_values=format_geographic_filter_values(areas),
        taxonomic_filter_values=format_taxonomic_filter_values(taxa),
        end_date=end_date,
    )


def render_refused_request_tpl(user, request):
    areas = split_value_filter(request["geographic_filter"])
    taxa = split_value_filter(request["taxonomic_filter"])
    date = datetime.datetime.strptime(request["end_date"], "%Y-%m-%d")
    end_date = date.strftime("%x")
    return render_template(
        "email_user_request_refused.html",
        app_name=current_app.config["appName"],
        user=user,
        validators=get_validators(),
        sensitive_permission=request["sensitive_access"],
        geographic_filter_values=format_geographic_filter_values(areas),
        taxonomic_filter_values=format_taxonomic_filter_values(taxa),
        end_date=end_date,
        refusal_reason=request["refusal_reason"],
    )


def get_validators():
    validators = current_app.config["PERMISSION_MANAGEMENT"]["VALIDATOR_EMAIL"]
    if isinstance(validators, list):
       validators = ", ".join(validators)
    return validators.strip()


# TODO: Delete if not used !
@routes.route("/modules", methods=["GET"])
def get_all_modules():
    """
    Retourne tous les modules.

    .. :quickref: Permissions;

    Params:
    :param codes: filtre permetant de récupérer seulement les modules
    pour un ou plusieurs codes données séparés par des virgules.

    :returns: un tableau de dictionnaire contenant les infos des modules.
    """
    # Get params
    params = request.args.to_dict()

    query = DB.session.query(TModules)
    if "codes" in params:
        codes = params["codes"].split(',')
        query = query.filter(TModules.module_code.in_(codes))

    modules = []
    for mdl in query.all():
        modules.append(mdl.as_dict())

    output = prepare_output(modules, remove_in_key="module")
    return jsonify(output), 200


# TODO: Delete if not used !
@routes.route("/actions", methods=["GET"])
def get_all_actions():
    """
    Retourne toutes les actions.

    .. :quickref: Permissions;

    :returns: un tableau de dictionnaire contenant les infos des actions.
    """
    q = DB.session.query(TActions)
    actions = []
    for act in q.all():
        actions.append(act.as_dict())

    output = prepare_output(actions, remove_in_key="action")
    return jsonify(output), 200


# TODO: Delete if not used !
@routes.route("/filters", methods=["GET"])
def get_all_filters():
    """
    Retourne tous les types de filtres.

    .. :quickref: Permissions;

    :returns: un tableau de dictionnaire contenant les infos des filtres.
    """
    q = DB.session.query(BibFiltersType)
    filters = []
    for fit in q.all():
        filters.append(fit.as_dict())
    
    output = prepare_output(filters, remove_in_key="filter_type")
    return jsonify(output), 200

# TODO: Delete if not used !
@routes.route("/filters-values", methods=["GET"])
def get_all_filters_values():
    """
    Retourne toutes les valeurs des différents types de filtres.

    .. :quickref: Permissions;

    :returns: un dictionnaire dont les attributs correspondent aux codes 
    des types de filtres et les valeurs à des tableaux des valeurs des
    filtres correspondantes.
    """
    q = (
        DB.session
        .query(BibFiltersValues, BibFiltersType.code_filter_type)
        .join(
            BibFiltersType, 
            BibFiltersType.id_filter_type == BibFiltersValues.id_filter_type
        )
        .order_by(
            BibFiltersValues.id_filter_type,
            BibFiltersValues.value_or_field,
        )
    )

    filters_values = {}
    for item in q.all():
        (bib_filter_value, code) = item
        
        if code not in filters_values.keys():
            filters_values[code] = []
        
        # Prepare filter value
        fvalue = bib_filter_value.as_dict()
        fvalue["filter_type_code"] = code
        fvalue["filter_type_id"] = fvalue["id_filter_type"]
        del fvalue["id_filter_type"]
        if (fvalue["predefined"]):
            fvalue["value"] = fvalue["value_or_field"]

        filters_values[code].append(fvalue)
    
    output = prepare_output(filters_values, remove_in_key="filter_value")
    return jsonify(output), 200



# TODO: Delete if not used !
@routes.route("/objects", methods=["GET"])
def get_all_objects():
    """
    Retourne toutes les objets.

    .. :quickref: Permissions;

    :returns: un tableau de dictionnaire contenant les infos des objets.
    """
    q = DB.session.query(TObjects)
    objects = []
    for obj in q.all():
        objects.append(obj.as_dict())

    output = prepare_output(objects, remove_in_key="object")
    return jsonify(output), 200


@routes.route("/requests", methods=["GET"])
#@json_resp
def get_permissions_requests():
    """
    Retourne toutes les demandes de permissions avec des info sur 
    l'utilisateur ayant fait la demande.

    .. :quickref: Permissions;
    
    Params:
    :param state: filtre permetant de récupérer seulement les requêtes
    acceptées (accepted), refusées (refused), refusées et acceptées 
    (processed) ou en attentes (pending).
    :type state: 'accepted', 'refused', 'processed', 'pending'

    :returns: un tableau de dictionnaire contenant les infos des demandes
    de permissions.
    """
    # Get params
    params = request.args.to_dict()
    
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Check "state" values validity
    state_accepted_values = ["accepted", "refused", "processed", "pending"]
    if "state" in params and params["state"] not in state_accepted_values:
        msg = (
            f"Valeur « {params['state']} » du paramère « state » inconnue. "
            + f"Valeurs acceptées : {', '.join(state_accepted_values)}"
        )
        response = {
            "message": msg,
            "status": "warning"
        }
        return response, 400

    # Get requests
    UserAsker = aliased(User)
    UserValidator = aliased(User)
    query = (
        DB.session.query(TRequests, UserAsker, BibOrganismes, UserValidator)
            .join(UserAsker, UserAsker.id_role == TRequests.id_role)
            .join(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme, isouter=True)
            .join(UserValidator, UserValidator.id_role == TRequests.processed_by, isouter=True)
            .order_by(TRequests.meta_create_date)
    )
    
    if "state" in params:
        if params["state"] == "processed":
            query = query.filter(
                or_(
                    TRequests.processed_state == RequestStates.accepted, 
                    TRequests.processed_state == RequestStates.refused, 
                )
            )
        else:
            query = query.filter(TRequests.processed_state == RequestStates(params["state"]))
    results = query.all()

    requests = []
    for result in results:
        access_request = formatAccessRequest(*result)
        requests.append(access_request)
        
    output = prepare_output(requests)
    return jsonify(output), 200


@routes.route("/requests/<token>", methods=["GET"])
def get_permissions_requests_by_token(token):
    """
    Retourne le détail d'une demande.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos d'une demande de permission.
    """
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    UserAsker = aliased(User)
    UserValidator = aliased(User)
    query = (
        DB.session.query(TRequests, UserAsker, BibOrganismes, UserValidator)
            .join(UserAsker, UserAsker.id_role == TRequests.id_role)
            .join(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme, isouter=True)
            .join(UserValidator, UserValidator.id_role == TRequests.processed_by, isouter=True)
            .filter(TRequests.token == token)
    )
    results = query.first()

    if not results:
        response = {
            "message": f"Token de demande introuvable : {token} .",
            "status": "error"
        }
        return response, 404
    
    response = formatAccessRequest(*results)
    response = prepare_output(response)
    return response, 200


@routes.route("/requests/<token>", methods=["PATCH"])
@permissions.check_cruved_scope(action='U', get_role=True)
@json_resp
def patch_permissions_request_by_token(info_role, token):
    """
    Modifier partiellement une demande d'accès.

    Utilisé pour accepter ou refuser une demande en modifiant son état.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos de la demande modifiée.
    """
    # Check if permissions management is enable
    if not current_app.config["PERMISSION_MANAGEMENT"]["ENABLE_ACCESS_REQUEST"]:
        response = {
            "message": "Demande de permissions d'accès non activé sur cette instance de Geonature.",
            "status": "warning"
        }
        return response, 403

    # Transform received data
    role = get_user_infos(info_role.id_role)
    data = prepare_input(dict(request.get_json()))
    refusal_reason = data.get("refusal_reason", None)
    if RequestStates(data.get("processed_state")) != RequestStates.refused:
        refusal_reason = None

    # Load TRequest
    trequest = DB.session.query(TRequests).filter(TRequests.token == token).first()
    if not trequest:
        response = {
            "message": f"Token de demande introuvable : {token} .",
            "status": "error"
        }
        return response, 404

    # Prepare TRequests
    trequest.processed_date = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    trequest.processed_by = role.get("id_role")
    trequest.processed_state = RequestStates(data.get("processed_state"))
    trequest.refusal_reason = refusal_reason

    # Update TRequest
    DB.session.merge(trequest)

    # Update Permissions according to access request state
    if trequest.processed_state == RequestStates.accepted:
        add_permission(trequest.as_dict())
    else:
        remove_permission_by_request(trequest.as_dict())

    # Commit update in DB
    DB.session.commit()
    DB.session.flush()

    # Send email to user
    send_email_after_managing_request(trequest.as_dict())

    # Get updated TRequests
    UserAsker = aliased(User)
    UserValidator = aliased(User)
    results = (
        DB.session.query(TRequests, UserAsker, BibOrganismes, UserValidator)
            .join(UserAsker, UserAsker.id_role == TRequests.id_role)
            .join(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme, isouter=True)
            .join(UserValidator, UserValidator.id_role == TRequests.processed_by, isouter=True)
            .filter(TRequests.token == token)
            .first()
    )

    # Prepare response
    access_request = formatAccessRequest(*results)
    response = prepare_output(access_request)
    return response, 200


def remove_permission_by_request(request):
    # Remove permissions in database
    try:
        query = (
            DB.session
            .query(CorRoleActionFilterModuleObject)
            .filter(CorRoleActionFilterModuleObject.id_request == request['id_request'])
        )
        result = query.first()
        DB.session.delete(result)
    except exc.NoResultFound:
        log.info("No permissions found. No permissions to remove.")
    except Exception as exp:
        log.error("Permissions deletion error: %s", exp)


def formatAccessRequest(request, asker, asker_organism, validator):
    taxa = split_value_filter(request.taxonomic_filter)
    areas = split_value_filter(request.geographic_filter)
    sensitive = request.sensitive_access
    access_request = {
        "token": request.token,
        "user_name": formatRoleName(asker),
        "organism_name": (asker_organism.nom_organisme if asker_organism else "-"),
        "geographic_filters": areas,
        "geographic_filters_labels": format_geographic_filter_values(areas),
        "taxonomic_filters": taxa,
        "taxonomic_filters_labels": format_taxonomic_filter_values(taxa),
        "sensitive_access": sensitive,
        "end_access_date": request.end_date.strftime("%Y-%m-%d"),
        "processed_state": request.processed_state,
        "processed_date": request.processed_date,
        "processed_by": request.processed_by,
        "refusal_reason": request.refusal_reason,
        "additional_data": format_additional_fields(request.additional_data),
        "meta_create_date": request.meta_create_date.strftime("%Y-%m-%d %H:%M:%S"),
        "meta_update_date": request.meta_update_date.strftime("%Y-%m-%d %H:%M:%S"),
    }
    if request.processed_date:
        access_request["processed_date"] = request.processed_date.strftime("%Y-%m-%d %H:%M:%S")
    if request.processed_by:
        access_request["processed_by"] = f"{validator.prenom_role} {validator.nom_role}"
    return access_request


# TODO: Delete this route if not used !
@routes.route("/requests/<token>", methods=["PUT"])
@permissions.check_cruved_scope(action='U', get_role=True)
@json_resp
def update_permissions_requests_by_token(token):
    """
    Modifier une demande d'accès.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos de la demande modifiée.
    """
    response = {
            "message": f"Update permission request is not implemented yet !",
            "status": "error"
        }
    return response, 501


@routes.route("/roles", methods=["GET"])
@permissions.check_cruved_scope("R", True, object_code="PERMISSION")
@json_resp
def get_permissions_for_all_roles(info_role):
    """
    Retourne tous les rôles avec leurs permissions.

    .. :quickref: Permissions;

    :returns: un tableau de dictionnaire contenant les infos du rôle et 
    ses permissions.
    """
    # Get params
    params = request.args.to_dict()

    # Get roles with permissions
    # TODO: use AppRole instead of User and BibOrganismes
    query = (
        DB.session.query(
                User, 
                BibOrganismes, 
                func.count(distinct(CorRoleActionFilterModuleObject.gathering))
            )
            .join(AppRole, AppRole.id_role == User.id_role)
            .outerjoin(CorRoleActionFilterModuleObject, CorRoleActionFilterModuleObject.id_role == User.id_role)
            .outerjoin(BibOrganismes, BibOrganismes.id_organisme == User.id_organisme)
            .filter(AppRole.id_application == current_app.config["ID_APPLICATION_GEONATURE"])
            .group_by(
                User.id_role,
                BibOrganismes.id_organisme
            )
            .order_by(User.groupe.desc(), User.prenom_role, User.nom_role)
    )

    # Filter with user authentified permissions
    if info_role.value_filter == "2":
        query = query.filter(BibOrganismes.id_organisme == info_role.id_organisme)
    elif info_role.value_filter == "1":
        query = query.filter(User.id_role == info_role.id_role)
    
    results = query.all()
    
    roles = []
    for result in results:
        (user, organism, permissions_number) = result
        role = formatRole(user, organism)
        role["permissions_nbr"] = permissions_number
        roles.append(role)
    
    # Send response
    output = prepare_output(roles)
    return output, 200
    

def formatRole(user, organism):
    return {
        "id": user.id_role,
        "user_name": formatRoleName(user),
        "organism_name": (organism.nom_organisme if organism else None),
        "type": "GROUP" if user.groupe == True else "USER",
    }


def formatRoleName(role):
    name_parts = []
    if role.prenom_role:
        name_parts.append(role.prenom_role)
    if role.nom_role:
        name_parts.append(role.nom_role)
    return " ".join(name_parts)


@routes.route("/roles/<int:id_role>", methods=["GET"])
@json_resp
def get_permissions_by_role_id(id_role):
    """
    Retourne un rôle avec ses permissions.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos du rôle et ses permissions.
    """
    # Get role infos
    query = (
        DB.session.query(User, BibOrganismes)
            #.select_from(CorRoleActionFilterModuleObject)
            #.join(User, User.id_role == CorRoleActionFilterModuleObject.id_role)
            .outerjoin(BibOrganismes, BibOrganismes.id_organisme == User.id_organisme)
            .filter(User.id_role == id_role)
    )
    result = query.first()

    # Prepare role infos
    if not result:
        response = {
            "message": f"Id de rôle introuvable : {id_role} .",
            "status": "error"
        }
        return response, 404
    
    (user, organism) = result
    role = formatRole(user, organism)

    # Get, prepare and add groups of an user (for permissions inheritance)
    role["groups"] = []
    for role_group in get_user_groups(id_role):
        role["groups"].append({
            "id": role_group.id_role, 
            "groupName": formatRoleName(role_group), 
        })

    # Get permissions
    query = (
        DB.session.query(
            CorRoleActionFilterModuleObject.id_role,
            CorModuleActionObjectFilter.label,
            CorModuleActionObjectFilter.code,
            TModules.module_code,
            TActions.code_action,
            TObjects.code_object,
            cast(CorRoleActionFilterModuleObject.end_date, Date),
            CorRoleActionFilterModuleObject.gathering,
            BibFiltersType.code_filter_type,
            CorRoleActionFilterModuleObject.value_filter
        )
        .join(User, User.id_role == CorRoleActionFilterModuleObject.id_role)
        .join(CorModuleActionObjectFilter, and_(
            CorModuleActionObjectFilter.id_module == CorRoleActionFilterModuleObject.id_module,
            CorModuleActionObjectFilter.id_action == CorRoleActionFilterModuleObject.id_action,
            CorModuleActionObjectFilter.id_object == CorRoleActionFilterModuleObject.id_object,
            CorModuleActionObjectFilter.id_filter_type == CorRoleActionFilterModuleObject.id_filter_type,
        ))
        .join(
            TActions, 
            TActions.id_action == CorModuleActionObjectFilter.id_action
        )
        .join(
            TObjects, 
            TObjects.id_object == CorModuleActionObjectFilter.id_object
        )
        .join(TModules, TModules.id_module == CorRoleActionFilterModuleObject.id_module)
        .join(BibFiltersType, BibFiltersType.id_filter_type == CorRoleActionFilterModuleObject.id_filter_type)
        .filter(User.id_role == id_role)
    )
    results = query.all()

    # Prepare permissions
    permissions = {}
    for result in results:
        (
            id_role, label, code, module, action_code, object_code, 
            end_date, gathering, filter_type, filter_value
        ) = result
        
        # Initialize new module entry
        if module not in permissions.keys():
            permissions[module] = {}

        # Build filter labels if necessary
        labels = None
        if filter_type == 'GEOGRAPHIC':
            filter_value = split_value_filter(filter_value)
            labels = format_geographic_filter_values(filter_value)
        if filter_type == 'TAXONOMIC':
            filter_value = split_value_filter(filter_value)
            labels = format_taxonomic_filter_values(filter_value)

        # Create new permission or only add an additionnal filter
        gathering = str(gathering)
        if gathering not in permissions[module].keys():
            permissions[module][gathering] = {
                "name": label,
                "code": code,
                "gathering": gathering,
                "module": module,
                "action": action_code,
                "object": object_code,
                "end_date": end_date,
                "filters": [{
                    "type": filter_type,
                    "value": filter_value,
                    "label": labels,
                }],
            }
        else:
            new_filter = {
                "type": filter_type,
                "value": filter_value,
                "label": labels,
            }
            permissions[module][gathering]["filters"].append(new_filter)

    # Add permissions list to role (remove "gathering from output")
    for module_name in permissions:
        permissions[module_name] = list(permissions[module_name].values())
    role["permissions"] = permissions

    # Send response
    output = prepare_output(role)
    return output, 200


def get_user_groups(id_role):
    """
    Fournit tous les groupes d'un utilisateur.
    Parameters:
        id_role (int): identifiant de l'utilisateur.
    Return:
        Array<User>
    """
    return (
        DB.session.query(User)
            .join(CorRole, User.id_role == CorRole.id_role_groupe)
            .filter(CorRole.id_role_utilisateur == id_role)
            .all()
    )

@routes.route("/<gathering>", methods=["DELETE"])
@json_resp
def delete_permission(gathering):
    """
    Supprime une permissions par son hash de groupement.

    Notes : il est plus simple de supprimer une permission et tous les 
    filtres qui lui son associé à l'aide du hash de regroupement plutôt 
    que par une liste d'identifiant.

    .. :quickref: Permissions;

    :returns: code http 204 et un corps de réponse vide si tout est OK.
    """
    # Delete permission
    try:
        delete_permission_by_gathering(gathering)
        DB.session.commit()
        DB.session.flush()
    except exc.NoResultFound:
        log.info(f"No permissions found for gathering {gathering}")
        response = {
            "message": f"Aucune permission trouvé pour le groupement : {gathering} .",
            "status": "error"
        }
        return response, 404
    except Exception as exp:
        log.error("Error %s", exp)
        response = {
            "message": f"Une exception est survenue durant la suppression : {exp} .",
            "status": "error"
        }
        return response, 500
    
    return "", 204


def delete_permission_by_gathering(gathering):
    result = (
        DB.session
        .query(CorRoleActionFilterModuleObject)
        .filter(CorRoleActionFilterModuleObject.gathering == gathering)
        .delete()
    )
    return result

@routes.route("/availables/actions-objects", methods=["GET"])
@json_resp
def get_availables_actions_objects():
    """
    Retourne tous les ensembles action-object disponibles.

    .. :quickref: Permissions;

    Params:
    :param module: filtre permetant de récupérer seulement les ensembles
    action-object disponibles pour un module donné.

    :returns: un tableau des ensembles action-object possibles.
    """
    # Extract params
    params = request.args.to_dict()

    # Build query
    query = (DB.session
        .query(
            CorModuleActionObjectFilter.label,
            TActions.code_action,
            TObjects.code_object,
            TModules.module_code,
        )
        .distinct()
        .join(
            TModules, 
            TModules.id_module == CorModuleActionObjectFilter.id_module
        )
        .join(
            TActions, 
            TActions.id_action == CorModuleActionObjectFilter.id_action
        )
        .join(
            TObjects, 
            TObjects.id_object == CorModuleActionObjectFilter.id_object
        )
        .order_by(
            CorModuleActionObjectFilter.id_action,
            CorModuleActionObjectFilter.id_object,
        )
    )
    
    # Manage parameters
    if "module" in params:
        query = query.filter(TModules.module_code == params["module"])

    # Build output
    availables = []
    for result in query.all():
        (label, action_code, object_code, module_code) = result
        
        availables.append({
            "module_code": module_code,
            "action_code": action_code,
            "object_code": object_code,
            "label": label,
        })
    
    output = prepare_output(availables)
    return output, 200


@routes.route("/availables/actions-objects-filters", methods=["GET"])
@json_resp
def get_availables_actions_objects_filters():
    """
    Retourne tous les ensembles action-object-filter disponibles.

    .. :quickref: Permissions;

    Params:
    :param module: filtre permetant de récupérer seulement les permissions
        disponibles pour un module donné.
    :param action: filtre permetant de récupérer seulement les permissions
        disponibles pour une action (CRUVED) donnée.
    :param object: filtre permetant de récupérer seulement les permissions
        disponibles pour un objet donné.

    :returns: un dictionnaire contenant en clé le code des modules et en
    valeur un tableau des ensembles action-object-filter possibles.
    Si le paramètres "module" est utilisé, retourne seulement le tableau
    des ensembles action-object-filter possibles
    """
    # Extract params
    params = request.args.to_dict()

    # Build query
    query = (DB.session
        .query(
            TActions.code_action,
            TObjects.code_object,
            BibFiltersType.code_filter_type,
            CorModuleActionObjectFilter.code,
            CorModuleActionObjectFilter.description,
            TModules.module_code,
        )
        .distinct()
        .join(
            TModules, 
            TModules.id_module == CorModuleActionObjectFilter.id_module
        )
        .join(
            TActions, 
            TActions.id_action == CorModuleActionObjectFilter.id_action
        )
        .join(
            TObjects, 
            TObjects.id_object == CorModuleActionObjectFilter.id_object
        )
        .join(
            BibFiltersType, 
            BibFiltersType.id_filter_type == CorModuleActionObjectFilter.id_filter_type
        )
        .order_by(
            CorModuleActionObjectFilter.id_action,
            CorModuleActionObjectFilter.id_object,
            CorModuleActionObjectFilter.id_filter_type,
        )
    )
    
    # Manage parameters
    if "module" in params:
        query = query.filter(TModules.module_code == params["module"])
    if "action" in params:
        query = query.filter(TActions.code_action == params["action"])
    if "object" in params:
        query = query.filter(TObjects.code_object == params["object"])

    # Build output
    availables = []
    for result in query.all():
        (action_code, object_code, filter_type_code, code, description, module_code) = result
        
        availables.append({
            "module_code": module_code,
            "action_code": action_code,
            "object_code": object_code,
            "filter_type_code": filter_type_code,
            "code": code,
            "description": description,
        })
    
    output = prepare_output(availables)
    return output, 200


@routes.route("", methods=["POST"])
@permissions.check_cruved_scope(action='C', get_role=True)
@json_resp
def post_permission(info_role):
    """
    Ajouter une permission.

    .. :quickref: Permissions;
    """
    # Transform received data
    gathering = uuid.uuid4()
    data = prepare_input(dict(request.get_json()))
    exp = None
    
    try:
        # Create permssion
        create_permission(gathering, data)
        
        # Write in database
        DB.session.commit()
        DB.session.flush()
    except exc.SQLAlchemyError as exp:
        log.error("Error SQLAlchemy %s", exp)
    except Exception as exp:
        log.error("Error %s", exp)
    
    # Return response
    if exp:
        response = {
            "message": f"Une erreur est survenue durant l'ajout de la permission : {exp} .",
            "status": "error"
        }
        code = 500
    else:
        response = {
            "message": "Succès de l'ajout de la permission.",
            "status": "success"
        }
        code = 200
    
    return response, code


@routes.route("<gathering>", methods=["PUT"])
@permissions.check_cruved_scope(action='U', get_role=True)
@json_resp
def update_permission(info_role, gathering):
    """
    Modifier une permission.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos de la permission modifiée.
    """
    # Transform received data
    role = get_user_infos(info_role.id_role)
    data = prepare_input(dict(request.get_json()))
    exp = None

    try:
        # Delete permission before create new one
        delete_permission_by_gathering(gathering)
        create_permission(gathering, data)

        # Write in database
        DB.session.commit()
        DB.session.flush()
    except exc.SQLAlchemyError as exp:
        log.error("Error SQLAlchemy %s", exp)
    except Exception as exp:
        log.error("Error %s", exp)
    
    # Return response
    if exp:
        response = {
            "message": f"Une erreur est survenue durant la mise à jour de la permission : {exp} .",
            "status": "error"
        }
        code = 500
    else:
        response = {
            "message": "Succès de la modification de la permission.",
            "status": "success"
        }
        code = 200
    
    return response, code


def create_permission(gathering, data):
    role_id = data["id_role"]
    module_id = get_module_id(data["module"])
    action_id = get_action_id(data["action"])
    object_id = get_object_id(data["object"])
    end_access_date = format_end_access_date(data["end_date"])
    
    # TODO: check if this permission with all this specific filters already exist

    # (Re)create permissions
    for key, val in data["filters"].items():
        if val != None:
            # Get filter type and value
            filter_type_id = get_filter_id(key)
            if key in ("geographic", "taxonomic"):
                value_filter = build_value_filter_from_list(unduplicate_values(val))
            else: 
                value_filter = val

            # (Re)create permission with same gathering
            permission = CorRoleActionFilterModuleObject(**{
                "id_role": role_id,
                "id_module": module_id,
                "id_action": action_id,
                "id_object": object_id,
                "id_filter": 0,# TODO: delete this line !
                "gathering": gathering,
                "end_date": end_access_date,
                "id_filter_type": filter_type_id,
                "value_filter": value_filter,
            })
            if not permission.is_already_exist():
                # TODO: remove permission_filter managment !
                permission_filter = get_filter(
                    id_filter_type=permission.id_filter_type,
                    value_filter=permission.value_filter,
                )
                if not permission_filter:
                    filter_type_label = get_filter_type_label(permission.id_filter_type)
                    permission_filter = TFilters(
                        label_filter=f"{filter_type_label} : {permission.value_filter}",
                        id_filter_type=permission.id_filter_type,
                        value_filter=permission.value_filter,
                    )
                permission.filter.append(permission_filter)
                
                DB.session.add(permission)


def get_module_id(module_code):
    return (DB
        .session.query(TModules.id_module)
        .filter(TModules.module_code == module_code)
        .scalar()
    )

def get_action_id(action_code):
    return (DB
        .session.query(TActions.id_action)
        .filter(TActions.code_action == action_code)
        .scalar()
    )

def get_object_id(object_code):
    return (DB
        .session.query(TObjects.id_object)
        .filter(TObjects.code_object == object_code)
        .scalar()
    )

def get_filter_id(filter_code):
    return (DB
        .session.query(BibFiltersType.id_filter_type)
        .filter(BibFiltersType.code_filter_type == filter_code.upper())
        .scalar()
    )


# -----------------------------------------------------------------------
# UTILS functions
# TODO: move this functions in other file (?)
def prepare_output(d, remove_in_key=None):
    if isinstance(d, list):
        output = []
        for item in d:
            output.append(prepare_output(item, remove_in_key))
        return output
    elif isinstance(d, dict) :
        new = {}
        for k, v in d.items():
            # Remove None and empty values
            if v != None and v != "":
                # Remove substring in key
                if remove_in_key:
                    k = k.replace(remove_in_key, '').strip('_')
                # Value processing recursively
                new[format_to_camel_case(k)] = prepare_output(v, remove_in_key)
        return new
    else:
        return d


def format_to_camel_case(snake_str):
    components = snake_str.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


def prepare_input(d):
    if isinstance(d, list):
        output = []
        for item in d:
            output.append(prepare_input(item))
        return output
    elif isinstance(d, dict) :
        return dict((format_to_snake_case(k), v) for k, v in d.items())
    else:
        return d


def format_to_snake_case(camel_str): 
    return ''.join(['_'+char.lower() if char.isupper()  
        else char for char in camel_str]).lstrip('_') 
