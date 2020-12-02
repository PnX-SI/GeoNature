"""
Routes of the gn_permissions blueprint
"""

from copy import copy
import datetime
import json
import locale
import logging
import random

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
from sqlalchemy import or_
from sqlalchemy.orm import (aliased, noload)
from sqlalchemy.orm.exc import NoResultFound
from utils_flask_sqla.response import json_resp
from pypnusershub.db.models import User

from geonature.core.gn_commons.models import TModules
from geonature.core.ref_geo.models import LAreas, BibAreasTypes
from geonature.core.taxonomie.models import Taxref
from geonature.core.users.models import BibOrganismes
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.models import (
    BibFiltersType,
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
    :param module_code: the code of the requested module - as querystring
    :type module_code: str

    :returns: dict of the CRUVED
    """
    params = request.args.to_dict()

    # get modules
    q = DB.session.query(TModules)
    if "module_code" in params:
        q = q.filter(TModules.module_code.in_(params["module_code"]))
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
    copy_session_key = copy(session)
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
        # TODO : see how to define locale globaly => bug with python 3.7?
        print(f"Current locale: {locale.getlocale(locale.LC_TIME)}")
        locale.setlocale(locale.LC_TIME, "fr_FR.UTF-8")
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
        status = "acceptée" if request["processed_state"] == RequestStates.accepted else "refusée"
        msg = f"Demande de permission déjà {status} le {date}.",
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
        add_permissions(request)

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
    except NoResultFound:
        return False
    print(f"In get_request_by_token(): {data}")
    return data


def add_permissions(request):
    new_permissions = []
    if (request["geographic_filter"]):
        permissions = get_geographic_permissions()
        for perm in permissions:
            perm.id_role = request["id_role"]
            perm.gathering = request["token"]
            perm.end_date = request["end_date"]
            perm.value_filter = build_value_filter_from_list(request["geographic_filter"])
            new_permissions.append(perm)

    if (request["taxonomic_filter"]):
        permissions = get_geographic_permissions()
        for perm in permissions:
            perm.id_role = request["id_role"]
            perm.gathering = request["token"]
            perm.end_date = request["end_date"]
            perm.value_filter = build_value_filter_from_list(request["taxonomic_filter"])
            new_permissions.append(perm)

    if (request["sensitive_access"] is True):
        permissions = get_sensitivity_permissions()
        for perm in permissions:
            perm.id_role = request["id_role"]
            perm.gathering = request["token"]
            perm.end_date = request["end_date"]
            perm.value_filter = "exact"
            new_permissions.append(perm)

    for permission in new_permissions:
        if not permission.is_permission_already_exist():
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


def build_value_filter_from_list(data: list):
    unduplicated_data = unduplicate_values(data)
    return ",".join(map(str, unduplicated_data))

def split_value_filter(data: str):
    values = data.split(',')
    unduplicated_data = unduplicate_values(values)
    return unduplicated_data


def get_geographic_permissions():
    permissions = []
    for new_perm in get_default_permission_to_set():
        new_perm["filter_type_code"] = "GEOGRAPHIC"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_taxonomic_permissions():
    permissions = []
    for new_perm in get_default_permission_to_set():
        new_perm["filter_type_code"] = "TAXONOMIC"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_sensitivity_permissions():
    permissions = []
    for new_perm in get_default_permission_to_set():
        new_perm["filter_type_code"] = "PRECISION"
        new_perm["object_code"] = "SENSITIVE_OBSERVATION"
        fresh_perm = get_fresh_permission(**new_perm)
        permissions.append(fresh_perm)
    return permissions


def get_default_permission_to_set():
    return [
        {"module_code": "SYNTHESE", "action_code": "R", "object_code": "PRIVATE_OBSERVATION", },
        {"module_code": "SYNTHESE", "action_code": "E", "object_code": "PRIVATE_OBSERVATION", },
        {"module_code": "VALIDATION", "action_code": "R", "object_code": "PRIVATE_OBSERVATION", },
    ]


def get_fresh_permission(filter_type_code, module_code, action_code, object_code):
    permission_module = DB.session.query(TModules).filter(TModules.module_code == module_code).one()
    permission_action = DB.session.query(TActions).filter(TActions.code_action == action_code).one()
    permission_object = DB.session.query(TObjects).filter(TObjects.code_object == object_code).one()
    permission_filter_type = (DB.session
        .query(BibFiltersType)
        .filter(BibFiltersType.code_filter_type == filter_type_code)
        .one()
    )
    return CorRoleActionFilterModuleObject(
        id_module=permission_module.id_module,
        id_action=permission_action.id_action,
        id_object=permission_object.id_object,
        id_filter=0,# TODO: remove this line !
        id_filter_type=permission_filter_type.id_filter_type,
    )


def get_filter(id_filter_type, value_filter):
    try:
        permission_filter = (DB
            .session.query(TFilters)
            .filter(TFilters.id_filter_type == id_filter_type)
            .filter(TFilters.value_filter == value_filter)
            .one()
        )
    except NoResultFound:
        return False
    return permission_filter


def get_filter_type_label(id_filter_type):
    try:
        label = (DB
            .session.query(BibFiltersType.label_filter_type)
            .filter(BibFiltersType.id_filter_type == id_filter_type)
            .one()[0]
        )
    except NoResultFound:
        return False
    return label


def remove_permissions(request):
    try:
        (DB.session
            .query(CorRoleActionFilterModuleObject)
            .filter(CorRoleActionFilterModuleObject.gathering == request.token)
            .delete()
        )
    except NoResultFound:
        log.info("No permissions found. No permissions to remove.")
    except IntegrityError as exp:
        log.error("Permissions deletion error %s", exp)
    except Exception as exp:
        log.error("Error %s", exp)


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
        sensitive_permission=request["sensitive_access"],
        geographic_filter_values=format_geographic_filter_values(areas),
        taxonomic_filter_values=format_taxonomic_filter_values(taxa),
        end_date=end_date,
        app_url=current_app.config["URL_APPLICATION"],
        validators=get_validators(),
    )


def render_pending_request_tpl(user, request):
    return render_template(
        "email_user_request_pending.html",
        app_name=current_app.config["appName"],
        user=user,
        validators=get_validators(),
    )


def render_refused_request_tpl(user, request):
    return render_template(
        "email_user_request_refused.html",
        app_name=current_app.config["appName"],
        user=user,
        refusal_reason=request["refusal_reason"],
        validators=get_validators(),
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

    :returns: un tableau de dictionnaire contenant les infos des modules.
    """
    q = DB.session.query(TModules)
    modules = []
    for module in q.all():
        module = format_keys_to_camel_case(module.as_dict())
        modules.append(module)
    return jsonify(modules), 200

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
    for action in q.all():
        action = format_keys_to_camel_case(action.as_dict())
        actions.append(action)
    return jsonify(actions), 200

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
    for pfilter in q.all():
        pfilter = format_keys_to_camel_case(pfilter.as_dict())
        filters.append(pfilter)
    return jsonify(filters), 200

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
        obj = format_keys_to_camel_case(obj.as_dict())
        objects.append(obj)
    return jsonify(objects), 200


def format_keys_to_camel_case(d):
    if isinstance(d, list):
        output = []
        for item in d:
            output.append(format_keys_to_camel_case(item))
        return output
    elif isinstance(d, dict) :
        return dict((format_to_camel_case(k), v) for k, v in d.items())
    else:
        raise TypeError('formating to camel case accept only dict or list of dict')


def format_to_camel_case(snake_str):
    components = snake_str.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])

