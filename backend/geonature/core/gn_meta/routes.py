"""
    Routes for gn_meta 
"""
import datetime as dt
import json
import logging
from pathlib import Path
from binascii import a2b_base64
from lxml import etree as ET

from flask import (
    Blueprint,
    current_app,
    request,
    render_template,
    send_from_directory,
    copy_current_request_context,
    Response,
    g,
)
from flask.json import jsonify
from sqlalchemy import inspect, and_, or_
from sqlalchemy.sql import text, exists, select, update
from sqlalchemy.sql.functions import func
from sqlalchemy.orm import Load, joinedload, raiseload
from werkzeug.exceptions import Conflict, BadRequest, Forbidden, NotFound
from werkzeug.datastructures import Headers, MultiDict
from werkzeug.utils import secure_filename
from marshmallow import ValidationError, EXCLUDE

from geonature.utils.config import config
from geonature.utils.env import DB, db
from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    CorAreaSynthese,
)
from geonature.core.gn_permissions.decorators import login_required

from ref_geo.models import LAreas
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.tools import InsufficientRightsError
from pypnusershub.db.models import User

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    CorDatasetProtocol,
    CorDatasetTerritory,
    TAcquisitionFramework,
    TAcquisitionFrameworkDetails,
    CorAcquisitionFrameworkActor,
    CorAcquisitionFrameworkObjectif,
    CorAcquisitionFrameworkVoletSINP,
)
from geonature.core.gn_meta.repositories import (
    get_metadata_list,
)
from geonature.core.gn_meta.schemas import (
    AcquisitionFrameworkSchema,
    DatasetSchema,
)
from utils_flask_sqla.response import json_resp, to_csv_resp, generate_csv_content
from werkzeug.datastructures import Headers
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import (
    cruved_scope_for_user_in_module,
    get_scopes_by_action,
)
from geonature.core.gn_meta.mtd import mtd_utils
import geonature.utils.filemanager as fm
import geonature.utils.utilsmails as mail
from geonature.utils.errors import GeonatureApiError
from .mtd import sync_af_and_ds as mtd_sync_af_and_ds

from ref_geo.models import LAreas

routes = Blueprint("gn_meta", __name__, cli_group="metadata")

# get the root logger
log = logging.getLogger()


if config["CAS_PUBLIC"]["CAS_AUTHENTIFICATION"]:

    @routes.before_request
    def synchronize_mtd():
        if request.endpoint in ["gn_meta.get_datasets", "gn_meta.get_acquisition_frameworks_list"]:
            try:
                mtd_utils.post_jdd_from_user(id_user=g.current_user.id_role)
            except Exception as e:
                log.exception("Error while get JDD via MTD")


