import logging

from sqlalchemy import or_, String, Date, and_
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
    if scope not in (1, 2, 3):
        raise Unauthorized("Not a valid cruved value")
    elif scope == 3:
        return True
    elif scope in (1, 2):
        sub_q = DB.select(TDatasets).join(
            CorDatasetActor, TDatasets.id_dataset == CorDatasetActor.id_dataset
        )

        or_filter = [
            TDatasets.id_digitizer == role.id_role,
            CorDatasetActor.id_role == role.id_role,
        ]

        # if organism is None => do not filter on id_organism even if level = 2
        if scope == 2 and role.id_organisme is not None:
            or_filter.append(CorDatasetActor.id_organism == role.id_organisme)
        sub_q = sub_q.filter(and_(or_(*or_filter), model.id_dataset == TDatasets.id_dataset))
        return sub_q.exists()

    return True


def cruved_af_filter(model, role, scope):
    if scope not in (1, 2, 3):
        raise Unauthorized("Not a valid cruved value")
    elif scope == 3:
        return True
    elif scope in (1, 2):
        sub_q = DB.select(TAcquisitionFramework).join(
            CorAcquisitionFrameworkActor,
            TAcquisitionFramework.id_acquisition_framework
            == CorAcquisitionFrameworkActor.id_acquisition_framework,
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
        return sub_q.exists()


def get_metadata_list(role, scope, args, exclude_cols):
    num = args.get("num")
    uuid = args.get("uuid")
    name = args.get("name")
    date = args.get("date")
    organisme = args.get("organism")
    person = args.get("person")
    selector = args.get("selector")
    is_parent = args.get("is_parent")

    # @TODO : replace by select
    query = DB.session.query(TAcquisitionFramework)

    if is_parent is not None:
        query = query.where(TAcquisitionFramework.is_parent)

    if selector == "af" and set(["organism", "person"]).intersection(args):
        query = query.join(
            CorAcquisitionFrameworkActor,
            TAcquisitionFramework.id_acquisition_framework
            == CorAcquisitionFrameworkActor.id_acquisition_framework,
        )
        # remove cor_af_actor from joined load because already joined
        exclude_cols.append("cor_af_actor")

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
    if args.get("selector") == "af":
        query = (
            query.where(TAcquisitionFramework.id_acquisition_framework == num if num else True)
            .where(
                cast(TAcquisitionFramework.unique_acquisition_framework_id, String).ilike(
                    f"%{uuid.strip()}%"
                )
                if uuid
                else True
            )
            .where(
                TAcquisitionFramework.acquisition_framework_name.ilike(f"%{name}%")
                if name
                else True
            )
            .where(CorAcquisitionFrameworkActor.id_organism == organisme if organisme else True)
            .where(CorAcquisitionFrameworkActor.id_role == person if person else True)
        )

    elif args.get("selector") == "ds":
        query = (
            query.where(TDatasets.id_dataset == num if num else True)
            .where(
                cast(TDatasets.unique_dataset_id, String).ilike(f"%{uuid.strip()}%")
                if uuid
                else True
            )
            .where(TAcquisitionFramework.datasets.any(dataset_name=name) if name else True)
            .where(cast(TDatasets.meta_create_date, Date) == date if date else True)
            .where(CorDatasetActor.id_organism == organisme if organisme else True)
            .where(CorDatasetActor.id_role == person if person else True)
        )

    if args.get("orderby", None):
        try:
            query = query.order_by(getattr(TAcquisitionFramework, args.get("orderby")).asc())
        except:
            query = query.order_by(getattr(TDatasets, args.get("orderby")).asc())
        finally:
            pass
    return query
