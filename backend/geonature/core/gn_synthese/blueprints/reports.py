import datetime

import sqlalchemy as sa
from flask import Blueprint, abort, current_app, g, jsonify, request
from geonature.core.gn_permissions.decorators import (
    login_required,
    permissions_required,
)
from geonature.core.gn_permissions.tools import get_permissions
from geonature.core.gn_synthese.models import BibReportsTypes, Synthese, TReport
from geonature.core.gn_synthese.schemas import ReportSchema
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.notifications.utils import dispatch_notifications
from geonature.utils.env import db
from pypnusershub.db.models import User
from sqlalchemy import asc, desc, or_, select
from sqlalchemy.orm import Load, joinedload
from utils_flask_sqla.response import json_resp
from werkzeug.exceptions import BadRequest, Conflict, Forbidden

reports_blueprint = Blueprint("reports", __name__)


@reports_blueprint.route("", methods=["POST"])
@permissions_required("R", module_code="SYNTHESE")
@json_resp
def create_report(permissions):
    """
    Create a report (e.g report) for a given synthese id

    Returns
    -------
        report: `json`:
            Every occurrence's report
    """
    session = db.session
    data = request.get_json()
    if data is None:
        raise BadRequest("Empty request data")
    try:
        type_name = data["type"]
        id_synthese = data["item"]
        content = data["content"]
    except KeyError:
        raise BadRequest("Empty request data")
    if not id_synthese:
        raise BadRequest("id_synthese is missing from the request")
    if not type_name:
        raise BadRequest("Report type is missing from the request")
    if not content and type_name == "discussion":
        raise BadRequest("Discussion content is required")

    type_exists = db.session.execute(
        sa.select(BibReportsTypes).filter_by(type=type_name)
    ).scalar_one_or_none()

    if not type_exists:
        raise BadRequest("This report type does not exist")

    synthese = db.session.scalars(
        select(Synthese)
        .options(
            Load(Synthese).raiseload("*"),
            joinedload("nomenclature_sensitivity"),
            joinedload("cor_observers"),
            joinedload("digitiser"),
            joinedload("dataset"),
        )
        .filter_by(id_synthese=id_synthese)
        .limit(1),
    ).first()

    if not synthese:
        abort(404)

    if not synthese.has_instance_permission(permissions):
        raise Forbidden

    report_query = sa.select(TReport).where(
        TReport.id_synthese == id_synthese,
        TReport.report_type.has(BibReportsTypes.type == type_name),
    )

    user_pin = sa.select(TReport).where(
        TReport.id_synthese == id_synthese,
        TReport.report_type.has(BibReportsTypes.type == "pin"),
        TReport.id_role == g.current_user.id_role,
    )
    # only allow one alert by id_synthese
    if type_name in ["alert"]:
        alert_exists = db.session.execute(report_query).scalar_one_or_none()
        if alert_exists is not None:
            raise Conflict("This type already exists for this id")
    if type_name in ["pin"]:
        pin_exist = db.session.execute(user_pin).scalar_one_or_none()
        if pin_exist is not None:
            raise Conflict("This type already exists for this id")
    new_entry = TReport(
        id_synthese=id_synthese,
        id_role=g.current_user.id_role,
        content=content,
        creation_date=datetime.datetime.now(),
        id_type=type_exists.id_type,
    )
    session.add(new_entry)

    if type_name == "discussion":
        # Get the observers of the observation
        observers = {observer.id_role for observer in synthese.cor_observers}
        # Get the users that commented the observation
        commenters = {
            report.id_role
            for report in db.session.scalars(
                report_query.where(
                    TReport.id_role.notin_({synthese.id_digitiser} | observers)
                ).distinct(TReport.id_role)
            ).all()
        }
        # The id_roles are the Union between observers and commenters
        id_roles = observers | commenters | {synthese.id_digitiser}
        # Remove the user that just commented the obs not to notify him/her
        id_roles.discard(g.current_user.id_role)
        notify_new_report_change(
            synthese=synthese, user=g.current_user, id_roles=id_roles, content=content
        )
    session.commit()


def notify_new_report_change(synthese, user, id_roles, content):
    if not synthese.id_digitiser:
        return
    dispatch_notifications(
        code_categories=["OBSERVATION-COMMENT"],
        id_roles=id_roles,
        title="Nouveau commentaire sur une observation",
        url=(
            current_app.config["URL_APPLICATION"]
            + "/#/synthese/occurrence/"
            + str(synthese.id_synthese)
        ),
        context={"synthese": synthese, "user": user, "content": content},
    )


@reports_blueprint.route("/<int:id_report>", methods=["PUT"])
@login_required
@json_resp
def update_content_report(id_report):
    """
    Modify a report (e.g report) for a given synthese id

    Returns
    -------
        report: `json`:
            Every occurrence's report
    """
    data = request.json
    idReport = data["idReport"]
    report = db.get_or_404(TReport, idReport)
    if report.user != g.current.user:
        raise Forbidden
    report.content = data["content"]
    db.session.commit()


