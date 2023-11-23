import datetime
import logging

from flask import (
    Blueprint,
    request,
    current_app,
    session,
    send_from_directory,
    render_template,
    jsonify,
    g,
)
from werkzeug.exceptions import BadRequest, Forbidden, NotFound, Unauthorized
from sqlalchemy import or_, func, distinct, case
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.orm import joinedload
from geojson import Feature, FeatureCollection
from shapely.geometry import asShape
from geoalchemy2.shape import from_shape, to_shape
from marshmallow import ValidationError

from geonature.core.gn_commons.models import TAdditionalFields
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_meta.models import TDatasets
from geonature.utils.env import DB, db, ROOT_DIR

from geonature.utils import filemanager
from .models import (
    TRelevesOccurrence,
    TOccurrencesOccurrence,
    CorCountingOccurrence,
    DefaultNomenclaturesValue,
)
from .repositories import (
    ReleveRepository,
    get_query_occtax_filters,
    get_query_occtax_order,
)
from .schemas import OccurrenceSchema, ReleveCruvedSchema, ReleveSchema
from .utils import as_dict_with_add_cols
from geonature.utils.errors import GeonatureApiError
from geonature.utils.utilsgeometrytools import export_as_geo_file

from geonature.core.users.models import UserRigth
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_scopes_by_action

from pypnusershub.db.models import User, Organisme
from utils_flask_sqla_geo.generic import GenericTableGeo
from utils_flask_sqla_geo.utilsgeometry import remove_third_dimension
from utils_flask_sqla.response import to_csv_resp, to_json_resp, json_resp

from occtax.commands import add_submodule_permissions

blueprint = Blueprint("pr_occtax", __name__, cli_group="occtax")
blueprint.cli.add_command(add_submodule_permissions)

log = logging.getLogger(__name__)


@blueprint.url_value_preprocessor
def set_current_module(endpoint, values):
    requested_module = values.pop("module_code", "OCCTAX")
    g.current_module = TModules.query.filter_by(module_code=requested_module).first_or_404(
        f"No module name {requested_module}"
    )


@blueprint.route("/<module_code>/releves", methods=["GET"])
@blueprint.route("/releves", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True)
@json_resp
def getReleves(scope):
    """
    Route for map list web interface

    .. :quickref: Occtax;

    """

    releve_repository = ReleveRepository(TRelevesOccurrence)
    q = releve_repository.get_filtered_query(g.current_user, scope)

    parameters = request.args

    limit = int(parameters.get("limit", 100))
    page = int(parameters.get("offset", 0))
    orderby = {
        "orderby": (parameters.get("orderby", "date_max")).lower(),
        "order": (parameters.get("order", "desc")).lower()
        if (parameters.get("order", "desc")).lower() == "asc"
        else "desc",  # asc or desc
    }

    # Filters
    q = get_query_occtax_filters(parameters, TRelevesOccurrence, q)
    query_without_limit = q
    # Order by
    q = get_query_occtax_order(orderby, TRelevesOccurrence, q)
    data = q.limit(limit).offset(page * limit).all()

    # Pour obtenir le nombre de résultat de la requete sans le LIMIT
    nb_results_without_limit = query_without_limit.count()

    featureCollection = []
    for n in data:
        releve_cruved = n.get_releve_cruved()
        feature = n.get_geofeature(
            fields=[
                "t_occurrences_occtax",
                "t_occurrences_occtax.cor_counting_occtax",
                "t_occurrences_occtax.taxref",
                "observers",
                "digitiser",
                "dataset",
                "t_occurrences_occtax.cor_counting_occtax.medias",
            ]
        )
        feature["properties"]["rights"] = releve_cruved
        featureCollection.append(feature)
    return {
        "total": nb_results_without_limit,
        "total_filtered": len(data),
        "page": page,
        "limit": limit,
        "items": FeatureCollection(featureCollection),
    }


