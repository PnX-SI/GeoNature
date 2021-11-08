"""
    Routes for gn_meta 
"""
import datetime as dt
import json
import logging
import threading
import click


from pathlib import Path
from binascii import a2b_base64
from flask.json import jsonify
from werkzeug.utils import secure_filename

from lxml import etree as ET

from flask import (
    Blueprint,
    current_app,
    request,
    render_template,
    send_from_directory,
    copy_current_request_context,
    Response,
)
from sqlalchemy import inspect
from sqlalchemy.sql import text, exists, select, update
from sqlalchemy.sql.functions import func
from werkzeug.exceptions import BadRequest, Forbidden, NotFound
from werkzeug.datastructures import Headers
from marshmallow import ValidationError, EXCLUDE


from geonature.utils.env import DB, BACKEND_DIR
from geonature.core.gn_synthese.models import (
    Synthese,
    TSources,
    CorAreaSynthese,
    CorSensitivitySynthese,
)
from geonature.core.ref_geo.models import LAreas

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.tools import InsufficientRightsError
from pypnusershub.db.models import User

from binascii import a2b_base64

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
    get_datasets_cruved,
    get_metadata_list,
)
from geonature.core.gn_meta.schemas import (
    AcquisitionFrameworkSchema,
    DatasetSchema,
)
from utils_flask_sqla.response import json_resp, to_csv_resp, generate_csv_content
from werkzeug.datastructures import Headers
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_meta.mtd import mtd_utils
from .mtd import sync_af_and_ds as mtd_sync_af_and_ds
import geonature.utils.filemanager as fm
import geonature.utils.utilsmails as mail
from geonature.utils.errors import GeonatureApiError




routes = Blueprint("gn_meta", __name__, cli_group='metadata')

# get the root logger
log = logging.getLogger()



@routes.route("/list/datasets", methods=["GET"])
@json_resp
def get_datasets_list():
    q = DB.session.query(TDatasets)
    data = q.all()
    return [d.as_dict(fields=["id_dataset", "dataset_name"]) for d in data]


