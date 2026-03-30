"""
Routes for gn_meta
"""

import datetime as dt
import json
import logging

from flask import Blueprint, current_app, request, Response, g, render_template, jsonify

from sqlalchemy.exc import DatabaseError
from sqlalchemy.sql import select
from sqlalchemy.sql.functions import func
from sqlalchemy.orm import Load, joinedload, undefer
from werkzeug.exceptions import Conflict, BadRequest, Forbidden, InternalServerError, NotFound
from werkzeug.datastructures import MultiDict, TypeConversionDict
from marshmallow import ValidationError, EXCLUDE
from sqlalchemy.exc import IntegrityError
from psycopg2.errors import UniqueViolation

from geonature.core.gn_meta.utils import (
    get_acquisition_framework_stats,
    MetadataPdfBuilder,
)
from geonature.utils.env import db
from geonature.core.gn_commons.routes import _get_additional_fields
from geonature.core.gn_synthese.models import (
    Synthese,
    CorAreaSynthese,
)
from geonature.core.gn_permissions.decorators import login_required
from geonature.utils.errors import GeoNatureError
from geonature.utils.json import pagination_schema

from pypnnomenclature.models import TNomenclatures

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
)
from geonature.core.gn_meta.schemas import (
    AcquisitionFrameworkSchema,
    DatasetSchema,
)
from utils_flask_sqla.response import json_resp, to_csv_resp, generate_csv_content
from utils_flask_sqla.db import ordered
from werkzeug.datastructures import Headers
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_scopes_by_action

from ref_geo.models import LAreas

routes = Blueprint("gn_meta", __name__, cli_group="metadata")

# get the root logger
log = logging.getLogger()


@routes.route("/datasets", methods=["GET", "POST"])
@login_required
def get_datasets():
    """
    Get datasets list

    .. :quickref: Metadata;

    :query boolean active: filter on active fiel
    :query string create: filter on C permission for the module_code specified
        (we can specify the object_code by adding a . between both)
    :query int id_acquisition_framework: get only dataset of given AF
    :returns:  `list<TDatasets>`
    """
    params = MultiDict(request.args)
    if request.is_json:
        params.update(request.json)
    fields = params.get("fields", type=str, default=[])

    if fields:
        fields = fields.split(",")

    if "create" in params:
        create = params.pop("create").split(".")
        if len(create) > 1:
            query = TDatasets.filter_by_creatable(module_code=create[0], object_code=create[1])
        else:
            query = TDatasets.filter_by_creatable(module_code=create[0])
    else:
        query = TDatasets.filter_by_readable()

    if request.is_json:
        query = TDatasets.filter_by_params(request.json, query=query)

    query = ordered(query, TDatasets, arg_name="orderby")

    query = query.options(
        Load(TDatasets).raiseload("*"),
        joinedload(TDatasets.cor_dataset_actor).options(
            joinedload(CorDatasetActor.role),
            joinedload(CorDatasetActor.organism),
        ),
        # next relationships are joined for permission checks purpose:
        joinedload(TDatasets.acquisition_framework).options(
            joinedload(TAcquisitionFramework.cor_af_actor),
        ),
    )
    only = [
        "+cruved",
        "cor_dataset_actor",
        "cor_dataset_actor.nomenclature_actor_role",
        "cor_dataset_actor.organism",
        "cor_dataset_actor.role",
    ]

    if params.get("synthese_records_count", type=int, default=0):
        query = query.options(undefer(TDatasets.synthese_records_count))
        only.append("+synthese_records_count")

    if "modules" in fields:
        query = query.options(joinedload(TDatasets.modules))
        only.append("modules")

    dataset_schema = DatasetSchema(only=only)

    # detect mobile app to enable retro-compatibility hacks
    user_agent = request.headers.get("User-Agent")
    mobile_app = user_agent and user_agent.split("/")[0].lower() == "okhttp"
    dataset_schema.mobile_app = mobile_app
    datasets = db.session.scalars(query).unique().all()
    return dataset_schema.jsonify(datasets, many=True)


