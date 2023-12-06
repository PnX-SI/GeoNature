import logging

from sqlalchemy import or_, String, Date, and_, func
from sqlalchemy.inspection import inspect
from sqlalchemy.orm import joinedload, contains_eager, aliased
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
from geonature.core.gn_commons.models import cor_field_dataset, TAdditionalFields


from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
)
from pypnusershub.db.models import Organisme as BibOrganismes
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
            DB.select(func.count("*"))
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
            DB.select(func.count("*"))
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
        sub_q = sub_q.filter(
            and_(
                or_(*or_filter),
                model.id_acquisition_framework == TAcquisitionFramework.id_acquisition_framework,
            )
        )
        return DB.session.execute(sub_q).scalar_one() > 0


def get_metadata_list(role, scope, args, exclude_cols):
    id_acquisition_framework = args.get("num")
    unique_acquisition_framework_id = args.get("uuid")
    acquisition_framework_name = args.get("name")
    meta_create_date = args.get("date")
    id_organism = args.get("organism")
    id_role = args.get("person")
    selector = args.get("selector")
    is_parent = args.get("is_parent")
    order_by = args.get("orderby", None)

    query = DB.select(TAcquisitionFramework).where_if(
        is_parent is not None, TAcquisitionFramework.is_parent
    )

    if selector == "ds":
        query = query.join(
            TDatasets,
            TDatasets.id_acquisition_framework == TAcquisitionFramework.id_acquisition_framework,
        )
        if "organism" in args or "person" in args:
            query = query.join(CorDatasetActor, CorDatasetActor.id_dataset == TDatasets.id_dataset)
        exclude_cols.append("t_datasets")

    joined_loads_rels = [
        db_rel.key
        for db_rel in inspect(TAcquisitionFramework).relationships
        if db_rel.key not in exclude_cols
    ]
    for rel in joined_loads_rels:
        query = query.options(joinedload(getattr(TAcquisitionFramework, rel)))

    query = query.where(
        or_(
            cruved_af_filter(TAcquisitionFramework, role, scope),
            cruved_ds_filter(TDatasets, role, scope),
        )
    )
    if selector == "af":
        if set(["organism", "person"]).intersection(args):
            query = query.join(
                CorAcquisitionFrameworkActor,
                TAcquisitionFramework.id_acquisition_framework
                == CorAcquisitionFrameworkActor.id_acquisition_framework,
            )
            # remove cor_af_actor from joined load because already joined
            exclude_cols.append("cor_af_actor")
        query = (
            query.where(
                TAcquisitionFramework.id_acquisition_framework == id_acquisition_framework
                if id_acquisition_framework
                else True
            )
            .where(
                cast(TAcquisitionFramework.unique_acquisition_framework_id, String).ilike(
                    f"%{unique_acquisition_framework_id.strip()}%"
                )
                if unique_acquisition_framework_id
                else True
            )
            .where(
                TAcquisitionFramework.acquisition_framework_name.ilike(
                    f"%{acquisition_framework_name}%"
                )
                if acquisition_framework_name
                else True
            )
            .where(
                CorAcquisitionFrameworkActor.id_organism == id_organism if id_organism else True
            )
            .where(CorAcquisitionFrameworkActor.id_role == id_role if id_role else True)
        )

    elif selector == "ds":
        query = (
            query.where(
                TDatasets.id_dataset == id_acquisition_framework
                if id_acquisition_framework
                else True
            )
            .where(
                cast(TDatasets.unique_dataset_id, String).ilike(
                    f"%{unique_acquisition_framework_id.strip()}%"
                )
                if unique_acquisition_framework_id
                else True
            )
            .where(
                TAcquisitionFramework.datasets.any(dataset_name=acquisition_framework_name)
                if acquisition_framework_name
                else True
            )
            .where(
                cast(TDatasets.meta_create_date, Date) == meta_create_date
                if meta_create_date
                else True
            )
            .where(CorDatasetActor.id_organism == id_organism if id_organism else True)
            .where(CorDatasetActor.id_role == id_role if id_role else True)
        )

    if order_by:
        try:
            query = query.order_by(getattr(TAcquisitionFramework, order_by).asc())
        except:
            query = query.order_by(getattr(TDatasets, order_by).asc())
        finally:
            pass
    return query
