import datetime
import logging

from flask import (
    Blueprint,
    request,
    current_app,
    session,
    send_from_directory,
    redirect,
    make_response,
    Response,
    render_template,
)
from sqlalchemy import or_, func, distinct
from sqlalchemy.orm.exc import NoResultFound
from geojson import FeatureCollection
from shapely.geometry import asShape
from geoalchemy2.shape import from_shape


from geonature.utils.env import DB, ROOT_DIR
from pypnusershub.db.models import User
from pypnusershub.db.tools import InsufficientRightsError

from geonature.utils import filemanager
from .models import (
    TRelevesOccurrence,
    TOccurrencesOccurrence,
    CorCountingOccurrence,
    VReleveOccurrence,
    VReleveList,
    corRoleRelevesOccurrence,
    DefaultNomenclaturesValue,
)
from .repositories import ReleveRepository, get_query_occtax_filters
from .utils import get_nomenclature_filters
from geonature.utils.utilssqlalchemy import (
    json_resp,
    testDataType,
    csv_resp,
    GenericTable,
    to_json_resp,
    to_csv_resp,
)
from geonature.utils.errors import GeonatureApiError
from geonature.core.users.models import UserRigth
from geonature.core.gn_meta.models import TDatasets, CorDatasetActor
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved

blueprint = Blueprint("pr_occtax", __name__)
log = logging.getLogger(__name__)


@blueprint.route("/releves", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="OCCTAX")
@json_resp
def getReleves(info_role):
    releve_repository = ReleveRepository(TRelevesOccurrence)
    data = releve_repository.get_all(info_role)
    return FeatureCollection([n.get_geofeature() for n in data])


@blueprint.route("/occurrences", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="OCCTAX")
@json_resp
def getOccurrences():
    q = DB.session.query(TOccurrencesOccurrence)
    data = q.all()
    return [n.as_dict() for n in data]


@blueprint.route("/counting/<int:id_counting>", methods=["GET"])
@json_resp
def getOneCounting(id_counting):
    """
    Get a counting record, with its id_releve

    Parameters:
        id_counting(integer): the pr_occtax.cor_counting_occtax PK

    Returns:
        json: a json representing a counting record
    """
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
                TRelevesOccurrence.id_releve_occtax
                == TOccurrencesOccurrence.id_releve_occtax,
            )
            .filter(CorCountingOccurrence.id_counting_occtax == id_counting)
            .one()
        )
    except NoResultFound:
        return None
    counting = data[0].as_dict()
    counting["id_releve"] = data[1]
    return counting


@blueprint.route("/releve/<int:id_releve>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="OCCTAX")
@json_resp
def getOneReleve(id_releve, info_role):
    """
    Get one releve
    """
    releve_repository = ReleveRepository(TRelevesOccurrence)
    releve_model, releve_geojson = releve_repository.get_one(id_releve, info_role)
    user_cruved = get_or_fetch_user_cruved(
        session=session, id_role=info_role.id_role, module_code="OCCTAX"
    )
    releve_cruved = releve_model.get_releve_cruved(info_role, user_cruved)
    return {"releve": releve_geojson, "cruved": releve_cruved}


@blueprint.route("/vreleveocctax", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="OCCTAX")
@json_resp
def getViewReleveOccurrence(info_role):
    releve_repository = ReleveRepository(VReleveOccurrence)
    q = releve_repository.get_filtered_query(info_role)

    parameters = request.args

    nbResultsWithoutFilter = DB.session.query(VReleveOccurrence).count()

    limit = int(parameters.get("limit")) if parameters.get("limit") else 100
    page = int(parameters.get("offset")) if parameters.get("offset") else 0

    # Filters
    for param in parameters:
        if param in VReleveOccurrence.__table__.columns:
            col = getattr(VReleveOccurrence.__table__.columns, param)
            q = q.filter(col == parameters[param])

    # Order by
    if "orderby" in parameters:
        if parameters.get("orderby") in VReleveOccurrence.__table__.columns:
            orderCol = getattr(
                VReleveOccurrence.__table__.columns, parameters["orderby"]
            )

        if "order" in parameters:
            if parameters["order"] == "desc":
                orderCol = orderCol.desc()

        q = q.order_by(orderCol)

    try:
        data = q.limit(limit).offset(page * limit).all()
    except Exception as e:
        DB.session.rollback()
        raise

    user = info_role
    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        module_code="OCCTAX",
        id_application_parent=current_app.config["ID_APPLICATION_GEONATURE"],
    )
    featureCollection = []

    for n in data:
        releve_cruved = n.get_releve_cruved(user, user_cruved)
        feature = n.get_geofeature()
        feature["properties"]["rights"] = releve_cruved
        featureCollection.append(feature)

    if data:
        return {
            "items": FeatureCollection(featureCollection),
            "total": nbResultsWithoutFilter,
        }
    return {"message": "not found"}, 404