def get_af_from_id(id_af, af_list):
    found_af = None
    for af in af_list:
        if af["id_acquisition_framework"] == id_af:
            found_af = af
            break
    return found_af


@routes.route("/dataset/<int:id_dataset>", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="METADATA")
def get_dataset(scope, id_dataset):
    """
    Get one dataset

    .. :quickref: Metadata;

    :param id_dataset: the id_dataset
    :param type: int
    :returns: dict<TDataset>
    """
    dataset = db.get_or_404(TDatasets, id_dataset)
    if not dataset.has_instance_permission(scope=scope):
        raise Forbidden(f"User {g.current_user} cannot read dataset {dataset.id_dataset}")

    dataset_schema = DatasetSchema(
        only=[
            "+cruved",
            "creator",
            "cor_dataset_actor",
            "cor_dataset_actor.nomenclature_actor_role",
            "cor_dataset_actor.organism",
            "cor_dataset_actor.role",
            "modules",
            "nomenclature_data_type",
            "nomenclature_dataset_objectif",
            "nomenclature_collecting_method",
            "nomenclature_data_origin",
            "nomenclature_source_status",
            "nomenclature_resource_type",
            "cor_territories",
            "acquisition_framework",
            "acquisition_framework.creator",
            "acquisition_framework.cor_af_actor",
            "acquisition_framework.cor_af_actor.nomenclature_actor_role",
            "acquisition_framework.cor_af_actor.organism",
            "acquisition_framework.cor_af_actor.role",
            "sources",
        ]
    )
    return dataset_schema.jsonify(dataset)


