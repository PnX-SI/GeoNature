import json
import datetime
import time

from collections import OrderedDict
from warnings import warn

from flask import (
    Blueprint,
    request,
    Response,
    current_app,
    send_from_directory,
    render_template,
    jsonify,
    g,
)
from werkzeug.exceptions import Forbidden, NotFound, BadRequest, Conflict
from sqlalchemy import distinct, func, desc, asc, select, text, update
from sqlalchemy.orm import joinedload, contains_eager, lazyload, selectinload
from geojson import FeatureCollection, Feature
import sqlalchemy as sa

from utils_flask_sqla.generic import serializeQuery, GenericTable
from utils_flask_sqla.response import to_csv_resp, to_json_resp, json_resp
from utils_flask_sqla_geo.generic import GenericTableGeo


from geonature.utils import filemanager
from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometrytools import export_as_geo_file

from geonature.core.gn_meta.models import TDatasets

from geonature.core.gn_synthese.models import (
    BibReportsTypes,
    Synthese,
    TSources,
    DefaultsNomenclaturesValue,
    VSyntheseForWebApp,
    VColorAreaTaxon,
    TReport,
)
from geonature.core.gn_synthese.synthese_config import MANDATORY_COLUMNS
from geonature.core.taxonomie.models import (
    Taxref,
    TaxrefProtectionArticles,
    TaxrefProtectionEspeces,
    VMTaxrefListForautocomplete,
)
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery

from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import (
    cruved_scope_for_user_in_module,
    get_scopes_by_action,
)

from ref_geo.models import LAreas, BibAreasTypes

from pypnusershub.db.tools import user_from_token
from pypnusershub.db.models import User

routes = Blueprint("gn_notification", __name__)


@routes.route("/notifications", methods=["POST"])
@json_resp
def create_notification(scope):

    session = DB.session
    data = request.get_json()
    if data is None:
        raise BadRequest("Empty request data")
    try:
        # Information to check if notification is need
        id_role = data["id_role"]
        category = data["category"]
        method = data["method"]

        # Optional notification content
        title = data["title"]
        content = data["content"]
        url = data["url"]

        if not id_role:
            raise BadRequest("id_role is missing from the request")
        if not category or not method:
            raise BadRequest("Category or method is missing from the request")

        # Check if method exist in config
        method_exists = BibNotificationsMethods.query.filter_by(
            label_notification_method=method
        ).first()
        if not method_exists:
            raise BadRequest("This type of notification in not implement yet")

        # check if id_role exist

        # check in rules if user have notification for this category

        # if method is type BDD
        if method == "BDD":

            # create notification with unread status
            unread = "UNREAD"
            status = BibNotificationsStatus.query.filter_by(
                label_notification_status=unread
            ).first()

            # Save notification in database
            new_notification = TNotifications(
                id_role=g.current_user.id_role,
                title=title,
                content=content,
                url=url,
                creation_date=datetime.datetime.now(),
                code_status=status.code_notification_status,
            )
            session.add(new_notification)
            session.commit()

        # else if method is type MAIL
        # get category

        # get templates

        # replace information in templates

        # Send mail via celery

    except KeyError:
        raise BadRequest("Empty request data")


@routes.route("/notifications", methods=["GET"])
def list_database_notification(scope):

    notifications = TNotifications.query.filter(TNotifications.id_role == g.current_user.id_role)
    notifications = notifications.order_by(desc(TNotifications.creation_date))
    notifications = notification.options(joinedload("notification_status"))
    result = [
        notificationsResult.as_dict(
            fields=[
                "id_notification",
                "id_role",
                "title",
                "content",
                "url",
                "code_status",
                "creation_date",
                "notification_status.code_status",
                "notification_status.label_notification_status",
            ]
        )
        for notificationsResult in notifications.all()
    ]
    return jsonify(result)


@routes.route("/notificationsNumber", methods=["GET"])
def count_notification(scope):

    notificationNumber = TNotifications.query.filter(
        TNotifications.id_role == g.current_user.id_role
    ).count()
    return notificationNumber
