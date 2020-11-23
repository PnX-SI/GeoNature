import logging
import json

from sqlalchemy import or_, String, Date
from sqlalchemy.orm import joinedload
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql.functions import func
from sqlalchemy.sql.expression import cast

from flask import request, current_app
import requests

from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla.generic import test_type_and_generate_query, testDataType

from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module


from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
    TDatasetDetails,
)
from geonature.core.gn_synthese.models import Synthese
from geonature.core.users.models import BibOrganismes

log = logging.getLogger()


def cruved_filter(q, model, info_role):
    if info_role.value_filter in ("1", "2"):
        or_filter = [
            getattr(model, "id_digitizer") == info_role.id_role,
            CorDatasetActor.id_role == info_role.id_role,
        ]
        if not CorDatasetActor in [mapper.class_ for mapper in query._join_entities]:
            q = q.outerjoin(
                CorDatasetActor, CorDatasetActor.id_dataset == getattr(model, "id_dataset")
            )

        # if organism is None => do not filter on id_organism even if level = 2
        if info_role.value_filter == "2" and info_role.id_organisme is not None:
            or_filter.append(CorDatasetActor.id_organism == info_role.id_organisme)
        q = q.filter(or_(*or_filter))
    return q


def get_datasets_cruved(info_role, params=dict(), as_model=False, recursif=False, lazyloaded=[]):
    """
        Return the datasets filtered with cruved

        Params:
            params (dict): parameter to add where clause
            as_model (boolean): default false, if truereturn an array of model
                                instead of an array of dict
            recursif (boolean): serialize recursively (availabke only if as_model = False)
            lazyloaded (iterable): list of relationships property to lazyload
    """
    q = DB.session.query(TDatasets).distinct()
    if lazyloaded:
        for rel in lazyloaded:
            q = q.options(joinedload(rel))

    # filter with modules
    if "module_code" in params:
        q = q.filter(TDatasets.modules.any(module_code=params["module_code"]))

    # filters with cruved
    if info_role.value_filter in ("1", "2"):
        q = cruved_filter(q, TDatasets, info_role)
    # filters query string
    if "active" in request.args:
        q = q.filter(TDatasets.active == bool(request.args["active"]))
        params.pop("active")
    if "id_acquisition_framework" in params:
        if type(request.args["id_acquisition_framework"]) is list:
            q = q.filter(
                TDatasets.id_acquisition_framework.in_(
                    [int(id_af) for id_af in params["id_acquisition_framework"]]
                )
            )
        else:
            q = q.filter(
                TDatasets.id_acquisition_framework == int(request.args["id_acquisition_framework"])
            )

        params.pop("id_acquisition_framework")
    table_columns = TDatasets.__table__.columns
    # Generic Filters
    for param in params:
        if param in table_columns:
            col = getattr(table_columns, param)
            testT = testDataType(params[param], col.type, param)
            if testT:
                raise GeonatureApiError(message=testT)
            q = q.filter(col == params[param])
    if "orderby" in params:
        try:
            orderCol = getattr(TDatasets.__table__.columns, params["orderby"])
            q = q.order_by(orderCol)
        except AttributeError:
            log.error("the attribute to order on does not exist")
    data = q.all()
    if as_model:
        return data
    return [d.as_dict(recursif) for d in data]


def filtered_ds_query(info_role, args):

    num = request.args.get("num")
    uuid = args.get("uuid")
    name = request.args.get("name")
    date = request.args.get("date")
    organisme = request.args.get("organism")
    role = request.args.get("role")

    query = (
        DB.session.query(TDatasets)
        .outerjoin(CorDatasetActor, CorDatasetActor.id_dataset == TDatasets.id_dataset)
        .outerjoin(BibOrganismes, BibOrganismes.id_organisme == CorDatasetActor.id_organism)
        .options(joinedload("creator"))
        .options(joinedload("cor_dataset_actor"))
    )

    query = cruved_filter(query, TDatasets, info_role)
    if args.get("selector") == "af":
        return query

    if num is not None:
        query = query.filter(TDatasets.id_dataset == num)
    if uuid is not None:
        query = query.filter(cast(TDatasets.unique_dataset_id, String).ilike(f"%{uuid}%"))
    if name is not None:
        query = query.filter(TDatasets.dataset_name.ilike(f"%{name}%"))
    if date is not None:
        query = query.filter(cast(TDatasets.meta_create_date, Date) == date)
    if organisme is not None:
        query = query.filter(BibOrganismes.id_organisme == organisme)
    if role is not None:
        query = query.filter(CorDatasetActor.id_role == role)
    return query