@blueprint.route("/<module_code>/counting/<int:id_counting>", methods=["GET"])
@blueprint.route("/counting/<int:id_counting>", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True)
@json_resp
def getOneCounting(scope, id_counting):
    """
    Get one counting record, with its id_counting

    .. :quickref: Occtax;

    :param id_counting: the pr_occtax.cor_counting_occtax PK
    :type id_counting: int
    :returns: a dict representing a counting record
    :rtype: dict<CorCountingOccurrence>
    """
    ccc = CorCountingOccurrence.query.get_or_404(id_counting)
    if not ccc.occurrence.releve.has_instance_permission(scope):
        raise Forbidden

    try:
        data = (
            DB.session.query(CorCountingOccurrence, TRelevesOccurrence.id_releve_occtax)
            .join(
                TOccurrencesOccurrence,
                TOccurrencesOccurrence.id_occurrence_occtax
                == CorCountingOccurrence.id_occurrence_occtax,
            )
            .join(
                TRelevesOccurrence,
                TRelevesOccurrence.id_releve_occtax == TOccurrencesOccurrence.id_releve_occtax,
            )
            .filter(CorCountingOccurrence.id_counting_occtax == id_counting)
            .one()
        )
    except NoResultFound:
        return None
    counting = data[0].as_dict()
    counting["id_releve"] = data[1]
    return counting


@blueprint.route("/<module_code>/releve/<int:id_releve>", methods=["GET"])
@blueprint.route("/releve/<int:id_releve>", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True)
def getOneReleve(id_releve, scope):
    """
    Get one releve

    .. :quickref: Occtax;

    :param id_releve: the id releve from pr_occtax.t_releve_occtax
    :type id_releve: int
    :returns: Return a releve with its attached Cruved
    :rtype: `dict{'releve':<TRelevesOccurrence>, 'cruved': Cruved}`
    """
    releveCruvedSchema = ReleveCruvedSchema()
    releve = TRelevesOccurrence.query.get_or_404(id_releve)
    if not releve.has_instance_permission(scope):
        raise Forbidden()

    releve_cruved = {
        "releve": {
            "properties": releve,
            "id": releve.id_releve_occtax,
            "geometry": releve.geom_4326,
        },
        "cruved": releve.get_releve_cruved(),
    }

    return releveCruvedSchema.dump(releve_cruved)