@routes.route("/dataset/<int:ds_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True, module_code="METADATA")
def delete_dataset(scope, ds_id):
    """
    Delete a dataset

    .. :quickref: Metadata;
    """

    dataset = db.get_or_404(TDatasets, ds_id)
    if not dataset.has_instance_permission(scope=scope):
        raise Forbidden(f"User {g.current_user} cannot delete dataset {dataset.id_dataset}")
    if not dataset.is_deletable():
        raise Conflict(
            "La suppression du jeu de données n'est pas possible "
            "car des données y sont rattachées dans la Synthèse"
        )
    db.session.delete(dataset)
    db.session.commit()
    return "", 204


@routes.route("/uuid_report", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="METADATA")
def uuid_report():
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """

    params = request.args
    ds_id = params.get("id_dataset")
    id_import = params.get("id_import")
    id_module = params.get("id_module")

    query = (
        select(Synthese)
        .where(Synthese.id_module == id_module if id_module is not None else True)
        .where(Synthese.id_dataset == ds_id if ds_id is not None else True)
        .where(Synthese.id_import == id_import if id_import is not None else True)
    )

    query = query.order_by(Synthese.id_synthese)

    data = [
        {
            "identifiantOrigine": row.entity_source_pk_value,
            "identifiant_gn": row.id_synthese,
            "identifiantPermanent (SINP)": row.unique_id_sinp,
            "nomcite": row.nom_cite,
            "jourDateDebut": row.date_min,
            "jourDatefin": row.date_max,
            "observateurIdentite": row.observers,
        }
        for row in db.session.scalars(query).all()
    ]

    return to_csv_resp(
        filename="filename",
        data=data,
        columns=[
            "identifiantOrigine",
            "identifiant_gn",
            "identifiantPermanent (SINP)",
            "nomcite",
            "jourDateDebut",
            "jourDatefin",
            "observateurIdentite",
        ],
    )


@routes.route("/sensi_report", methods=["GET"])  # TODO remove later
@routes.route("/sensi_report/<int:ds_id>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="METADATA")
def sensi_report(ds_id=None):
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """
    # TODO: put ds_id in /sensi_report/<int: ds_id>

    params = request.args
    if not ds_id:
        ds_id = params["id_dataset"]
    dataset = db.get_or_404(TDatasets, ds_id)
    id_import = params.get("id_import")
    id_module = params.get("id_module")

    query = (
        select(
            Synthese,
            func.taxonomie.find_cdref(Synthese.cd_nom).label("cd_ref"),
            func.array_agg(LAreas.area_name).label("codeDepartementCalcule"),
            func.ref_nomenclatures.get_cd_nomenclature(Synthese.id_nomenclature_sensitivity).label(
                "cd_sensi"
            ),
            func.ref_nomenclatures.get_nomenclature_label(
                Synthese.id_nomenclature_bio_status, "fr"
            ).label("occStatutBiologique"),
            TNomenclatures.cd_nomenclature,
            TNomenclatures.label_fr,
        )
        .select_from(Synthese)
        .outerjoin(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
        .outerjoin(LAreas, LAreas.id_area == CorAreaSynthese.id_area)
        .outerjoin(
            TNomenclatures,
            TNomenclatures.id_nomenclature == Synthese.id_nomenclature_sensitivity,
        )
        .where(LAreas.id_type == func.ref_geo.get_id_area_type("DEP"))
        .where(Synthese.id_module == id_module if id_module else True)
        .where(Synthese.id_dataset == ds_id)
        .where(Synthese.id_import == id_import if id_import else True)
    )

    query = query.group_by(
        Synthese.id_synthese, TNomenclatures.cd_nomenclature, TNomenclatures.label_fr
    )

    data = db.session.execute(query).all()

    str_productor = ""
    header = ""
    if len(data) > 0:
        index_productor = -1
        if dataset.cor_dataset_actor:
            for index, actor in enumerate(dataset.cor_dataset_actor):
                # cd_nomenclature producteur = 6
                if actor.nomenclature_actor_role.cd_nomenclature == "6":
                    index_productor = index
            productor = (
                dataset.cor_dataset_actor[index_productor] if index_productor != -1 else None
            )
            if productor:
                if not productor.organism:
                    str_productor = productor.role.nom_complet
                else:
                    str_productor = productor.organism.nom_organisme
    data = [
        {
            "cdNom": row.Synthese.cd_nom,
            "cdRef": row.cd_ref,
            "codeDepartementCalcule": ", ".join(row.codeDepartementCalcule),
            "identifiantOrigine": row.Synthese.entity_source_pk_value,
            "occStatutBiologique": row.occStatutBiologique,
            "identifiantPermanent": row.Synthese.unique_id_sinp,
            "sensible": "Oui" if row.cd_sensi != "0" else "Non",
            "sensiNiveau": f"{row.cd_nomenclature} = {row.label_fr}",
        }
        for row in data
    ]
    sensi_version = db.session.scalars(
        select(func.gn_commons.get_default_parameter("ref_sensi_version"))
    ).one_or_none()

    if sensi_version:
        sensi_version = sensi_version[0]

    # set an header only if the rapport is on a dataset
    header = f""""Rapport de sensibilité"
        "Jeu de données";"{dataset.dataset_name}"
        "Identifiant interne";"{dataset.id_dataset}"
        "Identifiant SINP";"{dataset.unique_dataset_id}"
        "Organisme/personne fournisseur";"{str_productor}"
        "Date de création du rapport";"{dt.datetime.now().strftime("%d/%m/%Y %Hh%M")}"
        "Nombre de données sensibles";"{len(list(filter(lambda row: row["sensible"] == "Oui", data)))}"
        "Nombre de données total dans le fichier";"{len(data)}"
        "sensiVersionReferentiel";"{sensi_version}"
        """

    return my_csv_resp(
        filename="filename",
        data=data,
        columns=[
            "cdNom",
            "cdRef",
            "codeDepartementCalcule",
            "identifiantOrigine",
            "occStatutBiologique",
            "identifiantPermanent",
            "sensible",
            "sensiNiveau",
        ],
        _header=header,
    )


def my_csv_resp(filename, data, columns, _header, separator=";"):
    headers = Headers()
    headers.add("Content-Type", "text/plain")
    headers.add("Content-Disposition", "attachment", filename="export_%s.csv" % filename)
    out = _header + generate_csv_content(columns, data, separator)
    return Response(out, headers=headers)


def datasetHandler(dataset, data):
    datasetSchema = DatasetSchema(
        only=["cor_dataset_actor", "modules", "cor_territories"], unknown=EXCLUDE
    )
    try:
        dataset = datasetSchema.load(data, instance=dataset)
    except ValidationError as error:
        raise BadRequest(error.messages)

    db.session.add(dataset)

    try:
        db.session.commit()
    except IntegrityError as err:
        db.session.rollback()

        if isinstance(err.orig, UniqueViolation):
            detail = getattr(getattr(err.orig, "diag", None), "message_detail", None)
            if not detail:
                detail = str(err.orig).splitlines()[0]

            raise Conflict(detail) from err
        raise InternalServerError("An error occured while creating/updating a dataset !")
    return dataset


@routes.route("/dataset", methods=["POST"])
@permissions.check_cruved_scope("C", module_code="METADATA")
def create_dataset():
    """
    Post one Dataset data
    .. :quickref: Metadata;
    """
    return DatasetSchema().jsonify(
        datasetHandler(
            dataset=TDatasets(id_digitizer=g.current_user.id_role),
            data=request.get_json(),
        )
    )


@routes.route("/dataset/<int:id_dataset>", methods=["POST", "PATCH"])
@permissions.check_cruved_scope("U", get_scope=True, module_code="METADATA")
def update_dataset(id_dataset, scope):
    """
    Post one Dataset data for update dataset
    .. :quickref: Metadata;
    """

    dataset = db.get_or_404(TDatasets, id_dataset)
    if not dataset.has_instance_permission(scope):
        raise Forbidden(f"User {g.current_user} cannot update dataset {dataset.id_dataset}")
    # TODO: specify which fields may be updated
    return DatasetSchema().jsonify(datasetHandler(dataset=dataset, data=request.get_json()))


@routes.route("/dataset/export_pdf/<id_dataset>", methods=["GET", "POST"])
@permissions.check_cruved_scope("E", get_scope=True, module_code="METADATA")
def get_export_pdf_dataset(id_dataset, scope):
    """
    Get a PDF export of one dataset
    """
    dataset = db.get_or_404(TDatasets, id_dataset)
    if not dataset.has_instance_permission(scope=scope):
        raise Forbidden("Vous n'avez pas les droits d'exporter ces informations")
    dataset_schema = DatasetSchema(
        only=[
            "nomenclature_data_type",
            "nomenclature_dataset_objectif",
            "nomenclature_collecting_method",
            "acquisition_framework",
            "cor_dataset_actor.nomenclature_actor_role",
            "cor_dataset_actor.organism",
            "cor_dataset_actor.role",
        ]
    )
    dataset = dataset_schema.dump(dataset)
    if len(dataset.get("dataset_desc")) > 240:
        dataset["dataset_desc"] = dataset["dataset_desc"][:240] + "..."
    url = current_app.config["URL_APPLICATION"] + "/#/metadata/dataset_detail/" + id_dataset
    pdf = (
        MetadataPdfBuilder("dataset_template_pdf.html", dataset)
        .add_css()
        .add_footer(url)
        .add_chart_if_provided(request)
        .add_title(current_app.config["METADATA"]["DS_PDF_TITLE"])
    )

    return current_app.response_class(pdf.build(), content_type="application/pdf")


@routes.route("/acquisition_frameworks", methods=["GET", "POST"])
@login_required
def get_acquisition_frameworks():
    """
    Get a simple list of AF without any nested relationships. The response is paginated, you can specify the number of
    items per page with the `per_page` parameter and the the page number with parameter `page`.
    The default value is 50 items per page. If you specify -1 for `per_page`, all items will be returned.
    Use for AF select in form
    Get the GeoNature CRUVED
    """

    only = ["+cruved"]

    # QUERY
    af_list = TAcquisitionFramework.filter_by_readable()
    params = TypeConversionDict(
        request.get_json(silent=True) if request.method == "POST" else request.args
    )
    if params:
        params_for_filter = params.copy()
        params_for_filter.pop(
            "datasets", None
        )  # create a conflict with datasets param in filter by param
        params_for_filter.pop("per_page", None)
        params_for_filter.pop("page", None)
        af_list = TAcquisitionFramework.filter_by_params(params_for_filter, query=af_list)

    per_page = params.get("per_page", default=50, type=int)
    page = params.get("page", default=1, type=int)

    af_list = af_list.order_by(TAcquisitionFramework.acquisition_framework_name).options(
        Load(TAcquisitionFramework).raiseload("*"),
        # for permission checks:
        joinedload(TAcquisitionFramework.creator),
        joinedload(TAcquisitionFramework.cor_af_actor).options(
            joinedload(CorAcquisitionFrameworkActor.role),
            joinedload(CorAcquisitionFrameworkActor.organism),
        ),
        joinedload(TAcquisitionFramework.datasets).options(
            joinedload(TDatasets.digitizer),
            joinedload(TDatasets.cor_dataset_actor).options(
                joinedload(CorDatasetActor.role),
                joinedload(CorDatasetActor.organism),
            ),
        ),
    )
    if params.get("datasets", default=False, type=int):
        only.extend(
            [
                "datasets.+cruved",
            ]
        )
    if params.get("creator", default=False, type=int):
        only.append("creator")
        af_list = af_list.options(joinedload(TAcquisitionFramework.creator))
    if params.get("actors", default=False, type=int):
        only.extend(
            [
                "cor_af_actor",
                "cor_af_actor.nomenclature_actor_role",
                "cor_af_actor.organism",
                "cor_af_actor.role",
            ]
        )
        af_list = af_list.options(
            joinedload(TAcquisitionFramework.cor_af_actor).options(
                joinedload(CorAcquisitionFrameworkActor.nomenclature_actor_role),
            ),
        )
        if params.get("datasets", default=False, type=int):
            only.extend(
                [
                    "datasets.cor_dataset_actor",
                    "datasets.cor_dataset_actor.nomenclature_actor_role",
                    "datasets.cor_dataset_actor.organism",
                    "datasets.cor_dataset_actor.role",
                ]
            )
            af_list = af_list.options(
                joinedload(TAcquisitionFramework.datasets).options(
                    joinedload(TDatasets.cor_dataset_actor).options(
                        joinedload(CorDatasetActor.nomenclature_actor_role),
                    ),
                ),
            )

    af_schema = AcquisitionFrameworkSchema(only=only, many=True)
    if per_page == -1:
        items = db.session.scalars(af_list).unique().all()
        count_ = len(items)
        result = {
            "items": af_schema.dump(items),
            "total": count_,
            "page": 1,
            "pages": 1,
            "per_page": count_,
            "has_next": False,
            "has_prev": False,
        }
        return jsonify(result)
    else:
        result = db.paginate(
            select=af_list,
            page=page,
            per_page=per_page,
        )
        with pagination_schema(af_schema):
            return jsonify(result)


@routes.route(
    "/acquisition_frameworks/export_pdf/<id_acquisition_framework>",
    methods=["POST", "GET"],
)
@permissions.check_cruved_scope("E", module_code="METADATA")
def get_export_pdf_acquisition_frameworks(id_acquisition_framework):
    """
    Get a PDF export of one acquisition framework
    """
    # Recuperation des données
    af = db.session.get(TAcquisitionFramework, id_acquisition_framework)

    if not af:
        return (
            render_template(
                "error.html",
                error="Le dataset presente des erreurs",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )

    acquisition_framework = af.as_dict(True, depth=2)

    acquisition_framework["stats"] = get_acquisition_framework_stats(id_acquisition_framework)

    acquisition_framework["nomenclature_territorial_level"] = (
        af.nomenclature_territorial_level.as_dict()
    )

    acquisition_framework["nomenclature_financing_type"] = af.nomenclature_financing_type.as_dict()

    if acquisition_framework["acquisition_framework_start_date"]:
        acquisition_framework["acquisition_framework_start_date"] = (
            af.acquisition_framework_start_date.strftime("%d/%m/%Y")
        )

    if acquisition_framework["acquisition_framework_end_date"]:
        acquisition_framework["acquisition_framework_end_date"] = (
            af.acquisition_framework_end_date.strftime("%d/%m/%Y")
        )

    if af.initial_closing_date:
        acquisition_framework["initial_closing_date"] = af.initial_closing_date.strftime(
            "%d-%m-%Y %H:%M"
        )
        acquisition_framework["closed_title"] = current_app.config["METADATA"]["CLOSED_AF_TITLE"]

    # Retrieve labels for additional fields
    if acquisition_framework["additional_data"]:
        updated_additional_data = {}
        list_additional_fields = _get_additional_fields(
            module_code="METADATA", object_code="METADATA_CADRE_ACQUISITION"
        )
        for dict_additional_field in list_additional_fields:
            label_additional_field = dict_additional_field["field_label"]
            name_additional_field = dict_additional_field["field_name"]
            updated_additional_data[label_additional_field] = ""
            if acquisition_framework["additional_data"].get(name_additional_field):
                # Replace name with label for the additional_field
                updated_additional_data[label_additional_field] = acquisition_framework[
                    "additional_data"
                ][name_additional_field]
        acquisition_framework["additional_data"] = updated_additional_data

    url = current_app.config["URL_APPLICATION"] + "/#/metadata/af-card/" + id_acquisition_framework

    pdf = (
        MetadataPdfBuilder(
            "acquisition_framework_template_pdf.html",
            acquisition_framework,
        )
        .add_css()
        .add_footer(url)
        .add_chart_if_provided(request)
        .add_title(current_app.config["METADATA"]["AF_PDF_TITLE"])
    )

    return current_app.response_class(pdf.build(), content_type="application/pdf")


@routes.route("/acquisition_framework/<id_acquisition_framework>", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="METADATA")
def get_acquisition_framework(scope, id_acquisition_framework):
    """
    Get one AF with nomenclatures
    .. :quickref: Metadata;

    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    :returns: dict<TAcquisitionFramework>
    """
    af = db.get_or_404(TAcquisitionFramework, id_acquisition_framework)
    if not af.has_instance_permission(scope=scope):
        raise Forbidden(
            f"User {g.current_user} cannot read acquisition "
            "framework {af.id_acquisition_framework}"
        )

    exclude = request.args.getlist("exclude")
    try:
        af_schema = AcquisitionFrameworkSchema(
            only=[
                "+cruved",
                "creator",
                "nomenclature_territorial_level",
                "nomenclature_financing_type",
                "cor_af_actor",
                "cor_af_actor.nomenclature_actor_role",
                "cor_af_actor.organism",
                "cor_af_actor.role",
                "cor_volets_sinp",
                "cor_objectifs",
                "cor_territories",
                "datasets",
                "datasets.creator",
                "datasets.nomenclature_data_type",
                "datasets.cor_dataset_actor",
                "datasets.cor_dataset_actor.nomenclature_actor_role",
                "datasets.cor_dataset_actor.organism",
                "datasets.cor_dataset_actor.role",
            ],
            exclude=exclude,
        )
    except ValueError as e:
        raise BadRequest(str(e))
    return af_schema.jsonify(af)


@routes.route("/acquisition_framework/<int:af_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True, module_code="METADATA")
def delete_acquisition_framework(scope, af_id):
    """
    Delete an acquisition framework
    .. :quickref: Metadata;
    """
    af = db.get_or_404(TAcquisitionFramework, af_id)
    if not af.has_instance_permission(scope):
        raise Forbidden(
            f"User {g.current_user} cannot delete acquisition framework {af.id_acquisition_framework}"
        )
    if af.has_datasets():
        raise Conflict(
            "La suppression du cadre d’acquisition est impossible "
            "car celui-ci contient des jeux de données."
        )

    if af.has_child_acquisition_framework():
        raise Conflict(
            "La suppression du cadre d’acquisition est impossible "
            "car celui-ci est le parent d'autre(s) cadre(s) d'acquisition."
        )
    db.session.delete(af)
    db.session.commit()

    return "", 204


def acquisitionFrameworkHandler(request, *, acquisition_framework):
    # Test des droits d'édition du acquisition framework si modification

    # 🔎 Récupération des données brutes du body

    if acquisition_framework.id_acquisition_framework is not None:
        user_cruved = get_scopes_by_action(module_code="METADATA")

        # verification des droits d'édition pour le acquisition framework
        if not acquisition_framework.has_instance_permission(user_cruved["U"]):
            raise Forbidden(
                "User {} has no right in acquisition_framework {}".format(
                    g.current_user, acquisition_framework.id_acquisition_framework
                )
            )
    else:
        acquisition_framework.id_digitizer = g.current_user.id_role

    acquisitionFrameworkSchema = AcquisitionFrameworkSchema(
        only=["cor_af_actor", "cor_volets_sinp", "cor_objectifs", "cor_territories"],
        unknown=EXCLUDE,
    )
    try:
        acquisition_framework = acquisitionFrameworkSchema.load(
            request.get_json(), instance=acquisition_framework
        )
    except ValidationError as error:
        log.exception(error)
        raise BadRequest(error.messages)

    db.session.add(acquisition_framework)
    try:
        db.session.commit()
    except IntegrityError as err:
        db.session.rollback()

        if isinstance(err.orig, UniqueViolation):
            detail = getattr(getattr(err.orig, "diag", None), "message_detail", None)
            if not detail:
                detail = str(err.orig).splitlines()[0]

            raise Conflict(detail) from err
        raise InternalServerError("An error occured while creating/updating a dataset !")

    return acquisition_framework


@routes.route("/acquisition_framework", methods=["POST"])
@permissions.check_cruved_scope("C", module_code="METADATA")
def create_acquisition_framework():
    """
    Post one AcquisitionFramework data
    .. :quickref: Metadata;
    """
    # TODO: spécifier only
    # create new acquisition_framework
    return AcquisitionFrameworkSchema(only=[]).dump(
        acquisitionFrameworkHandler(request=request, acquisition_framework=TAcquisitionFramework())
    )


@routes.route("/acquisition_framework/<int:id_acquisition_framework>", methods=["POST"])
@permissions.check_cruved_scope("U", get_scope=True, module_code="METADATA")
def updateAcquisitionFramework(id_acquisition_framework, scope):
    """
    Post one AcquisitionFramework data for update acquisition_framework
    .. :quickref: Metadata;
    """
    af = db.get_or_404(TAcquisitionFramework, id_acquisition_framework)
    if not af.has_instance_permission(scope=scope):
        raise Forbidden(
            f"User {g.current_user} cannot update "
            f"acquisition framework {af.id_acquisition_framework}"
        )
    return AcquisitionFrameworkSchema().dump(
        acquisitionFrameworkHandler(request=request, acquisition_framework=af)
    )


@routes.route("/acquisition_framework/<id_acquisition_framework>/stats", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="METADATA")
@json_resp
def get_acquisition_framework_stats_route(id_acquisition_framework):
    """
    Get stats from one AF
    .. :quickref: Metadata;
    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    return get_acquisition_framework_stats(id_acquisition_framework)


@routes.route("/dataset/<id_dataset>/stats", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="METADATA")
@json_resp
def get_dataset_stats(id_dataset):
    """
    Get stats from one DS
    .. :quickref: Metadata;
    :param id_dataset: the id_dataset
    :param type: int
    """
    dict_nb_obs = {}

    nb_obs_synthese = db.session.execute(
        select(func.count(Synthese.id_synthese)).where(Synthese.id_dataset == id_dataset)
    ).scalar_one()

    dict_nb_obs["SYNTHESE"] = nb_obs_synthese

    from geonature.utils.module import iter_modules_dist

    for module_dist in iter_modules_dist():
        module_name = module_dist.name
        is_current_module_installed = current_app.dict_modules_is_installed[module_name]
        if is_current_module_installed:
            module_statistics = None
            try:
                module_statistics = module_dist.entry_points["statistics"]
            except KeyError:
                pass
            if module_statistics:
                statistics = __import__(module_name + ".statistics", fromlist=["statistics"])
                nb_observations = statistics.get_dataset_nb_observations(id_dataset)
                module_code = module_dist.entry_points["code"].load()
                dict_nb_obs[module_code] = nb_observations

    total_nb_obs = sum(dict_nb_obs.values())

    return dict(
        dict_nb_obs=dict_nb_obs,
        total_nb_obs=total_nb_obs,
    )


@routes.route("/acquisition_framework/<id_acquisition_framework>/bbox", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="METADATA")
@json_resp
def get_acquisition_framework_bbox(id_acquisition_framework):
    """
    Get BBOX from one AF
    .. :quickref: Metadata;
    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """

    dataset_ids = db.session.scalars(
        select(TDatasets.id_dataset).where(
            TDatasets.id_acquisition_framework == id_acquisition_framework
        )
    ).all()

    # geojsonData will never be empty, if no entries matching the query condition(s), it will contains [(None,)]
    geojsonData = db.session.execute(
        select(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .where(Synthese.id_dataset.in_(dataset_ids))
        .limit(1)
    ).first()[0]

    return json.loads(geojsonData) if geojsonData else None


def call_extended_af_publish(af_id):
    """
    If a route with the name extended_publish, we call it.
    """
    extended_route = current_app.view_functions.get(
        current_app.config["METADATA"]["EXTENDED_AF_PUBLISH_ROUTE_NAME"]
    )
    if extended_route:
        try:
            extended_route(af_id)
        except Exception as excp:
            raise GeoNatureError(
                f"Custom route extended_af_publish called on {af_id} raised : {excp} "
            )


@routes.route("/acquisition_framework/open/<int:af_id>", methods=["GET"])
@permissions.check_cruved_scope("U", module_code="METADATA")
@json_resp
def open_acquisition_framework(af_id):
    """
    Open an acquisition framework
    """
    if not current_app.config["METADATA"]["AF_OPENABLE"]:
        raise GeoNatureError("Acquisition Frameworks are not openable")
    af = db.session.get(TAcquisitionFramework, af_id)
    if not af:
        raise NotFound(f"Acquisition framework {af_id} not found")
    af.opened = True
    db.session.commit()
    return af.as_dict()


@routes.route("/acquisition_framework/publish/<int:af_id>", methods=["GET"])
@permissions.check_cruved_scope("U", module_code="METADATA")
@json_resp
def close_acquisition_framework(af_id):
    """
    close an acquisition framework
    .. :quickref: Metadata;
    """

    # The AF must contain DS to be published
    datasets = (
        db.session.scalars(select(TDatasets).filter_by(id_acquisition_framework=af_id))
        .unique()
        .all()
    )

    if not datasets:
        raise Conflict("Le cadre doit contenir des jeux de données")

    af_count = db.session.execute(
        select(func.count("*"))
        .select_from(TAcquisitionFramework)
        .where(
            TAcquisitionFramework.id_acquisition_framework == af_id,
            TAcquisitionFramework.datasets.any(TDatasets.nb_observations > 0),
        )
    ).scalar_one()

    if af_count < 1:
        raise Conflict("Tous les jeux de données du cadre d’acquisition sont vides")

    # After publishing an AF, we set it as closed and all its DS as inactive
    for dataset in datasets:
        dataset.active = False

    # If the AF if closed for the first time, we set it an initial_closing_date as the actual time
    af = db.session.get(TAcquisitionFramework, af_id)
    af.opened = False
    if af.initial_closing_date is None:
        af.initial_closing_date = dt.datetime.now()
    try:
        db.session.flush()  # tester si le commit devrait fonctionner
        call_extended_af_publish(af_id)
    except (DatabaseError, GeoNatureError) as error:
        db.session.rollback()  # Si ça plante, on annule tout
        log.error(
            f"Erreur de type {type(error).__name__} lors de la publication du cadre : {error}"
        )
        raise Exception("Erreur lors de la publication du cadre, cadre non publié")
    else:
        db.session.commit()  # On commit que si tout a bien fonctionné

    return af.as_dict()