@blueprint.route("/vreleve", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="OCCTAX")
@json_resp
def getViewReleveList(info_role):
    """
        Retour la liste résumé des relevés avec occurrences


        Parameters
        ----------
        limit: int
            Nombre max de résulats à retourner
        offset: int
            Numéro de la page à retourner
        cd_nom: int
            Filtrer les relevés avec des occurrences avec le taxon x
        observers: int
        date_up: date
            Date minimum des relevés à retourner
        date_low: date
            Date maximum des relevés à retourner
        date_eq: date
            Date exacte des relevés à retourner
        orderby: char
            Nom du champ sur lequel baser l'ordonnancement
        order: char (asc|desc)
            Sens de l'ordonnancement
        organism: int
            id de l'organisme
        [NomChampTableVReleveList]
            Filtre sur le champ NomChampTableVReleveList

        Returns
        -------
        json
        {
            'total': Nombre total de résultat,
            'total_filtered': Nombre total de résultat après filtration ,
            'page': Numéro de la page retournée,
            'limit': Nombre de résultats,
            'items': données au format GeoJson
        }


    """
    releveRepository = ReleveRepository(VReleveList)
    q = releveRepository.get_filtered_query(info_role)

    params = request.args.to_dict()

    nbResultsWithoutFilter = VReleveList.query.count()

    limit = int(params.get("limit")) if params.get("limit") else 100
    page = int(params.get("offset")) if params.get("offset") else 0

    q = get_query_occtax_filters(request.args, VReleveList, q)

    # order by date
    q = q.order_by(VReleveList.date_min.desc())

    nbResults = q.count()

    data = q.limit(limit).offset(page * limit).all()

    user = info_role
    user_cruved = get_or_fetch_user_cruved(
        session=session, id_role=info_role.id_role, module_code="OCCTAX"
    )
    featureCollection = []
    for n in data:
        releve_cruved = n.get_releve_cruved(user, user_cruved)
        feature = n.get_geofeature()
        feature["properties"]["rights"] = releve_cruved
        featureCollection.append(feature)
    return {
        "total": nbResultsWithoutFilter,
        "total_filtered": nbResults,
        "page": page,
        "limit": limit,
        "items": FeatureCollection(featureCollection),
    }


# current_app.config["SQLALCHEMY_ECHO"] = True


@blueprint.route("/releve", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="OCCTAX")
@json_resp
def insertOrUpdateOneReleve(info_role):
    releveRepository = ReleveRepository(TRelevesOccurrence)
    data = dict(request.get_json())
    occurrences_occtax = None
    if "t_occurrences_occtax" in data["properties"]:
        occurrences_occtax = data["properties"]["t_occurrences_occtax"]
        data["properties"].pop("t_occurrences_occtax")
    observersList = None
    if "observers" in data["properties"]:
        observersList = data["properties"]["observers"]
        data["properties"].pop("observers")

    # Test et suppression des propriétés inexistantes de TRelevesOccurrence
    attliste = [k for k in data["properties"]]
    for att in attliste:
        if not getattr(TRelevesOccurrence, att, False):
            data["properties"].pop(att)

    releve = TRelevesOccurrence(**data["properties"])

    shape = asShape(data["geometry"])
    releve.geom_4326 = from_shape(shape, srid=4326)

    if observersList is not None:
        observers = DB.session.query(User).filter(User.id_role.in_(observersList)).all()
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
        # get update right of the user
        user_cruved = get_or_fetch_user_cruved(
            session=session, id_role=info_role.id_role, module_code="OCCTAX"
        )
        update_code_filter = user_cruved["U"]
        # info_role.code_action = update_data_scope
        user = UserRigth(
            id_role=info_role.id_role,
            value_filter=update_code_filter,
            code_action="U",
            id_organisme=info_role.id_organisme,
        )
        releve = releveRepository.update(releve, user, shape)
    # if its a simple post
    else:
        # set id_digitiser
        releve.id_digitiser = info_role.id_role
        if info_role.value_filter in ("0", "1", "2"):
            # Check if user can add a releve in the current dataset
            allowed = releve.user_is_in_dataset_actor(info_role)
            if not allowed:
                raise InsufficientRightsError(
                    "User {} has no right in dataset {}".format(
                        info_role.id_role, releve.id_dataset
                    ),
                    403,
                )
        DB.session.add(releve)
    DB.session.commit()
    DB.session.flush()

    return releve.get_geofeature()