@blueprint.route("/<module_code>/releve", methods=["POST"])
@blueprint.route("/releve", methods=["POST"])
@permissions.login_required
def insertOrUpdateOneReleve():
    """
    Route utilisée depuis l'appli mobile => depreciée et non utilisée par l'appli web
    Post one Occtax data (Releve + Occurrence + Counting)

    .. :quickref: Occtax; Post one Occtax data (Releve + Occurrence + Counting)

    **Request JSON object:**

    .. sourcecode:: http

        {
        "geometry":
            {"type":"Point",
            "coordinates":[0.9008789062500001,47.14489748555398]},
            "properties":
                {
                "id_releve_occtax":null,"id_dataset":1,"id_digitiser":1,"date_min":"2019-05-09","date_max":"2019-05-09","hour_min":null,"hour_max":null,"altitude_min":null,"altitude_max":null,"meta_device_entry":"web","comment":null,"id_nomenclature_obs_technique":316,"observers":[1],"observers_txt":null,"id_nomenclature_grp_typ":132,
                "t_occurrences_occtax":[{
                    "id_releve_occtax":null,"id_occurrence_occtax":null,"id_nomenclature_obs_technique":41,"id_nomenclature_bio_condition":157,"id_nomenclature_bio_status":29,"id_nomenclature_naturalness":160,"id_nomenclature_exist_proof":81,"id_nomenclature_observation_status":88,"id_nomenclature_blurring":175,"id_nomenclature_source_status":75,"determiner":null,"id_nomenclature_determination_method":445,"cd_nom":67111,"nom_cite":"Ablette =  <i> Alburnus alburnus (Linnaeus, 1758)</i> - [ES - 67111]","meta_v_taxref":null,"sample_number_proof":null,"comment":null,
                "cor_counting_occtax":[{
                    "id_counting_occtax":null,"id_nomenclature_life_stage":1,"id_nomenclature_sex":171,"id_nomenclature_obj_count":146,"id_nomenclature_type_count":94,"id_occurrence_occtax":null,"count_min":1,"count_max":1
                    }]
                }]
            }
        }

    :returns: GeoJson<TRelevesOccurrence>
    """

    data = dict(request.get_json())
    depth = data.pop("depth", None)
    occurrences_occtax = None
    if "t_occurrences_occtax" in data["properties"]:
        occurrences_occtax = data["properties"]["t_occurrences_occtax"]
        data["properties"].pop("t_occurrences_occtax")
    observersList = None
    if "observers" in data["properties"]:
        observersList = data["properties"]["observers"]
        data["properties"].pop("observers")
    if "id_module" not in data["properties"]:
        data["properties"]["id_module"] = g.current_module.id_module

    # Test et suppression des propriétés inexistantes de TRelevesOccurrence
    attliste = [k for k in data["properties"]]
    for att in attliste:
        if not getattr(TRelevesOccurrence, att, False):
            data["properties"].pop(att)

    releve = TRelevesOccurrence(**data["properties"])
    shape = asShape(data["geometry"])
    two_dimension_geom = remove_third_dimension(shape)
    releve.geom_4326 = from_shape(two_dimension_geom, srid=4326)

    if observersList is not None:
        observers = User.query.filter(User.id_role.in_(observersList)).all()
        for o in observers:
            releve.observers.append(o)

    for occ in occurrences_occtax:
        cor_counting_occtax = []
        if "cor_counting_occtax" in occ:
            cor_counting_occtax = occ["cor_counting_occtax"]
            occ.pop("cor_counting_occtax")
        # Test et suppression
        #   des propriétés inexistantes de TOccurrencesOccurrence
        attliste = [k for k in occ]
        for att in attliste:
            if not getattr(TOccurrencesOccurrence, att, False):
                occ.pop(att)
        # pop the id if None. otherwise DB.merge is not OK
        if "id_occurrence_occtax" in occ and occ["id_occurrence_occtax"] is None:
            occ.pop("id_occurrence_occtax")
        occtax = TOccurrencesOccurrence(**occ)

        for cnt in cor_counting_occtax:
            # Test et suppression
            # des propriétés inexistantes de CorCountingOccurrence
            attliste = [k for k in cnt]
            for att in attliste:
                if not getattr(CorCountingOccurrence, att, False):
                    cnt.pop(att)
            # pop the id if None. otherwise DB.merge is not OK
            if "id_counting_occtax" in cnt and cnt["id_counting_occtax"] is None:
                cnt.pop("id_counting_occtax")
            countingOccurrence = CorCountingOccurrence(**cnt)
            occtax.cor_counting_occtax.append(countingOccurrence)
        releve.t_occurrences_occtax.append(occtax)
    # if its a update
    if releve.id_releve_occtax:
        scope = get_scopes_by_action()["U"]
        if not releve.has_instance_permission(scope):
            raise Forbidden(
                f"User {g.current_user.id_role} is not allowed to update releve {releve.id_releve_occtax}"
            )
        DB.session.merge(releve)
    # if its a simple post
    else:
        scope = get_scopes_by_action()["C"]
        if not db.session.get(TDatasets, releve.id_dataset).has_instance_permission(scope):
            raise Forbidden(
                f"User {g.current_user.id_role} is not allowed to create releve in dataset."
            )
        # set id_digitiser
        releve.id_digitiser = g.current_user.id_role
        DB.session.add(releve)
    DB.session.commit()
    return releve.get_geofeature(depth=depth)


def releveHandler(request, *, releve, scope):
    releveSchema = ReleveSchema()
    # Modification de la requete geojson en releve
    json_req = request.get_json()
    json_req["properties"]["geom_4326"] = json_req["geometry"]
    # chargement des données POST et merge avec relevé initial
    try:
        releve = releveSchema.load(json_req["properties"], instance=releve)
    except ValidationError as error:
        log.exception(error.messages)
        raise BadRequest(error.messages)
    # Test des droits d'édition du relevé
    if releve.id_releve_occtax is not None:
        scope = get_scopes_by_action()["U"]
        if not releve.has_instance_permission(scope):
            raise Forbidden(
                f"User {g.current_user.id_role} can not update releve {releve.id_releve_occtax}"
            )
    # if creation
    else:
        # Check if user can add a releve in the current dataset
        dataset = db.session.get(TDatasets, releve.id_dataset)
        if not dataset.has_instance_permission(scope):
            raise Forbidden(
                f"User {g.current_user.id_role} has no right in dataset {releve.id_dataset}"
            )
        # set id_digitiser
        releve.id_digitiser = g.current_user.id_role
    DB.session.add(releve)
    DB.session.commit()
    return releve