def filtered_af_query(args):

    if args.get("selector") == "ds":
        return DB.session.query(TAcquisitionFramework)

    num = args.get("num")
    uuid = args.get("uuid")
    name = args.get("name")
    date = args.get("date")
    organisme = args.get("organism")
    role = args.get("role")

    query = (
        DB.session.query(TAcquisitionFramework)
        .join(
            CorAcquisitionFrameworkActor,
            TAcquisitionFramework.id_acquisition_framework
            == CorAcquisitionFrameworkActor.id_acquisition_framework,
        )
        .outerjoin(
            BibOrganismes, CorAcquisitionFrameworkActor.id_organism == BibOrganismes.id_organisme
        )
        .options(joinedload("cor_af_actor"))
        .options(joinedload("creator"))
    )

    if num is not None:
        query = query.filter(TAcquisitionFramework.id_acquisition_framework == num)
    if uuid is not None:
        query = query.filter(
            cast(TAcquisitionFramework.unique_acquisition_framework_id, String).ilike(f"%{uuid}%")
        )
    if name is not None:
        query = query.filter(TAcquisitionFramework.acquisition_framework_name.ilike("%{name}%"))
    if date is not None:
        query = query.filter(
            cast(TAcquisitionFramework.acquisition_framework_start_date, Date) == f"%{date}%"
        )
    if organisme is not None:
        query = query.filter(BibOrganismes.id_organisme == organisme)
    if role is not None:
        query = query.filter(CorAcquisitionFrameworkActor.id_role == role)

    return query


def get_dataset_details_dict(id_dataset, session_role):
    """
    Return a dataset from TDatasetDetails model (with all relationships)
    return also the number of taxon and observation of the dataset
    Use for get_one datasert
    """
    q = DB.session.query(TDatasetDetails)
    q = cruved_filter(q, TDatasetDetails, session_role)
    try:
        data = q.filter(TDatasetDetails.id_dataset == id_dataset).one()
    except NoResultFound:
        return None

    dataset = data.as_dict(True)

    dataset["taxa_count"] = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset == id_dataset)
        .distinct()
        .count()
    )
    dataset["observation_count"] = (
        DB.session.query(Synthese.cd_nom).filter(Synthese.id_dataset == id_dataset).count()
    )
    geojsonData = (
        DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .filter(Synthese.id_dataset == id_dataset)
        .first()[0]
    )
    if geojsonData:
        dataset["bbox"] = json.loads(geojsonData)
    imports = requests.get(
        current_app.config["API_ENDPOINT"] + "/import/by_dataset/" + id_dataset,
        headers={"Cookie": request.headers.get("Cookie")},  # recuperation du token
    )
    imports = json.loads(imports.content.decode("utf8").replace("'", '"'))
    if imports:
        dataset["imports"] = imports

    user_cruved = cruved_scope_for_user_in_module(
        id_role=session_role.id_role, module_code="METADATA",
    )[0]
    cruved = data.get_object_cruved(
        user_cruved=user_cruved,
        id_object=data.id_dataset,
        ids_object_user=TDatasets.get_user_datasets(session_role, only_user=True),
        ids_object_organism=TDatasets.get_user_datasets(session_role, only_user=False),
    )
    dataset["cruved"] = cruved
    return dataset


def get_af_cruved(info_role, params=None, as_model=False):
    """
        Return the datasets filtered with cruved
        Params:
            info_role (VUsersPermissions):  user object with cruved level (value filter)
            params (dict): get parameters for filter
    """
    q = DB.session.query(TAcquisitionFramework).distinct()
    # filter with cruved

    if info_role.value_filter in ("1", "2"):
        or_filter = [
            TAcquisitionFramework.id_digitizer == info_role.id_role,
            CorAcquisitionFrameworkActor.id_role == info_role.id_role,
        ]
        q = q.join(
            CorAcquisitionFrameworkActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        )

        if info_role.value_filter == "2" and info_role.id_organisme is not None:
            or_filter.append(CorAcquisitionFrameworkActor.id_organism == info_role.id_organisme)
        q = q.filter(or_(*or_filter))

    if params:
        params = params.to_dict()
        if "orderby" in params:
            try:
                order_col = getattr(TAcquisitionFramework.__table__.columns, params.pop("orderby"))
                q = q.order_by(order_col)
            except AttributeError:
                log.error("the attribute to order on does not exist")

        # Generic Filters
        for key, value in params.items():
            q = test_type_and_generate_query(key, value, TAcquisitionFramework, q)
    data = q.all()
    if as_model:
        return data
    return [d.as_dict(True) for d in data]