def format_keys_to_snake_case(d):
    if isinstance(d, list):
        output = []
        for item in d:
            output.append(format_keys_to_snake_case(item))
        return output
    elif isinstance(d, dict) :
        return dict((format_to_snake_case(k), v) for k, v in d.items())
    else:
        raise TypeError('formating to snake case accept only dict or list of dict')

def format_to_snake_case(camel_str): 
    return ''.join(['_'+char.lower() if char.isupper()  
        else char for char in camel_str]).lstrip('_') 


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
            .join(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme)
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
        
    requests = format_keys_to_camel_case(requests)
    return jsonify(requests), 200


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
            .join(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme)
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
    response = format_keys_to_camel_case(response)
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
    data = format_keys_to_snake_case(dict(request.get_json()))
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
        add_permissions(trequest.as_dict())
    else:
        remove_permissions(trequest)

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
            .join(BibOrganismes, BibOrganismes.id_organisme == UserAsker.id_organisme)
            .join(UserValidator, UserValidator.id_role == TRequests.processed_by, isouter=True)
            .filter(TRequests.token == token)
            .first()
    )

    # Prepare response
    access_request = formatAccessRequest(*results)
    response = format_keys_to_camel_case(access_request)
    return response, 200


def formatAccessRequest(request, asker, asker_organism, validator):
    taxa = split_value_filter(request.taxonomic_filter)
    areas = split_value_filter(request.geographic_filter)
    sensitive = request.sensitive_access
    access_request = {
        "token": request.token,
        "user_name": f"{asker.prenom_role} {asker.nom_role}",
        "organism_name": asker_organism.nom_organisme,
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


def get_roles_permissions():
    return [
        { 'id': 1, 'name': 'Jean-Pascal MILCENT', 'type': 'USER', 'permissionsNbr': 5, 'permissions': [
            {'module': 'SYNTHESE', 'action': 'R', 'object': 'PRIVATE_OBSERVATION', 'filter_type': 'PRECISION', 'filter_value': 'precise'},
            {'module': 'SYNTHESE', 'action': 'R', 'object': 'PRIVATE_OBSERVATION', 'filter_type': 'GEOGRAPHIC', 'filter_value': '3896,18628'},
            {'module': 'SYNTHESE', 'action': 'E', 'object': 'PRIVATE_OBSERVATION', 'filter_type': 'PRECISION', 'filter_value': 'precise'},
            {'module': 'SYNTHESE', 'action': 'E', 'object': 'PRIVATE_OBSERVATION', 'filter_type': 'GEOGRAPHIC', 'filter_value': '3896,18628'},
        ]},
        { 'id': 2, 'name': 'Martin DUPOND', 'type': 'USER', 'permissionsNbr': 3 },
        { 'id': 3, 'name': 'Observateurs', 'type': 'GROUP', 'permissionsNbr': 6 },
        { 'id': 4, 'name': 'Zazi SWAROSKI', 'type': 'USER', 'permissionsNbr': 15 },
        { 'id': 5, 'name': 'Utilisateurs de GeoNature', 'type': 'GROUP', 'permissionsNbr': 8 },
        { 'id': 6, 'name': 'Administrateurs de GeoNature', 'type': 'GROUP', 'permissionsNbr': 25 },
        { 'id': 7, 'name': 'Raphaël LEPEINTRE', 'type': 'USER', 'permissionsNbr': 5 },
        { 'id': 8, 'name': 'Robert BAYLE', 'type': 'USER', 'permissionsNbr': 3 },
        { 'id': 9, 'name': 'Jean-Baptiste GIBELIN', 'type': 'USER', 'permissionsNbr': 6 },
        { 'id': 10, 'name': 'Louise NADAL', 'type': 'USER', 'permissionsNbr': 15 },
        { 'id': 11, 'name': 'Anne POLZE', 'type': 'USER', 'permissionsNbr': 8 },
        { 'id': 12, 'name': 'Scipion BAYLE', 'type': 'USER', 'permissionsNbr': 25 },
        { 'id': 13, 'name': 'Hélène TOURRE', 'type': 'USER', 'permissionsNbr': 5 },
        { 'id': 14, 'name': 'Étienne POMMEL', 'type': 'USER', 'permissionsNbr': 3 },
        { 'id': 15, 'name': 'Jeanne DOMERGUE', 'type': 'USER', 'permissionsNbr': 6 },
        { 'id': 16, 'name': 'Jacques DALVERNY', 'type': 'USER', 'permissionsNbr': 15 },
        { 'id': 17, 'name': 'Marie FABRE', 'type': 'USER', 'permissionsNbr': 8 },
        { 'id': 18, 'name': 'Pierre FONTANIEU', 'type': 'USER', 'permissionsNbr': 25 },
    ]


@routes.route("/roles", methods=["GET"])
def get_permissions_for_all_roles():
    """
    Retourne tous les rôles avec leur nombre de permissions.

    .. :quickref: Permissions;

    :returns: un tableau de dictionnaire contenant les infos du rôle et son nombre de permissions.
    """
    roles_permissions = get_roles_permissions()
    return jsonify(roles_permissions), 200


@routes.route("/roles/<int:id_role>", methods=["GET"])
def get_permissions_by_role_id(id_role):
    """
    Retourne un rôle avec son nombre de permissions.

    .. :quickref: Permissions;

    :returns: un dictionnaire avec les infos du rôle et son nombre de permissions.
    """
    roles_permissions = get_roles_permissions()

    response = False
    for role in roles_permissions:
        if role['id'] == id_role:
            response = role
            break

    if not response:
        response = {
            "message": f"Id de rôle introuvable : {id_role} .",
            "status": "error"
        }
        return response, 404
    else:
        return response, 200