@blueprint.route("/<module_code>/only/releve", methods=["POST"])
@blueprint.route("/only/releve", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True)
def createReleve(scope):
    """
    Post one Occtax data (Releve + Occurrence + Counting)

    .. :quickref: Occtax; Post one Occtax data (Releve + Occurrence + Counting)

    **Request JSON object:**

    .. sourcecode:: http

        {
        "geometry":
            {"type":"Point",
            "coordinates":[0.9008789062500001,47.14489748555398]},
            "properties":
                {
                "id_releve_occtax":null,"id_dataset":1,"id_digitiser":1,"date_min":"2019-05-09","date_max":"2019-05-09","hour_min":null,"hour_max":null,"altitude_min":null,"altitude_max":null,"meta_device_entry":"web","comment":null,"id_nomenclature_obs_technique":316,"observers":[1],"observers_txt":null,"id_nomenclature_grp_typ":132,
                "t_occurrences_occtax":[{
                    "id_releve_occtax":null,"id_occurrence_occtax":null,"id_nomenclature_obs_technique":41,"id_nomenclature_bio_condition":157,"id_nomenclature_bio_status":29,"id_nomenclature_naturalness":160,"id_nomenclature_exist_proof":81,"id_nomenclature_observation_status":88,"id_nomenclature_blurring":175,"id_nomenclature_source_status":75,"determiner":null,"id_nomenclature_determination_method":445,"cd_nom":67111,"nom_cite":"Ablette =  <i> Alburnus alburnus (Linnaeus, 1758)</i> - [ES - 67111]","meta_v_taxref":null,"sample_number_proof":null,"comment":null,
                "cor_counting_occtax":[{
                    "id_counting_occtax":null,"id_nomenclature_life_stage":1,"id_nomenclature_sex":171,"id_nomenclature_obj_count":146,"id_nomenclature_type_count":94,"id_occurrence_occtax":null,"count_min":1,"count_max":1
                    }]
                }]
            }
        }

    :returns: GeoJson<TRelevesOccurrence>
    """
    # nouveau releve vide
    releve = TRelevesOccurrence()
    releve = ReleveSchema().dump(releveHandler(request=request, releve=releve, scope=scope))

    return {
        "geometry": releve.pop("geom_4326", None),
        "properties": releve,
        "id": releve["id_releve_occtax"],
    }


@blueprint.route("/<module_code>/only/releve/<int:id_releve>", methods=["POST"])
@blueprint.route("/only/releve/<int:id_releve>", methods=["POST"])
@permissions.check_cruved_scope("U", get_scope=True)
def updateReleve(id_releve, scope):
    """
    Post one Occurrence data (Occurrence + Counting) for add to Releve

    """
    # get releve by id_releve
    releve = DB.session.query(TRelevesOccurrence).get(id_releve)

    if not releve:
        return {"message": "not found"}, 404

    releve = ReleveSchema().dump(releveHandler(request=request, releve=releve, scope=scope))

    return {
        "geometry": releve.pop("geom_4326", None),
        "properties": releve,
        "id": releve["id_releve_occtax"],
    }


def occurrenceHandler(request, *, occurrence, scope):
    releve = db.get_or_404(TRelevesOccurrence, occurrence.id_releve_occtax)
    if not releve.has_instance_permission(scope):
        raise Forbidden()

    occurrenceSchema = OccurrenceSchema()
    try:
        occurrence = occurrenceSchema.load(request.get_json(), instance=occurrence)
    except ValidationError as error:
        log.exception(error.messages)
        raise BadRequest(error.messages)
    DB.session.add(occurrence)
    DB.session.commit()

    return occurrence