@blueprint.route("/releve/<int:id_releve>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="OCCTAX")
@json_resp
def deleteOneReleve(id_releve, info_role):
    """Suppression d'une données d'un relevé et des occurences associés
      c-a-d un enregistrement de la table t_releves_occtax

    Parameters
    ----------
        id_releve: int
            identifiant de l'enregistrement à supprimer

    """
    releveRepository = ReleveRepository(TRelevesOccurrence)
    releveRepository.delete(id_releve, info_role)

    return {"message": "delete with success"}, 200


@blueprint.route("/releve/occurrence/<int:id_occ>", methods=["DELETE"])
@permissions.check_cruved_scope("D", module_code="OCCTAX")
@json_resp
def deleteOneOccurence(id_occ):
    """Suppression d'une données d'occurrence et des dénombrements associés
      c-a-d un enregistrement de la table t_occurrences_occtax

    Parameters
    ----------
        id_occ: int
            identifiant de l'enregistrement à supprimer

    """
    q = DB.session.query(TOccurrencesOccurrence)

    try:
        data = q.get(id_occ)
    except Exception as e:
        DB.session.rollback()
        raise

    if not data:
        return {"message": "not found"}, 404

    try:
        DB.session.delete(data)
        DB.session.commit()
    except Exception as e:
        DB.session.rollback()
        raise

    return {"message": "delete with success"}


@blueprint.route("/releve/occurrence_counting/<int:id_count>", methods=["DELETE"])
@permissions.check_cruved_scope("R", module_code="OCCTAX")
@json_resp
def deleteOneOccurenceCounting(id_count):
    """Suppression d'une données de dénombrement
      c-a-d un enregistrement de la table cor_counting_occtax


    Parameters
    ----------
        id_count: int
            identifiant de l'enregistrement à supprimer

    """
    q = DB.session.query(CorCountingOccurrence)

    try:
        data = q.get(id_count)
    except Exception as e:
        DB.session.rollback()
        raise

    if not data:
        return {"message": "not found"}, 404

    try:
        DB.session.delete(data)
        DB.session.commit()
    except Exception as e:
        DB.session.rollback()
        raise

    return {"message": "delete with success"}


@blueprint.route("/defaultNomenclatures", methods=["GET"])
@json_resp
def getDefaultNomenclatures():
    params = request.args
    group2_inpn = "0"
    regne = "0"
    organism = 0
    if "group2_inpn" in params:
        group2_inpn = params["group2_inpn"]
    if "regne" in params:
        regne = params["regne"]
    if "organism" in params:
        organism = params["organism"]
    types = request.args.getlist("id_type")

    q = DB.session.query(
        distinct(DefaultNomenclaturesValue.mnemonique_type),
        func.pr_occtax.get_default_nomenclature_value(
            DefaultNomenclaturesValue.mnemonique_type, organism, regne, group2_inpn
        ),
    )
    if len(types) > 0:
        q = q.filter(DefaultNomenclaturesValue.mnemonique_type.in_(tuple(types)))
    try:
        data = q.all()
    except Exception:
        DB.session.rollback()
        raise
    if not data:
        return {"message": "not found"}, 404
    return {d[0]: d[1] for d in data}


@blueprint.route("/export", methods=["GET"])
@permissions.check_cruved_scope(
    "E",
    True,
    module_code="OCCTAX",
    redirect_on_expiration=current_app.config.get("URL_APPLICATION"),
)
def export(info_role):
    export_view_name = blueprint.config["export_view_name"]
    export_geom_column = blueprint.config["export_geom_columns_name"]
    export_id_column_name = blueprint.config["export_id_column_name"]
    export_columns = blueprint.config["export_columns"]
    export_srid = blueprint.config["export_srid"]

    export_view = GenericTable(
        export_view_name, "pr_occtax", export_geom_column, export_srid
    )
    releve_repository = ReleveRepository(export_view)
    q = releve_repository.get_filtered_query(info_role, from_generic_table=True)
    q = get_query_occtax_filters(request.args, export_view, q, from_generic_table=True)

    data = q.all()

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    file_name = filemanager.removeDisallowedFilenameChars(file_name)

    export_format = request.args["format"] if "format" in request.args else "geojson"
    if export_format == "csv":
        columns = (
            export_columns
            if len(export_columns) > 0
            else [db_col.key for db_col in export_view.db_cols]
        )
        return to_csv_resp(
            file_name, [export_view.as_dict(d) for d in data], columns, ";"
        )
    elif export_format == "geojson":
        results = FeatureCollection(
            [export_view.as_geofeature(d, columns=export_columns) for d in data]
        )
        return to_json_resp(
            results, as_file=True, filename=file_name, indent=4, extension="geojson"
        )
    else:
        try:
            filemanager.delete_recursively(
                str(ROOT_DIR / "backend/static/shapefiles"), excluded_files=[".gitkeep"]
            )
            db_cols = [
                db_col for db_col in export_view.db_cols if db_col.key in export_columns
            ]
            dir_path = str(ROOT_DIR / "backend/static/shapefiles")
            export_view.as_shape(
                db_cols=db_cols, data=data, dir_path=dir_path, file_name=file_name
            )

            return send_from_directory(dir_path, file_name + ".zip", as_attachment=True)

        except GeonatureApiError as e:
            message = str(e)

        return render_template(
            "error.html",
            error=message,
            redirect=current_app.config["URL_APPLICATION"] + "/#/occtax",
        )