@reports_blueprint.route("", methods=["GET"])
@permissions_required("R", module_code="SYNTHESE")
def list_all_reports(permissions):
    # Parameters
    type_name = request.args.get("type")
    orderby = request.args.get("orderby", "creation_date")
    sort = request.args.get("sort")
    page = request.args.get("page", 1, int)
    per_page = request.args.get("per_page", 10, int)
    my_reports = request.args.get("my_reports", "false").lower() == "true"

    # Start query
    query = (
        sa.select(TReport, User.nom_complet)
        .join(User, TReport.id_role == User.id_role)
        .options(
            joinedload(TReport.report_type).load_only(
                BibReportsTypes.type, BibReportsTypes.id_type
            ),
            joinedload(TReport.synthese).load_only(
                Synthese.cd_nom,
                Synthese.nom_cite,
                Synthese.observers,
                Synthese.date_min,
                Synthese.date_max,
            ),
            joinedload(TReport.user).load_only(User.nom_role, User.prenom_role),
        )
    )
    # Verify and filter by type
    if type_name:
        type_exists = db.session.scalar(
            sa.exists(BibReportsTypes).where(BibReportsTypes.type == type_name).select()
        )
        if not type_exists:
            raise BadRequest("This report type does not exist")
        query = query.where(TReport.report_type.has(BibReportsTypes.type == type_name))

    # Filter by id_role for 'pin' type only or if my_reports is true
    if type_name == "pin" or my_reports:
        query = query.where(
            or_(
                TReport.id_role == g.current_user.id_role,
                TReport.id_synthese.in_(
                    select(TReport.id_synthese).where(TReport.id_role == g.current_user.id_role)
                ),
                TReport.synthese.has(Synthese.id_digitiser == g.current_user.id_role),
                TReport.synthese.has(
                    Synthese.cor_observers.any(User.id_role == g.current_user.id_role)
                ),
            )
        )

    # On vérifie les permissions en lecture sur la synthese
    synthese_query = select(Synthese.id_synthese).select_from(Synthese)
    synthese_query_obj = SyntheseQuery(Synthese, synthese_query, {})
    synthese_query_obj.filter_query_with_permissions(g.current_user, permissions)
    cte_synthese = synthese_query_obj.query.cte("cte_synthese")
    query = query.where(TReport.id_synthese == cte_synthese.c.id_synthese)

    SORT_COLUMNS = {
        "user.nom_complet": User.nom_complet,
        "content": TReport.content,
        "creation_date": TReport.creation_date,
    }

    # Determine the sorting
    if orderby in SORT_COLUMNS:
        sort_column = SORT_COLUMNS[orderby]
        if sort == "desc":
            query = query.order_by(desc(sort_column))
        else:
            query = query.order_by(asc(sort_column))
    else:
        raise BadRequest("Bad orderby")

    # Pagination
    paginated_results = db.paginate(query, page=page, per_page=per_page)

    result = []

    for report in paginated_results.items:
        report_dict = {
            "id_report": report.id_report,
            "id_synthese": report.id_synthese,
            "id_role": report.id_role,
            "report_type": {
                "type": report.report_type.type,
                "id_type": report.report_type.id_type,
            },
            "content": report.content,
            "deleted": report.deleted,
            "creation_date": report.creation_date,
            "user": {"nom_complet": report.user.nom_complet},
            "synthese": {
                "cd_nom": report.synthese.cd_nom,
                "nom_cite": report.synthese.nom_cite,
                "observers": report.synthese.observers,
                "date_min": report.synthese.date_min,
                "date_max": report.synthese.date_max,
            },
        }
        result.append(report_dict)

    response = {
        "total": paginated_results.total,
        "page": paginated_results.page,
        "per_page": paginated_results.per_page,
        "items": result,
    }
    return jsonify(response)


@reports_blueprint.route("/<int:id_synthese>", methods=["GET"])
@permissions_required("R", module_code="SYNTHESE")
def list_reports(permissions, id_synthese):
    type_name = request.args.get("type")

    synthese = db.get_or_404(Synthese, id_synthese)
    if not synthese.has_instance_permission(permissions):
        raise Forbidden

    query = sa.select(TReport).where(TReport.id_synthese == id_synthese)

    # Verify and filter by type
    if type_name:
        type_exists = db.session.scalar(
            sa.exists(BibReportsTypes).where(BibReportsTypes.type == type_name).select()
        )
        if not type_exists:
            raise BadRequest("This report type does not exist")
        query = query.where(TReport.report_type.has(BibReportsTypes.type == type_name))

    # Filter by id_role for 'pin' type only
    if type_name == "pin":
        query = query.where(TReport.id_role == g.current_user.id_role)

    # Join the User table
    query = query.options(
        joinedload(TReport.user).load_only(User.nom_role, User.prenom_role),
        joinedload(TReport.report_type),
    )

    return ReportSchema(many=True, only=["+user.nom_role", "+user.prenom_role"]).dump(
        db.session.scalars(query).all()
    )


@reports_blueprint.route("/<int:id_report>", methods=["DELETE"])
@login_required
@json_resp
def delete_report(id_report):
    reportItem = TReport.query.get_or_404(id_report)
    # alert control to check cruved - allow validators only
    if reportItem.report_type.type in ["alert"]:
        permissions = get_permissions(module_code="SYNTHESE", action_code="R")
        if not reportItem.synthese.has_instance_permission(permissions):
            raise Forbidden("Permission required to delete this report !")
    # only owner could delete a report for pin and discussion
    if reportItem.id_role != g.current_user.id_role and reportItem.report_type.type in [
        "discussion",
        "pin",
    ]:
        raise Forbidden
    # discussion control to don't delete but tag report as deleted only
    if reportItem.report_type.type == "discussion":
        reportItem.content = ""
        reportItem.deleted = True
    else:
        db.session.delete(reportItem)
    db.session.commit()
