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
from geonature.utils.utilssqlalchemy import json_resp
from geonature.core.gn_permissions import decorators as permissions
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

    dataset = TDatasets(**data)

    for cor in cor_dataset_actor:
        # remove id_cda if None otherwise merge no working well
        if "id_cda" in cor and cor["id_cda"] is None:
            cor.pop("id_cda")
        dataset.cor_dataset_actor.append(CorDatasetActor(**cor))

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