@blueprint.route("/<module_code>/releve/<int:id_releve>/occurrence", methods=["POST"])
@blueprint.route("/releve/<int:id_releve>/occurrence", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True)
def createOccurrence(id_releve, scope):
    """
    Post one Occurrence data (Occurrence + Counting) for add to Releve

    """
    # get releve by id_releve
    occurrence = TOccurrencesOccurrence()
    occurrence.id_releve_occtax = id_releve
    return OccurrenceSchema().dump(
        occurrenceHandler(request=request, occurrence=occurrence, scope=scope)
    )


@blueprint.route("/<module_code>/occurrence/<int:id_occurrence>", methods=["POST"])
@blueprint.route("/occurrence/<int:id_occurrence>", methods=["POST"])
@permissions.check_cruved_scope("U", get_scope=True)
def updateOccurrence(id_occurrence, scope):
    """
    Post one Occurrence data (Occurrence + Counting) for add to Releve

    """
    occurrence = db.get_or_404(TOccurrencesOccurrence, id_occurrence)

    return OccurrenceSchema().dump(
        occurrenceHandler(request=request, occurrence=occurrence, scope=scope)
    )


@blueprint.route("/<module_code>/releve/<int:id_releve>", methods=["DELETE"])
@blueprint.route("/releve/<int:id_releve>", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True)
def deleteOneReleve(id_releve, scope):
    """Delete one releve and its associated occurrences and counting

    .. :quickref: Occtax;

    :params int id_releve: ID of the releve to delete

    """
    releve = db.get_or_404(TRelevesOccurrence, id_releve)
    if not releve.has_instance_permission(scope):
        raise Forbidden()
    db.session.delete(releve)
    db.session.commit()
    return jsonify({"message": "delete with success"})


@blueprint.route("/<module_code>/occurrence/<int:id_occ>", methods=["DELETE"])
@blueprint.route("/occurrence/<int:id_occ>", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True)
def deleteOneOccurence(id_occ, scope):
    """Delete one occurrence and associated counting

    .. :quickref: Occtax;

    :params int id_occ: ID of the occurrence to delete

    """
    occ = db.get_or_404(TOccurrencesOccurrence, id_occ)

    if not occ.releve.has_instance_permission(scope):
        raise Forbidden()

    DB.session.delete(occ)
    DB.session.commit()

    return "", 204


@blueprint.route("/<module_code>/releve/occurrence_counting/<int:id_count>", methods=["DELETE"])
@blueprint.route("/releve/occurrence_counting/<int:id_count>", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True)
def deleteOneOccurenceCounting(scope, id_count):
    """Delete one counting

    .. :quickref: Occtax;

    :params int id_count: ID of the counting to delete

    """
    ccc = db.get_or_404(CorCountingOccurrence, id_count)
    if not ccc.occurence.releve.has_instance_permission(scope):
        raise Forbidden
    DB.session.delete(ccc)
    DB.session.commit()
    return "", 204


@blueprint.route("/<module_code>/defaultNomenclatures", methods=["GET"])
@blueprint.route("/defaultNomenclatures", methods=["GET"])
@permissions.login_required
def getDefaultNomenclatures():
    """Get default nomenclatures define in occtax module

    .. :quickref: Occtax;

    :returns: dict: {'MODULE_CODE': 'ID_NOMENCLATURE'}

    """
    organism = request.args.get("organism")
    regne = request.args.get("regne", "0")
    group2_inpn = request.args.get("group2_inpn", "0")
    types = request.args.getlist("id_type")

    query = db.select(
        distinct(DefaultNomenclaturesValue.mnemonique_type),
        func.pr_occtax.get_default_nomenclature_value(
            DefaultNomenclaturesValue.mnemonique_type, organism, regne, group2_inpn
        ),
    )
    if len(types) > 0:
        query = query.where(DefaultNomenclaturesValue.mnemonique_type.in_(tuple(types)))
    data = db.session.execute(query).all()
    if not data:
        raise NotFound
    return jsonify(dict(data))