# TODO: quel cruved on recupère sur une route comme celle là
# celui du module admin (meta) ou celui de geonature (route utilisé dans tous les modules...)
@routes.route("/datasets", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_datasets(info_role):
    """
    Get datasets list
    
    .. :quickref: Metadata;

    :param info_role: add with kwargs
    :type info_role: TRole
    :query boolean active: filter on active fiel
    :query int id_acquisition_framework: get only dataset of given AF
    :returns:  `dict{'data':list<TDatasets>, 'with_erros': <boolean>}`
    """
    with_mtd_error = False
    if current_app.config["CAS_PUBLIC"]["CAS_AUTHENTIFICATION"]:
        # synchronise the CA and JDD from the MTD WS
        try:
            mtd_utils.post_jdd_from_user(
                id_user=info_role.id_role, id_organism=info_role.id_organisme
            )
        except Exception as e:
            log.error(e)
            with_mtd_error = True
    params = request.args.to_dict()
    fields = params.get("fields", None)
    if fields:
        fields = fields.split(',')
    datasets = get_datasets_cruved(info_role, params, fields=fields)
    datasets_resp = {"data": datasets}
    if with_mtd_error:
        datasets_resp["with_mtd_errors"] = True
    if not datasets:
        return datasets_resp, 404
    return datasets_resp


def is_dataset_deletable(id_dataset):
    datas = DB.session.query(Synthese.id_synthese).filter(Synthese.id_dataset == id_dataset).all()
    if datas:
        return False
    return True


def is_af_deletable(id_af):
    datasets = (
        DB.session.query(TDatasets.id_dataset)
        .filter(TDatasets.id_acquisition_framework == id_af)
        .all()
    )
    if datasets:
        return False
    return True


def get_af_from_id(id_af, af_list):
    found_af = None
    for af in af_list:
        if af["id_acquisition_framework"] == id_af:
            found_af = af
            break
    return found_af


@routes.route("/dataset/<int:id_dataset>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
def get_dataset(info_role, id_dataset):
    """
    Get one dataset

    .. :quickref: Metadata;

    :param id_dataset: the id_dataset
    :param type: int
    :returns: dict<TDataset>
    """
    datasetSchema = DatasetSchema()
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]

    datasetSchema.context = {'info_role': info_role, 'user_cruved': user_cruved}

    dataset = DB.session.query(TDatasets).get(id_dataset)
    if not dataset:
        raise NotFound('Dataset "{}" does not exist'.format(id_dataset))

    return datasetSchema.jsonify(dataset)


@routes.route("/upload_canvas", methods=["POST"])
@json_resp
def upload_canvas():
    """Upload the canvas as a temporary image used while generating the pdf file
    """
    data = request.data[22:]
    filepath = str(BACKEND_DIR) + "/static/images/taxa.png"
    fm.remove_file(filepath)
    if data:
        binary_data = a2b_base64(data)
        fd = open(filepath, "wb")
        fd.write(binary_data)
        fd.close()
    return "OK"


@routes.route("/dataset/<int:ds_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="METADATA")
def delete_dataset(info_role, ds_id):
    """
    Delete a dataset

    .. :quickref: Metadata;
    """

    if not is_dataset_deletable(ds_id):
        raise GeonatureApiError(
            "La suppression du jeu de données n'est pas possible car des données y sont rattachées dans la Synthèse",
            406,
        )
    user_actor = TDatasets.get_user_datasets(info_role)
    dataset = TDatasets.query.get(ds_id)
    allowed = dataset.user_is_allowed_to(user_actor, info_role, info_role.value_filter)
    if not allowed:
        raise Forbidden(f"User {info_role.id_role} cannot delete dataset {dataset.id_dataset}")
    
    DB.session.query(TDatasets).filter(TDatasets.id_dataset == ds_id).delete()

    DB.session.commit()

    return '', 204


@routes.route("/uuid_report", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
def uuid_report(info_role):
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

    data = query.all()

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
@permissions.check_cruved_scope("R", True, module_code="METADATA")
def sensi_report(info_role):
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """
    """
    get the UUID report of a dataset

    .. :quickref: Metadata;
    """

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
            func.min(CorSensitivitySynthese.meta_update_date).label("sensiDateAttribution"),
            func.min(CorSensitivitySynthese.sensitivity_comment).label("sensiAlerte"),
            TNomenclatures.cd_nomenclature,
            TNomenclatures.label_fr
        )
        .select_from(Synthese)
        .outerjoin(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
        .outerjoin(LAreas, LAreas.id_area == CorAreaSynthese.id_area)
        .outerjoin(
            CorSensitivitySynthese,
            CorSensitivitySynthese.uuid_attached_row == Synthese.unique_id_sinp,
        )
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

    data = query.group_by(Synthese.id_synthese, TNomenclatures.cd_nomenclature, TNomenclatures.label_fr).all()

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
            "sensiAlerte": row.sensiAlerte,
            "sensible": "Oui" if row.cd_sensi != "0" else "Non",
            "sensiDateAttribution": row.sensiDateAttribution,
            "sensiNiveau": f"{row.cd_nomenclature} = {row.label_fr}" ,
        }
        for row in data
    ]
    sensi_version = DB.session.query(func.gn_commons.get_default_parameter('ref_sensi_version')).one_or_none()
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
            "sensiAlerte",
            "sensible",
            "sensiDateAttribution",
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


@routes.route("/update_sensitivity", methods=["GET"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
def update_sensitivity(info_role):
    """
    Update sensitivity of all datasets

    .. :quickref: Metadata;
    """

    params = request.args
    id_import = params.get("id_import")
    id_source = params.get("id_source")
    ds_id = params.get("ds_id")
    id_module = params.get("id_module")
    id_synthese = params.get("id_synthese")

    query = DB.session.query(Synthese.id_synthese).select_from(Synthese)

    if id_source:
        query = query.filter(Synthese.id_source == id_source)

    if id_synthese:
        query = query.filter(Synthese.id_synthese == id_synthese)

    if id_module:
        query = query.filter(Synthese.id_module == id_module)

    if ds_id:
        query = query.filter(Synthese.id_dataset == ds_id)

    if id_import:
        query = query.outerjoin(TSources, TSources.id_source == Synthese.id_source).filter(
            TSources.name_source == "Import(id={})".format(id_import)
        )

    id_syntheses = query.all()

    # id_syntheses = DB.session.query(Synthese.id_synthese).all()
    id_syntheses = [id[0] for id in id_syntheses]

    if len(id_syntheses) == 0:
        return "OK"

    if len(id_syntheses) > current_app.config["NB_MAX_DATA_SENSITIVITY_REPORT"]:

        @copy_current_request_context
        def update_sensitivity_task(id_syntheses):
            return update_sensitivity_query(id_syntheses)

        a = threading.Thread(
            name="update_sensitivity_task",
            target=update_sensitivity_task,
            kwargs={"id_syntheses": id_syntheses},
        )
        a.start()

        return "Processing"

    else:
        return update_sensitivity_query(id_syntheses)


# TODO: a écrire dans cor_sensitivy_synthese
def update_sensitivity_query(id_syntheses):

    queryStr = (
        """
        UPDATE gn_synthese.synthese SET id_nomenclature_sensitivity = gn_sensitivity.get_id_nomenclature_sensitivity(
            date_min::date,
            taxonomie.find_cdref(cd_nom),
            the_geom_local,
            ('{"STATUT_BIO": ' || id_nomenclature_bio_status::text || '}')::jsonb)
            where id_synthese in ("""
        + str(id_syntheses).strip("[]")
        + """)
        ; """
    )

    DB.engine.execute(queryStr)

    return "OK"


def datasetHandler(request, *, dataset, info_role):
    # Test des droits d'édition du dataset si modification
    if dataset.id_dataset is not None:
        user_cruved = cruved_scope_for_user_in_module(
            id_role=info_role.id_role, module_code="METADATA",
        )[0]
        dataset_cruved = dataset.get_object_cruved(info_role, user_cruved)
        #verification des droits d'édition pour le dataset
        if not dataset_cruved['U']:
            raise InsufficientRightsError(
                "User {} has no right in dataset {}".format(
                    info_role.id_role, dataset.id_dataset
                ),
                403,
            )
    else: 
        dataset.id_digitizer = info_role.id_role
    datasetSchema = DatasetSchema(unknown=EXCLUDE)
    try:
        dataset = datasetSchema.load(request.get_json(), instance=dataset)
    except ValidationError as error:
        log.exception(error)
        raise BadRequest(error.messages)

    DB.session.add(dataset)
    DB.session.commit()
    return dataset


@routes.route("/dataset", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
def create_dataset(info_role):
   """
   Post one Dataset data
   .. :quickref: Metadata;
   """

   # create new dataset
   return DatasetSchema().jsonify(
       datasetHandler(request=request, dataset=TDatasets(), info_role=info_role)
   )


@routes.route("/dataset/<int:id_dataset>", methods=["POST", "PATCH"])
@permissions.check_cruved_scope("U", True, module_code="METADATA")
def update_dataset(id_dataset, info_role):
    """
    Post one Dataset data for update dataset
    .. :quickref: Metadata;
    """

    dataset = DB.session.query(TDatasets).get(id_dataset)


    if not dataset:
        return {"message": "not found"}, 404

    return DatasetSchema().jsonify(
        datasetHandler(request=request, dataset=dataset, info_role=info_role)
    )


@routes.route("/dataset/export_pdf/<id_dataset>", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="METADATA")
def get_export_pdf_dataset(id_dataset, info_role):
    """
    Get a PDF export of one dataset
    """
    datasetSchema = DatasetSchema()
    
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]

    datasetSchema.context = {'info_role': info_role, 'user_cruved': user_cruved}

    dataset = DB.session.query(TDatasets).get(id_dataset)
    if not dataset:
        raise NotFound('Dataset "{}" does not exist'.format(id_dataset))

    dataset = json.loads((datasetSchema.dumps(dataset)).data)

    #test du droit d'export de l'utilisateur
    if not dataset.get('cruved').get('E'):
        return (
            render_template(
                "error.html",
                error="Vous n'avez pas les droits d'exporter ces informations",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )

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

    filename = "jdd_{}_{}_{}.pdf".format(
        id_dataset,
        secure_filename(dataset["dataset_shortname"]),
        dt.datetime.now().strftime("%d%m%Y_%H%M%S"),
    )

    try:
        f = open(str(BACKEND_DIR) + "/static/images/taxa.png")
        f.close()
        dataset["chart"] = True
    except IOError:
        dataset["chart"] = False

    # Appel de la methode pour generer un pdf
    pdf_file = fm.generate_pdf("dataset_template_pdf.html", dataset, filename)
    pdf_file_posix = Path(pdf_file)

    return send_from_directory(str(pdf_file_posix.parent), pdf_file_posix.name, as_attachment=True)

@routes.route("/acquisition_frameworks", methods=["GET"])
@permissions.check_cruved_scope("R", True, )
def get_acquisition_frameworks(info_role):
    """
        Get a simple list of AF without any nested relationships
        Use for AF select in form
        Get the GeoNature CRUVED
    """
    params = request.args.to_dict()
    exclude_fields = [db_rel.key for db_rel in inspect(TAcquisitionFramework).relationships]
    acquisitionFrameworkSchema = AcquisitionFrameworkSchema(
        exclude=exclude_fields
    )
    return acquisitionFrameworkSchema.jsonify(
        get_metadata_list(info_role, params, exclude_fields).all(),
        many=True
    )

@routes.route("/list/acquisition_frameworks", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
def get_acquisition_frameworks_list(info_role):
    """
    Get all AF with their datasets 
    Use in metadata module for list of AF and DS
    Add the CRUVED permission for each row (Dataset and AD)
    
    .. :quickref: Metadata;

    :param info_role: add with kwargs
    :type info_role: TRole
    :qparam list excluded_fields: fields excluded from serialization
    :qparam boolean nested: Default False - serialized relationships. If false: remove add all relationships in excluded_fields

    """
    if current_app.config["CAS_PUBLIC"]["CAS_AUTHENTIFICATION"]:
        # synchronise the CA and JDD from the MTD WS
        try:
            mtd_utils.post_jdd_from_user(
                id_user=info_role.id_role, id_organism=info_role.id_organisme
            )
        except Exception as e:
            log.error(e)
    params = request.args.to_dict()
    params["orderby"] = "acquisition_framework_name"

    if "selector" not in params:
        params["selector"] = None

    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]
    nested_serialization = params.get("nested", False)
    nested_serialization = True if nested_serialization == "true" else False
    exclude_fields = []
    if "excluded_fields" in params:
        exclude_fields = params.get("excluded_fields")
        try:
            exclude_fields = exclude_fields.split(',')
        except:
            raise BadRequest("Malformated parameter 'excluded_fields'")

    if not nested_serialization:
        # exclude all relationships from serialization if nested = false
        exclude_fields = [db_rel.key for db_rel in inspect(TAcquisitionFramework).relationships]

    acquisitionFrameworkSchema = AcquisitionFrameworkSchema(
        exclude=exclude_fields
    )
    acquisitionFrameworkSchema.context = {'info_role': info_role, 'user_cruved': user_cruved}
    return acquisitionFrameworkSchema.jsonify(
        get_metadata_list(info_role, params, exclude_fields).all(),
        many=True
    )

@routes.route("/acquisition_frameworks/export_pdf/<id_acquisition_framework>", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="METADATA")
def get_export_pdf_acquisition_frameworks(id_acquisition_framework, info_role):
    """
    Get a PDF export of one acquisition
    """

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

    if acquisition_framework:
        acquisition_framework[
            "nomenclature_territorial_level"
        ] = af.nomenclature_territorial_level.as_dict()
        acquisition_framework[
            "nomenclature_financing_type"
        ] = af.nomenclature_financing_type.as_dict()
        if acquisition_framework["acquisition_framework_start_date"]:
            acquisition_framework["acquisition_framework_start_date"] = af.acquisition_framework_start_date.strftime("%d/%m/%Y")
        if acquisition_framework["acquisition_framework_end_date"]:
            acquisition_framework["acquisition_framework_end_date"] = af.acquisition_framework_end_date.strftime("%d/%m/%Y")
        acquisition_framework["css"] = {
            "logo": "Logo_pdf.png",
            "bandeau": "Bandeau_pdf.png",
            "entite": "sinp",
        }
        acquisition_framework["pdf_title"] = current_app.config['METADATA']["AF_PDF_TITLE"]
        date = dt.datetime.now().strftime("%d/%m/%Y")
        acquisition_framework["footer"] = {
            "url": current_app.config["URL_APPLICATION"]
            + "/#/metadata/af-card/"
            + id_acquisition_framework,
            "date": date,
        }
        params = {"id_acquisition_frameworks": id_acquisition_framework}

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
        acquisition_framework['initial_closing_date'] = af.initial_closing_date.strftime('%d-%m-%Y %H:%M')
        filename = "{}_{}_{}.pdf".format(
            id_acquisition_framework,
            secure_filename(acquisition_framework["acquisition_framework_name"][0:31]),
            af.initial_closing_date.strftime("%d%m%Y_%H%M%S")
        )
        acquisition_framework["closed_title"] = current_app.config["METADATA"]["CLOSED_AF_TITLE"]

    else:
        filename = "{}_{}_{}.pdf".format(
            id_acquisition_framework,
            secure_filename(acquisition_framework["acquisition_framework_name"][0:31]),
            dt.datetime.now().strftime("%d%m%Y_%H%M%S"),
        )


    # Appel de la methode pour generer un pdf
    pdf_file = fm.generate_pdf(
        "acquisition_framework_template_pdf.html", acquisition_framework, filename
    )
    pdf_file_posix = Path(pdf_file)
    return send_from_directory(str(pdf_file_posix.parent), pdf_file_posix.name, as_attachment=True)




@routes.route("/acquisition_framework/<id_acquisition_framework>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
def get_acquisition_framework(info_role, id_acquisition_framework):
    """
    Get one AF with nomenclatures
    .. :quickref: Metadata;

    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    :returns: dict<TAcquisitionFramework>
    """
    exclude = request.args.getlist("exclude")
    try:
        acquisitionFrameworkSchema = AcquisitionFrameworkSchema(exclude=exclude)
    except ValueError as e:
        raise BadRequest(str(e))
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]

    acquisitionFrameworkSchema.context = {'info_role': info_role, 'user_cruved': user_cruved}

    acquisition_framework = DB.session.query(TAcquisitionFramework).get(id_acquisition_framework)
    if not acquisition_framework:
        raise NotFound('Acquisition framework "{}" does not exist'.format(id_acquisition_framework))
    return acquisitionFrameworkSchema.jsonify(acquisition_framework)


@routes.route("/acquisition_framework/<int:af_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="METADATA")
@json_resp
def delete_acquisition_framework(info_role, af_id):
    """
    Delete an acquisition framework
    .. :quickref: Metadata;
    """

    if not is_af_deletable(af_id):
        raise GeonatureApiError(
            "La suppression du cadre d'acquisition n'est pas possible car des jeux de données y sont rattachées",
            500,
        )

    DB.session.query(TAcquisitionFramework).filter(
        TAcquisitionFramework.id_acquisition_framework == af_id
    ).delete()

    DB.session.commit()

    return "OK"


def acquisitionFrameworkHandler(request, *, acquisition_framework, info_role):

    # Test des droits d'édition du acquisition framework si modification
    if acquisition_framework.id_acquisition_framework is not None:
        user_cruved = cruved_scope_for_user_in_module(
            id_role=info_role.id_role, module_code="METADATA",
        )[0]
        af_cruved = acquisition_framework.get_object_cruved(info_role, user_cruved)
        #verification des droits d'édition pour le acquisition framework
        if not af_cruved['U']:
            raise InsufficientRightsError(
                "User {} has no right in acquisition_framework {}".format(
                    info_role.id_role, acquisition_framework.id_acquisition_framework
                ),
                403,
            )
    else:
        acquisition_framework.id_digitizer = info_role.id_role

    acquisitionFrameworkSchema = AcquisitionFrameworkSchema(unknown=EXCLUDE)
    try:
        acquisition_framework = acquisitionFrameworkSchema.load(request.get_json(), instance=acquisition_framework)
    except ValidationError as error:
        log.exception(error)
        raise BadRequest(error.messages)

    DB.session.add(acquisition_framework)
    DB.session.commit()

    return acquisition_framework


@routes.route("/acquisition_framework", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
def create_acquisition_framework(info_role):
    """
    Post one AcquisitionFramework data
    .. :quickref: Metadata;
    """

    # create new acquisition_framework
    return AcquisitionFrameworkSchema().dump(
        acquisitionFrameworkHandler(request=request, acquisition_framework=TAcquisitionFramework(), info_role=info_role)
    )



@routes.route("/acquisition_framework/<int:id_acquisition_framework>", methods=["POST"])
@permissions.check_cruved_scope("U", True, module_code="METADATA")
def updateAcquisitionFramework(id_acquisition_framework, info_role):
    """
    Post one AcquisitionFramework data for update acquisition_framework
    .. :quickref: Metadata;
    """
    acquisition_framework = DB.session.query(TAcquisitionFramework).get(id_acquisition_framework)
    if not acquisition_framework:
        return {"message": "not found"}, 404

    return AcquisitionFrameworkSchema().dump(
        acquisitionFrameworkHandler(request=request, acquisition_framework=acquisition_framework, info_role=info_role)
    )

@routes.route("/acquisition_framework/<id_acquisition_framework>/stats", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_acquisition_framework_stats(info_role, id_acquisition_framework):
    """
    Get stats from one AF
    .. :quickref: Metadata;
    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    datasets = TDatasets.query.filter(TDatasets.id_acquisition_framework == id_acquisition_framework).all()
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
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_acquisition_framework_bbox(info_role, id_acquisition_framework):
    """
    Get BBOX from one AF
    .. :quickref: Metadata;
    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    datasets = TDatasets.query.filter(TDatasets.id_acquisition_framework == id_acquisition_framework).all()
    dataset_ids = [d.id_dataset for d in datasets]
    geojsonData = (
        DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .first()[0]
    )
    return json.loads(geojsonData) if geojsonData else None


def publish_acquisition_framework_mail(af, info_role):
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
    pdf_url = current_app.config["API_ENDPOINT"] + "/meta/acquisition_frameworks/export_pdf/" + str(af.id_acquisition_framework)

    # Mail subject
    mail_subject = "Dépôt du cadre d'acquisition " + str(af.unique_acquisition_framework_id).upper()
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
    mail_content_pdf = current_app.config['METADATA']["MAIL_CONTENT_AF_CLOSED_PDF"]
    mail_content_greetings = current_app.config['METADATA']["MAIL_CONTENT_AF_CLOSED_GREETINGS"]

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
    cur_user = DB.session.query(User).get(info_role.id_role)
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
@permissions.check_cruved_scope("E", True, module_code="METADATA")
@json_resp
def publish_acquisition_framework(info_role, af_id):
    """
    Publish an acquisition framework
    .. :quickref: Metadata;
    """

    # The AF must contain DS to be published
    datasets = TDatasets.query.filter_by(id_acquisition_framework=af_id).all()

    if not datasets:
        return (
            render_template(
                "error.html",
                error="Le cadre doit contenir des jeux de données",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )

    # After publishing an AF, we set it as closed and all its DS as inactive
    for dataset in datasets:
        dataset.active=False

    # If the AF if closed for the first time, we set it an initial_closing_date as the actual time
    af = DB.session.query(TAcquisitionFramework).get(af_id)
    af.opened=False
    if (af.initial_closing_date is None):
        af.initial_closing_date=dt.datetime.now()

    # first commit before sending mail
    DB.session.commit()
    try:
        # We send a mail to notify the AF publication
        publish_acquisition_framework_mail(af, info_role)
    except Exception:
        return {
            'error': 'error while sending mail',
            'name': 'mailError'
            }, 500

    return af.as_dict()


def get_cd_nomenclature(id_type, cd_nomenclature):
    query = "SELECT ref_nomenclatures.get_id_nomenclature(:id_type, :cd_n)"
    result = DB.engine.execute(text(query), id_type=id_type, cd_n=cd_nomenclature).first()
    value = None
    if len(result) >= 1:
        value = result[0]
    return value


@routes.route("/aquisition_framework_mtd/<uuid_af>", methods=["POST"])
@json_resp
def post_acquisition_framework_mtd(uuid=None, id_user=None, id_organism=None):
    """ 
    Post an acquisition framwork from MTD web service in XML
    .. :quickref: Metadata;
    """
    return mtd_utils.post_acquisition_framework(
        uuid=uuid, id_user=id_user, id_organism=id_organism
    )


@routes.route("/dataset_mtd/<id_user>", methods=["POST"])
@routes.route("/dataset_mtd/<id_user>/<id_organism>", methods=["POST"])
@json_resp
def post_jdd_from_user_id(id_user=None, id_organism=None):
    """ 
    Post a jdd from the mtd XML
    .. :quickref: Metadata;
    """
    return mtd_utils.post_jdd_from_user(id_user=id_user, id_organism=id_organism)


@routes.cli.command()
def mtd_sync():
    mtd_sync_af_and_ds()
