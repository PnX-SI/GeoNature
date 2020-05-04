import json
import logging
from flask import Blueprint, current_app, request

from sqlalchemy import or_
from sqlalchemy.sql import text

from geonature.utils.env import DB

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.tools import InsufficientRightsError

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
    CorAcquisitionFrameworkObjectif,
    CorAcquisitionFrameworkVoletSINP,
)
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.repositories import get_datasets_cruved, get_af_cruved
from utils_flask_sqla.response import json_resp
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_meta import mtd_utils
from geonature.utils.errors import GeonatureApiError

routes = Blueprint("gn_meta", __name__)

# get the root logger
log = logging.getLogger()
gunicorn_error_logger = logging.getLogger("gunicorn.error")


@routes.route("/list/datasets", methods=["GET"])
@json_resp
def get_datasets_list():
    q = DB.session.query(TDatasets)
    data = q.all()
    return [d.as_dict(columns=("id_dataset", "dataset_name")) for d in data]


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
            gunicorn_error_logger.info(e)
            log.error(e)
            with_mtd_error = True
    params = request.args.to_dict()
    datasets = get_datasets_cruved(info_role, params)
    datasets_resp = {"data": datasets}
    if with_mtd_error:
        datasets_resp["with_mtd_errors"] = True
    if not datasets:
        return datasets_resp, 404
    return datasets_resp


@routes.route("/datasets_metadata", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_datasets_metadata(info_role):
    """
    Get datasets list with metadata module CRUVED
    Use in maplist
    Add the CRUVED permission for each row
    
    .. :quickref: Metadata;

    :param info_role: add with kwargs
    :type info_role: TRole
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
            gunicorn_error_logger.info(e)
            log.error(e)
            with_mtd_error = True
    params = request.args.to_dict()
    datasets = get_datasets_cruved(info_role, params, as_model=True)

    id_dataset_user = TDatasets.get_user_datasets(info_role, only_user=True)
    id_dataset_organisms = TDatasets.get_user_datasets(info_role, only_user=False)
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]
    datasets_dict = []
    for d in datasets:
        dataset_dict = d.as_dict(True)
        dataset_dict["cruved"] = d.get_object_cruved(
            user_cruved, d.id_dataset, id_dataset_user, id_dataset_organisms,
        )
        datasets_dict.append(dataset_dict)
    datasets_resp = {"data": datasets_dict}
    if with_mtd_error:
        datasets_resp["with_mtd_errors"] = True
    if not datasets:
        return datasets_resp, 404
    return datasets_resp


@routes.route("/dataset/<id_dataset>", methods=["GET"])
@json_resp
def get_dataset(id_dataset):
    """
    Get one dataset

    .. :quickref: Metadata;

    :param id_dataset: the id_dataset
    :param type: int
    :returns: dict<TDataset>
    """
    data = DB.session.query(TDatasets).get(id_dataset)
    cor = data.cor_dataset_actor
    dataset = data.as_dict(True)
    organisms = []
    for c in cor:
        if c.organism:
            organisms.append(c.organism.as_dict())
        else:
            organisms.append(None)
    i = 0
    for o in organisms:
        dataset["cor_dataset_actor"][i]["organism"] = o
        i = i + 1
    return dataset


@routes.route("/dataset", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
@json_resp
def post_dataset(info_role):
    """
    Post a dataset

    .. :quickref: Metadata;
    """
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" a dataset').format(
                info_role.id_role, info_role.code_action
            ),
            403,
        )

    data = dict(request.get_json())
    cor_dataset_actor = data.pop("cor_dataset_actor")
    modules = data.pop("modules")

    dataset = TDatasets(**data)
    for cor in cor_dataset_actor:
        # remove id_cda if None otherwise merge no working well
        if "id_cda" in cor and cor["id_cda"] is None:
            cor.pop("id_cda")
        dataset.cor_dataset_actor.append(CorDatasetActor(**cor))

    # init the relationship as an empty list
    modules_obj = (
        DB.session.query(TModules).filter(TModules.id_module.in_(modules)).all()
    )
    dataset.modules = modules_obj
    if dataset.id_dataset:
        DB.session.merge(dataset)
    else:
        DB.session.add(dataset)
    DB.session.commit()
    return dataset.as_dict(True)


@routes.route("/acquisition_frameworks", methods=["GET"])
@permissions.check_cruved_scope("R", True)
@json_resp
def get_acquisition_frameworks(info_role):
    """
    Get all AF with cruved filter

    .. :quickref: Metadata;

    """
    params = request.args
    return get_af_cruved(info_role, params)


@routes.route("/acquisition_frameworks_metadata", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_acquisition_frameworks_metadata(info_role):
    """
    Get all AF with cruved filter
    Use for metadata module. 
    Add the cruved permission for each row

    .. :quickref: Metadata;

    """
    params = request.args
    afs = get_af_cruved(info_role, params, as_model=True)
    id_afs_user = TAcquisitionFramework.get_user_af(info_role, only_user=True)
    id_afs_org = TAcquisitionFramework.get_user_af(info_role, only_user=False)
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]
    afs_dict = []
    for af in afs:
        af_dict = af.as_dict()
        af_dict["cruved"] = af.get_object_cruved(
            user_cruved=user_cruved,
            id_object=af.id_acquisition_framework,
            ids_object_user=id_afs_user,
            ids_object_organism=id_afs_org,
        )
        afs_dict.append(af_dict)
    return afs_dict


@routes.route("/acquisition_framework/<id_acquisition_framework>", methods=["GET"])
@json_resp
def get_acquisition_framework(id_acquisition_framework):
    """
    Get one AF

    .. :quickref: Metadata;

    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    af = DB.session.query(TAcquisitionFramework).get(id_acquisition_framework)
    if af:
        return af.as_dict(True)
    return None


@routes.route("/acquisition_framework", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
@json_resp
def post_acquisition_framework(info_role):
    """
    Post a dataset
    .. :quickref: Metadata;
    """
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" a dataset').format(
                info_role.id_role, info_role.code_action
            ),
            403,
        )
    data = dict(request.get_json())

    cor_af_actor = data.pop("cor_af_actor")
    cor_objectifs = data.pop("cor_objectifs")
    cor_volets_sinp = data.pop("cor_volets_sinp")

    af = TAcquisitionFramework(**data)

    for cor in cor_af_actor:
        # remove id_cda if None otherwise merge no working well
        if "id_cafa" in cor and cor["id_cafa"] is None:
            cor.pop("id_cafa")
        af.cor_af_actor.append(CorAcquisitionFrameworkActor(**cor))

    if cor_objectifs is not None:
        objectif_nom = (
            DB.session.query(TNomenclatures)
            .filter(TNomenclatures.id_nomenclature.in_(cor_objectifs))
            .all()
        )
        for obj in objectif_nom:
            af.cor_objectifs.append(obj)

    if cor_volets_sinp is not None:
        volet_nom = (
            DB.session.query(TNomenclatures)
            .filter(TNomenclatures.id_nomenclature.in_(cor_volets_sinp))
            .all()
        )
        for volet in volet_nom:
            af.cor_volets_sinp.append(volet)
    if af.id_acquisition_framework:
        DB.session.merge(af)
    else:
        DB.session.add(af)
    DB.session.commit()
    return af.as_dict()


def get_cd_nomenclature(id_type, cd_nomenclature):
    query = "SELECT ref_nomenclatures.get_id_nomenclature(:id_type, :cd_n)"
    result = DB.engine.execute(
        text(query), id_type=id_type, cd_n=cd_nomenclature
    ).first()
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