@blueprint.route("/<module_code>/export", methods=["GET"])
@blueprint.route("/export", methods=["GET"])
@permissions.check_cruved_scope("E", get_scope=True)
def export(scope):
    """Export data from pr_occtax.v_export_occtax view (parameter)

    .. :quickref: Occtax; Export data from pr_occtax.v_export_occtax

    :query str format: format of the export ('csv', 'geojson', 'shapefile', 'gpkg')

    """
    export_view_name = blueprint.config["export_view_name"]
    export_geom_column = blueprint.config["export_geom_columns_name"]
    export_columns = blueprint.config["export_columns"]
    export_srid = blueprint.config["export_srid"]
    export_format = request.args["format"] if "format" in request.args else "geojson"
    export_col_name_additional_data = blueprint.config["export_col_name_additional_data"]

    export_view = GenericTableGeo(
        tableName=export_view_name,
        schemaName="pr_occtax",
        engine=DB.engine,
        geometry_field=export_geom_column,
        srid=export_srid,
    )
    columns = (
        export_columns
        if len(export_columns) > 0
        else [db_col.key for db_col in export_view.db_cols]
    )

    releve_repository = ReleveRepository(export_view)
    q = releve_repository.get_filtered_query(g.current_user, scope, from_generic_table=True)
    q = get_query_occtax_filters(
        request.args,
        export_view,
        q,
        from_generic_table=True,
        obs_txt_column=blueprint.config["export_observer_txt_column"],
    )

    if current_app.config["OCCTAX"]["ADD_MEDIA_IN_EXPORT"]:
        q, columns = releve_repository.add_media_in_export(q, columns)
    data = q.all()

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    # Ajout des colonnes additionnels
    additional_col_names = []
    query_add_fields = (
        DB.session.query(TAdditionalFields)
        .filter(TAdditionalFields.modules.any(module_code=g.current_module.module_code))
        .filter(TAdditionalFields.exportable == True)
    )
    global_add_fields = query_add_fields.filter(~TAdditionalFields.datasets.any()).all()
    if "id_dataset" in request.args:
        dataset_add_fields = query_add_fields.filter(
            TAdditionalFields.datasets.any(id_dataset=request.args["id_dataset"])
        ).all()
        global_add_fields = [*global_add_fields, *dataset_add_fields]

    additional_col_names = [field.field_name for field in global_add_fields]
    if export_format == "csv":
        # set additional data col at the end (remove it and inset it ...)
        if export_col_name_additional_data in columns:
            columns.remove(export_col_name_additional_data)
        columns = columns + additional_col_names
        columns.append(export_col_name_additional_data)
        if additional_col_names:
            serialize_result = [
                as_dict_with_add_cols(
                    export_view, row, export_col_name_additional_data, additional_col_names
                )
                for row in data
            ]
        else:
            serialize_result = [export_view.as_dict(row) for row in data]
        return to_csv_resp(file_name, serialize_result, columns, ";")
    elif export_format == "geojson":
        if additional_col_names:
            features = []
            for row in data:
                properties = as_dict_with_add_cols(
                    export_view, row, export_col_name_additional_data, additional_col_names
                )
                feature = Feature(
                    properties=properties, geometry=to_shape(getattr(row, export_geom_column))
                )
                features.append(feature)
            serialize_result = FeatureCollection(features)

        else:
            serialize_result = FeatureCollection(
                [export_view.as_geofeature(d, fields=export_columns) for d in data]
            )
        return to_json_resp(
            serialize_result, as_file=True, filename=file_name, indent=4, extension="geojson"
        )
    else:
        db_cols = [db_col for db_col in export_view.db_cols if db_col.key in export_columns]
        dir_name, file_name = export_as_geo_file(
            export_format=export_format,
            export_view=export_view,
            db_cols=db_cols,
            geojson_col=None,
            data=data,
            file_name=file_name,
        )
        db_cols = [db_col for db_col in export_view.db_cols if db_col.key in export_columns]

        return send_from_directory(dir_name, file_name, as_attachment=True)
