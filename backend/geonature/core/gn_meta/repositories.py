import logging
import json

from sqlalchemy import or_
from sqlalchemy.orm import joinedload
from sqlalchemy.sql.functions import func

from flask import request

from geonature.utils.env import DB
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla.generic import test_type_and_generate_query, testDataType

from geonature.utils.errors import GeonatureApiError

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
    TDatasetDetails,
)
from geonature.core.gn_synthese.models import Synthese

log = logging.getLogger()


def get_datasets_cruved(info_role, params=dict(), as_model=False):
    """
        Return the datasets filtered with cruved

        Params:
            params (dict): parameter to add where clause
            as_model (boolean): default false, if truereturn an array of model
                                instead of an array of dict
    """
    q = DB.session.query(TDatasets).distinct()
    # filter with modules
    if "module_code" in params:
        q = q.filter(TDatasets.modules.any(module_code=params["module_code"]))

    # filters with cruved
    if info_role.value_filter == "2":
        q = q.join(CorDatasetActor, CorDatasetActor.id_dataset == TDatasets.id_dataset)
        # if organism is None => do not filter on id_organism even if level = 2
        if info_role.id_organisme is None:
            q = q.filter(CorDatasetActor.id_role == info_role.id_role)
        else:
            q = q.filter(
                or_(
                    CorDatasetActor.id_organism == info_role.id_organisme,
                    CorDatasetActor.id_role == info_role.id_role,
                )
            )
    elif info_role.value_filter == "1":
        q = q.join(
            CorDatasetActor, CorDatasetActor.id_dataset == TDatasets.id_dataset
        ).filter(CorDatasetActor.id_role == info_role.id_role)

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
                TDatasets.id_acquisition_framework
                == int(request.args["id_acquisition_framework"])
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
    data = q.distinct().all()
    if as_model:
        return data
    return [d.as_dict(True) for d in data]


def get_dataset_details_dict(id_dataset):
    """
    Return a dataset from TDatasetDetails model (with all relationships)
    return also the number of taxon and observation of the dataset
    Use for get_one datasert
    """
    data = DB.session.query(TDatasetDetails).get(id_dataset)
    dataset = data.as_dict(True)
    dataset["taxa_count"] = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset == id_dataset)
        .distinct()
        .count()
    )
    dataset["observation_count"] = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset == id_dataset)
        .count()
    )
    geojsonData = (
        DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .filter(Synthese.id_dataset == id_dataset)
        .first()[0]
    )
    if geojsonData:
        dataset["bbox"] = json.loads(geojsonData)
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
    if info_role.value_filter == "2":
        q = q.join(
            CorAcquisitionFrameworkActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        )
        # if organism is None => do not filter on id_organism even if level = 2
        if info_role.id_organisme is None:
            q = q.filter(CorAcquisitionFrameworkActor.id_role == info_role.id_role)
        else:
            q = q.filter(
                or_(
                    CorAcquisitionFrameworkActor.id_organism == info_role.id_organisme,
                    CorAcquisitionFrameworkActor.id_role == info_role.id_role,
                )
            )
    elif info_role.value_filter == "1":
        q = q.join(
            CorAcquisitionFrameworkActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        ).filter(CorAcquisitionFrameworkActor.id_role == info_role.id_role)

    if params:
        params = params.to_dict()
        if "orderby" in params:
            try:
                order_col = getattr(
                    TAcquisitionFramework.__table__.columns, params.pop("orderby")
                )
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