@routes.route("/datasets", methods=["GET"])
@login_required
def get_datasets():
    """
    Get datasets list

    .. :quickref: Metadata;

    :query boolean active: filter on active fiel
    :query int id_acquisition_framework: get only dataset of given AF
    :returns:  `list<TDatasets>`
    """
    params = MultiDict(request.args)
    allowed_fields = {"modules"}
    fields = params.pop("fields", None)
    if fields:
        fields = fields.split(",")
        if set(fields) - allowed_fields:
            raise BadRequest(f"Allowed fields: {','.join(allowed_fields)}")
    if "create" in params:
        query = TDatasets.query.filter_by_creatable(params.pop("create"))
    else:
        query = TDatasets.query.filter_by_readable()
    query = query.filter_by_params(params)
    data = [d.as_dict(fields=fields) for d in query.all()]
    user_agent = request.headers.get("User-Agent")
    if (
        user_agent and user_agent.split("/")[0].lower() == "okhttp"
    ):  # retro-compatibility for mobile app
        return jsonify({"data": data})
    return jsonify(data)


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
    dataset = TDatasets.query.get_or_404(id_dataset)
    if not dataset.has_instance_permission(scope=scope):
        raise Forbidden(f"User {g.current_user} cannot read dataset {dataset.id_dataset}")

    dataset_schema = DatasetSchema(
        only=[
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

    # TODO: Replace with get_scopes_by_action
    # check this in front
    user_cruved = cruved_scope_for_user_in_module(
        id_role=g.current_user.id_role,
        module_code="METADATA",
    )[0]
    dataset_schema.context = {"user_cruved": user_cruved}

    return dataset_schema.jsonify(dataset)


@routes.route("/dataset/<int:ds_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True, module_code="METADATA")
def delete_dataset(scope, ds_id):
    """
    Delete a dataset

    .. :quickref: Metadata;
    """

    dataset = TDatasets.query.get_or_404(ds_id)
    if not dataset.has_instance_permission(scope=scope):
        raise Forbidden(f"User {g.current_user} cannot delete dataset {dataset.id_dataset}")
    if not dataset.is_deletable():
        raise Conflict(
            "La suppression du jeu de données n'est pas possible "
            "car des données y sont rattachées dans la Synthèse"
        )
    DB.session.delete(dataset)
    DB.session.commit()
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

    query = DB.session.query(Synthese).select_from(Synthese)

    if id_module:
        query = query.filter(Synthese.id_module == id_module)

    if ds_id:
        query = query.filter(Synthese.id_dataset == ds_id)

    if id_import:
        query = query.outerjoin(TSources, TSources.id_source == Synthese.id_source).filter(
            TSources.name_source == "Import(id={})".format(id_import)
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
        for row in query.all()
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


@routes.route("/sensi_report", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="METADATA")
def sensi_report():
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """
    # TODO: put ds_id in /sensi_report/<int: ds_id>

    params = request.args
    ds_id = params["id_dataset"]
    dataset = TDatasets.query.get_or_404(ds_id)
    id_import = params.get("id_import")
    id_module = params.get("id_module")

    query = (
        DB.session.query(
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
            TNomenclatures, TNomenclatures.id_nomenclature == Synthese.id_nomenclature_sensitivity
        )
        .filter(LAreas.id_type == func.ref_geo.get_id_area_type("DEP"))
    )

    if id_module:
        query = query.filter(Synthese.id_module == id_module)

    query = query.filter(Synthese.id_dataset == ds_id)

    if id_import:
        query = query.outerjoin(TSources, TSources.id_source == Synthese.id_source).filter(
            TSources.name_source == "Import(id={})".format(id_import)
        )

    data = query.group_by(
        Synthese.id_synthese, TNomenclatures.cd_nomenclature, TNomenclatures.label_fr
    ).all()

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
    sensi_version = DB.session.query(
        func.gn_commons.get_default_parameter("ref_sensi_version")
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

    DB.session.add(dataset)
    DB.session.commit()
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
            dataset=TDatasets(id_digitizer=g.current_user.id_role), data=request.get_json()
        )
    )


@routes.route("/dataset/<int:id_dataset>", methods=["POST", "PATCH"])
@permissions.check_cruved_scope("U", get_scope=True, module_code="METADATA")
def update_dataset(id_dataset, scope):
    """
    Post one Dataset data for update dataset
    .. :quickref: Metadata;
    """

    dataset = TDatasets.query.get_or_404(id_dataset)
    if not dataset.has_instance_permission(scope):
        raise Forbidden(f"User {g.current_user} cannot update dataset {dataset.id_dataset}")
    # TODO: specify which fields may be updated
    return DatasetSchema().jsonify(datasetHandler(dataset=dataset, data=request.get_json()))


@routes.route("/dataset/export_pdf", methods=["POST"])
@permissions.check_cruved_scope("E", get_scope=True, module_code="METADATA")
def get_export_pdf_dataset(scope):
    """
    Get a PDF export of one dataset
    """
    id_dataset = request.args.get("dataset")
    dataset = TDatasets.query.get_or_404(id_dataset)
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
        dataset["dataset_desc"] = dataset.get("dataset_desc")[:240] + "..."

    dataset["css"] = {
        "logo": "Logo_pdf.png",
        "bandeau": "Bandeau_pdf.png",
        "entite": "sinp",
    }
    dataset["title"] = current_app.config["METADATA"]["DS_PDF_TITLE"]

    date = dt.datetime.now().strftime("%d/%m/%Y")

    dataset["footer"] = {
        "url": current_app.config["URL_APPLICATION"] + "/#/metadata/dataset_detail/" + id_dataset,
        "date": date,
    }
    # chart
    if request.is_json and request.json is not None:
        dataset["chart"] = request.json["chart"]
    # Appel de la methode pour generer un pdf
    return fm.generate_pdf("dataset_template_pdf.html", dataset)


@routes.route("/acquisition_frameworks", methods=["GET", "POST"])
@permissions.check_cruved_scope(
    "R",
    get_scope=True,
)
def get_acquisition_frameworks(scope):
    """
    Get a simple list of AF without any nested relationships
    Use for AF select in form
    Get the GeoNature CRUVED
    """
    only = []
    # QUERY
    af_list = TAcquisitionFramework.query.filter_by_readable()
    if request.method == "POST":
        af_list = af_list.filter_by_params(request.json)

    af_list = af_list.order_by(TAcquisitionFramework.acquisition_framework_name).options(
        Load(TAcquisitionFramework).raiseload("*"),
        # for permission checks:
        joinedload("creator"),
        joinedload("cor_af_actor").options(
            joinedload("role"),
            joinedload("organism"),
        ),
        joinedload("t_datasets").options(
            joinedload("digitizer"),
            joinedload("cor_dataset_actor").options(
                joinedload("role"),
                joinedload("organism"),
            ),
        ),
    )
    if request.args.get("datasets", default=False, type=int):
        only.extend(
            [
                "t_datasets",
            ]
        )
    if request.args.get("creator", default=False, type=int):
        only.append("creator")
        af_list = af_list.options(joinedload("creator"))
    if request.args.get("actors", default=False, type=int):
        only.extend(
            [
                "cor_af_actor",
                "cor_af_actor.nomenclature_actor_role",
                "cor_af_actor.organism",
                "cor_af_actor.role",
            ]
        )
        af_list = af_list.options(
            joinedload("cor_af_actor").options(
                joinedload("nomenclature_actor_role"),
            ),
        )
        if request.args.get("datasets", default=False, type=int):
            only.extend(
                [
                    "t_datasets.cor_dataset_actor",
                    "t_datasets.cor_dataset_actor.nomenclature_actor_role",
                    "t_datasets.cor_dataset_actor.organism",
                    "t_datasets.cor_dataset_actor.role",
                ]
            )
            af_list = af_list.options(
                joinedload("t_datasets").options(
                    joinedload("cor_dataset_actor").options(
                        joinedload("nomenclature_actor_role"),
                    ),
                ),
            )
    af_schema = AcquisitionFrameworkSchema(only=only)
    user_cruved = cruved_scope_for_user_in_module(
        id_role=g.current_user.id_role,
        module_code="METADATA",
    )[0]
    af_schema.context = {"user_cruved": user_cruved}
    return af_schema.jsonify(af_list.all(), many=True)


@routes.route("/list/acquisition_frameworks", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="METADATA")
def get_acquisition_frameworks_list(scope):
    """
    Get all AF with their datasets
    Use in metadata module for list of AF and DS
    Add the CRUVED permission for each row (Dataset and AD)

    .. :quickref: Metadata;

    :qparam list excluded_fields: fields excluded from serialization
    :qparam boolean nested: Default False - serialized relationships. If false: remove add all relationships in excluded_fields

    """
    params = request.args.to_dict()
    params["orderby"] = "acquisition_framework_name"

    if "selector" not in params:
        params["selector"] = None

    user_cruved = cruved_scope_for_user_in_module(
        id_role=g.current_user.id_role,
        module_code="METADATA",
    )[0]
    nested_serialization = params.get("nested", False)
    nested_serialization = True if nested_serialization == "true" else False
    exclude_fields = []
    if "excluded_fields" in params:
        exclude_fields = params.get("excluded_fields").split(",")

    if not nested_serialization:
        # exclude all relationships from serialization if nested = false
        exclude_fields = [db_rel.key for db_rel in inspect(TAcquisitionFramework).relationships]

    acquisitionFrameworkSchema = AcquisitionFrameworkSchema(exclude=exclude_fields)
    acquisitionFrameworkSchema.context = {"user_cruved": user_cruved}
    return acquisitionFrameworkSchema.jsonify(
        get_metadata_list(g.current_user, scope, params, exclude_fields).all(), many=True
    )


@routes.route("/acquisition_frameworks/export_pdf", methods=["POST"])
@permissions.check_cruved_scope("E", module_code="METADATA")
def get_export_pdf_acquisition_frameworks():
    """
    Get a PDF export of one acquisition
    """

    id_acquisition_framework = request.args.get("af")
    # Recuperation des données
    af = DB.session.query(TAcquisitionFrameworkDetails).get(id_acquisition_framework)
    acquisition_framework = af.as_dict(True, depth=2)
    dataset_ids = [d.id_dataset for d in af.t_datasets]
    nb_data = len(dataset_ids)
    nb_taxons = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .distinct()
        .count()
    )
    nb_observations = (
        DB.session.query(Synthese.cd_nom).filter(Synthese.id_dataset.in_(dataset_ids)).count()
    )
    nb_habitat = 0

    # Check if pr_occhab exist
    check_schema_query = exists(
        select([text("schema_name")])
        .select_from(text("information_schema.schemata"))
        .where(text("schema_name = 'pr_occhab'"))
    )

    if DB.session.query(check_schema_query).scalar() and nb_data > 0:
        query = (
            "SELECT count(*) FROM pr_occhab.t_stations s, pr_occhab.t_habitats h WHERE s.id_station = h.id_station AND s.id_dataset in \
        ("
            + str(dataset_ids).strip("[]")
            + ")"
        )

        nb_habitat = DB.engine.execute(text(query)).first()[0]

    acquisition_framework["stats"] = {
        "nb_data": nb_data,
        "nb_taxons": nb_taxons,
        "nb_observations": nb_observations,
        "nb_habitats": nb_habitat,
    }

    if request.is_json and request.json is not None:
        acquisition_framework["chart"] = request.json["chart"]

    if acquisition_framework:
        acquisition_framework[
            "nomenclature_territorial_level"
        ] = af.nomenclature_territorial_level.as_dict()
        acquisition_framework[
            "nomenclature_financing_type"
        ] = af.nomenclature_financing_type.as_dict()
        if acquisition_framework["acquisition_framework_start_date"]:
            acquisition_framework[
                "acquisition_framework_start_date"
            ] = af.acquisition_framework_start_date.strftime("%d/%m/%Y")
        if acquisition_framework["acquisition_framework_end_date"]:
            acquisition_framework[
                "acquisition_framework_end_date"
            ] = af.acquisition_framework_end_date.strftime("%d/%m/%Y")
        acquisition_framework["css"] = {
            "logo": "Logo_pdf.png",
            "bandeau": "Bandeau_pdf.png",
            "entite": "sinp",
        }
        acquisition_framework["pdf_title"] = current_app.config["METADATA"]["AF_PDF_TITLE"]
        date = dt.datetime.now().strftime("%d/%m/%Y")
        acquisition_framework["footer"] = {
            "url": current_app.config["URL_APPLICATION"]
            + "/#/metadata/af-card/"
            + id_acquisition_framework,
            "date": date,
        }
    else:
        return (
            render_template(
                "error.html",
                error="Le dataset presente des erreurs",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )
    if af.initial_closing_date:
        acquisition_framework["initial_closing_date"] = af.initial_closing_date.strftime(
            "%d-%m-%Y %H:%M"
        )
        acquisition_framework["closed_title"] = current_app.config["METADATA"]["CLOSED_AF_TITLE"]

    # Appel de la methode pour generer un pdf
    return fm.generate_pdf("acquisition_framework_template_pdf.html", acquisition_framework)


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
    af = TAcquisitionFramework.query.get_or_404(id_acquisition_framework)
    if not af.has_instance_permission(scope=scope):
        raise Forbidden(
            f"User {g.current_user} cannot read acquisition "
            "framework {af.id_acquisition_framework}"
        )

    exclude = request.args.getlist("exclude")
    try:
        af_schema = AcquisitionFrameworkSchema(
            only=[
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
                "t_datasets",
                "t_datasets.creator",
                "t_datasets.nomenclature_data_type",
                "t_datasets.cor_dataset_actor",
                "t_datasets.cor_dataset_actor.nomenclature_actor_role",
                "t_datasets.cor_dataset_actor.organism",
                "t_datasets.cor_dataset_actor.role",
            ],
            exclude=exclude,
        )
    except ValueError as e:
        raise BadRequest(str(e))

    user_cruved = cruved_scope_for_user_in_module(
        id_role=g.current_user.id_role,
        module_code="METADATA",
    )[0]
    af_schema.context = {"user_cruved": user_cruved}

    return af_schema.jsonify(af)


@routes.route("/acquisition_framework/<int:af_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True, module_code="METADATA")
def delete_acquisition_framework(scope, af_id):
    """
    Delete an acquisition framework
    .. :quickref: Metadata;
    """
    af = TAcquisitionFramework.query.get_or_404(af_id)
    if not af.has_instance_permission(scope):
        raise Forbidden(
            f"User {g.current_user} cannot delete acquisition framework {af.id_acquisition_framework}"
        )
    if not af.is_deletable():
        raise Conflict(
            "La suppression du cadre d’acquisition n'est pas possible "
            "car celui-ci contient des jeux de données."
        )
    db.session.delete(af)
    db.session.commit()

    return "", 204


def acquisitionFrameworkHandler(request, *, acquisition_framework):

    # Test des droits d'édition du acquisition framework si modification
    if acquisition_framework.id_acquisition_framework is not None:
        user_cruved = get_scopes_by_action(module_code="META_DATA")

        # verification des droits d'édition pour le acquisition framework
        if not acquisition_framework.has_instance_permission(user_cruved["U"]):
            raise InsufficientRightsError(
                "User {} has no right in acquisition_framework {}".format(
                    g.current_user, acquisition_framework.id_acquisition_framework
                ),
                403,
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

    DB.session.add(acquisition_framework)
    DB.session.commit()

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
    af = TAcquisitionFramework.query.get_or_404(id_acquisition_framework)
    if not af.has_instance_permission(scope=scope):
        raise Forbidden(
            f"User {g.current_user} cannot update "
            "acquisition framework {af.id_acquisition_framework}"
        )
    return AcquisitionFrameworkSchema().dump(
        acquisitionFrameworkHandler(request=request, acquisition_framework=af)
    )


@routes.route("/acquisition_framework/<id_acquisition_framework>/stats", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="METADATA")
@json_resp
def get_acquisition_framework_stats(id_acquisition_framework):
    """
    Get stats from one AF
    .. :quickref: Metadata;
    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    datasets = TDatasets.query.filter(
        TDatasets.id_acquisition_framework == id_acquisition_framework
    ).all()
    dataset_ids = [d.id_dataset for d in datasets]

    nb_dataset = len(dataset_ids)
    nb_taxons = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .distinct()
        .count()
    )
    nb_observations = (
        DB.session.query(Synthese.cd_nom).filter(Synthese.id_dataset.in_(dataset_ids)).count()
    )
    nb_habitat = 0

    # Check if pr_occhab exist
    check_schema_query = exists(
        select([text("schema_name")])
        .select_from(text("information_schema.schemata"))
        .where(text("schema_name = 'pr_occhab'"))
    )

    if DB.session.query(check_schema_query).scalar() and nb_dataset > 0:
        query = (
            "SELECT count(*) FROM pr_occhab.t_stations s, pr_occhab.t_habitats h WHERE s.id_station = h.id_station AND s.id_dataset in \
        ("
            + str(dataset_ids).strip("[]")
            + ")"
        )

        nb_habitat = DB.engine.execute(text(query)).first()[0]

    return {
        "nb_dataset": nb_dataset,
        "nb_taxons": nb_taxons,
        "nb_observations": nb_observations,
        "nb_habitats": nb_habitat,
    }


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
    datasets = TDatasets.query.filter(
        TDatasets.id_acquisition_framework == id_acquisition_framework
    ).all()
    dataset_ids = [d.id_dataset for d in datasets]
    geojsonData = (
        DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .first()[0]
    )
    return json.loads(geojsonData) if geojsonData else None


def publish_acquisition_framework_mail(af):
    """
    Method for sending a mail during the publication process
    """

    # Parsing the AF XML from MTD to get the idTPS parameter
    af_xml = mtd_utils.get_acquisition_framework(str(af.unique_acquisition_framework_id).upper())
    xml_parser = ET.XMLParser(ns_clean=True, recover=True, encoding="utf-8")
    namespace = current_app.config["XML_NAMESPACE"]
    root = ET.fromstring(af_xml, parser=xml_parser)
    try:
        ca = root.find(".//" + namespace + "CadreAcquisition")
        ca_idtps = mtd_utils.get_tag_content(ca, "idTPS")
    except AttributeError:
        ca_idtps = ""

    # Generate the links for the AF's deposite certificate and framework download
    pdf_url = (
        current_app.config["API_ENDPOINT"]
        + "/meta/acquisition_frameworks/export_pdf/"
        + str(af.id_acquisition_framework)
    )

    # Mail subject
    mail_subject = (
        "Dépôt du cadre d'acquisition " + str(af.unique_acquisition_framework_id).upper()
    )
    mail_subject_base = current_app.config["METADATA"]["MAIL_SUBJECT_AF_CLOSED_BASE"]
    if mail_subject_base:
        mail_subject = mail_subject_base + " " + mail_subject
    if ca_idtps:
        mail_subject = mail_subject + " pour le dossier {}".format(ca_idtps)

    # Mail content
    mail_content = f"""Bonjour,<br>
    <br>
    Le cadre d'acquisition <i> "{af.acquisition_framework_name}" </i> dont l’identifiant est
    "{str(af.unique_acquisition_framework_id).upper()}" que vous nous avez transmis a été déposé"""

    mail_content_additions = current_app.config["METADATA"]["MAIL_CONTENT_AF_CLOSED_ADDITION"]
    mail_content_pdf = current_app.config["METADATA"]["MAIL_CONTENT_AF_CLOSED_PDF"]
    mail_content_greetings = current_app.config["METADATA"]["MAIL_CONTENT_AF_CLOSED_GREETINGS"]

    if ca_idtps:
        mail_content = mail_content + f"dans le cadre du dossier {ca_idtps}"

    if mail_content_additions:
        mail_content = mail_content + mail_content_additions
    else:
        mail_content = mail_content + ".<br>"

    if mail_content_pdf:
        mail_content = mail_content + mail_content_pdf.format(pdf_url) + pdf_url + "<br>"

    if mail_content_greetings:
        mail_content = mail_content + mail_content_greetings

    # Mail recipients : if the publisher is the the AF digitizer, we send a mail to both of them
    mail_recipients = set()
    cur_user = g.current_user
    if cur_user and cur_user.email:
        mail_recipients.add(cur_user.email)

    if af.id_digitizer:
        digitizer = DB.session.query(User).get(af.id_digitizer)
        if digitizer and digitizer.email:
            mail_recipients.add(digitizer.email)
    # Mail sent
    if mail_subject and mail_content and len(mail_recipients) > 0:
        mail.send_mail(list(mail_recipients), mail_subject, mail_content)


@routes.route("/acquisition_framework/publish/<int:af_id>", methods=["GET"])
@permissions.check_cruved_scope("E", module_code="METADATA")
@json_resp
def publish_acquisition_framework(af_id):
    """
    Publish an acquisition framework
    .. :quickref: Metadata;
    """

    # The AF must contain DS to be published
    datasets = TDatasets.query.filter_by(id_acquisition_framework=af_id).all()

    if not datasets:
        raise Conflict("Le cadre doit contenir des jeux de données")

    if not db.session.query(
        TAcquisitionFramework.query.filter(
            TAcquisitionFramework.id_acquisition_framework == af_id,
            TAcquisitionFramework.datasets.any(TDatasets.synthese_records.any()),
        ).exists()
    ).scalar():
        raise Conflict("Tous les jeux de données du cadre d’acquisition sont vides")

    # After publishing an AF, we set it as closed and all its DS as inactive
    for dataset in datasets:
        dataset.active = False

    # If the AF if closed for the first time, we set it an initial_closing_date as the actual time
    af = DB.session.query(TAcquisitionFramework).get(af_id)
    af.opened = False
    if af.initial_closing_date is None:
        af.initial_closing_date = dt.datetime.now()

    # first commit before sending mail
    DB.session.commit()
    # We send a mail to notify the AF publication
    publish_acquisition_framework_mail(af)

    return af.as_dict()


@routes.cli.command()
def mtd_sync():
    mtd_sync_af_and_ds()
