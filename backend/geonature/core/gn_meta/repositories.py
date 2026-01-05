import logging

from sqlalchemy import or_, String, Date, and_, func, select
from sqlalchemy.inspection import inspect
from sqlalchemy.orm import joinedload, contains_eager, aliased
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql.functions import func
from sqlalchemy.sql.expression import cast

from flask import request, current_app
import requests

from utils_flask_sqla.serializers import serializable
from utils_flask_sqla.generic import test_type_and_generate_query, testDataType

from geonature.utils.env import DB
from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
)
from werkzeug.exceptions import Unauthorized

log = logging.getLogger()


def cruved_ds_filter(model, role, scope):
    # TODO check if not used elsewhere (not found in major module of Geonature)
    if scope not in (1, 2, 3):
        raise Unauthorized("Not a valid cruved value")
    elif scope == 3:
        return True
    elif scope in (1, 2):
        sub_q = (
            select(func.count("*"))
            .select_from(TDatasets)
            .join(CorDatasetActor, TDatasets.id_dataset == CorDatasetActor.id_dataset)
        )

        or_filter = [
            TDatasets.id_digitizer == role.id_role,
            CorDatasetActor.id_role == role.id_role,
        ]

        # if organism is None => do not filter on id_organism even if level = 2
        if scope == 2 and role.id_organisme is not None:
            or_filter.append(CorDatasetActor.id_organism == role.id_organisme)
        sub_q = sub_q.where(and_(or_(*or_filter), model.id_dataset == TDatasets.id_dataset))
        return DB.session.execute(sub_q).scalar_one() > 0


def cruved_af_filter(model, role, scope):
    if scope not in (1, 2, 3):
        raise Unauthorized("Not a valid cruved value")
    elif scope == 3:
        return True
    elif scope in (1, 2):
        sub_q = (
            select(func.count("*"))
            .select_from(TAcquisitionFramework)
            .join(
                CorAcquisitionFrameworkActor,
                TAcquisitionFramework.id_acquisition_framework
                == CorAcquisitionFrameworkActor.id_acquisition_framework,
            )
        )

        or_filter = [
            TAcquisitionFramework.id_digitizer == role.id_role,
            CorAcquisitionFrameworkActor.id_role == role.id_role,
        ]

        # if organism is None => do not filter on id_organism even if level = 2
        if scope == 2 and role.id_organisme is not None:
            or_filter.append(CorAcquisitionFrameworkActor.id_organism == role.id_organisme)
        sub_q = sub_q.where(
            and_(
                or_(*or_filter),
                model.id_acquisition_framework == TAcquisitionFramework.id_acquisition_framework,
            )
        )
        return DB.session.execute(sub_q).scalar_one() > 0
