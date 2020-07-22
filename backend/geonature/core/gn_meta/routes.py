import json
import logging
from pathlib import Path

from flask import Blueprint, current_app, request, render_template, send_from_directory
from sqlalchemy import or_
from sqlalchemy.sql import text, exists, select
from sqlalchemy.sql.functions import func


from geonature.utils.env import DB
from geonature.core.gn_synthese.models import Synthese

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.tools import InsufficientRightsError

import datetime as dt
from binascii import a2b_base64

from geonature.core.gn_meta.models import (
    TDatasets,
    CorDatasetActor,
    TAcquisitionFramework,
    TAcquisitionFrameworkDetails,
    CorAcquisitionFrameworkActor,
    CorAcquisitionFrameworkObjectif,
    CorAcquisitionFrameworkVoletSINP,
)
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.repositories import (
    get_datasets_cruved,
    get_af_cruved,
    get_dataset_details_dict,
)
from utils_flask_sqla.response import json_resp
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_meta import mtd_utils
from geonature.utils.errors import GeonatureApiError
from geonature.utils.env import BACKEND_DIR

import geonature.utils.filemanager as fm
from binascii import a2b_base64

from flask.wrappers import Response

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


@routes.route("/af_datasets_metadata", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_af_and_ds_metadata(info_role):
    """
    Get all AF with their datasets 
    The Cruved in only apply on dataset in order to see all the AF
    where the user have rights with its dataset
    Use in maplist
    Add the CRUVED permission for each row (Dataset and AD)
    
    .. :quickref: Metadata;

    :param info_role: add with kwargs
    :type info_role: TRole
    :returns:  `dict{'data':list<AF with Datasets>, 'with_erros': <boolean>}`
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
    ids_dataset_user = TDatasets.get_user_datasets(info_role, only_user=True)
    ids_dataset_organisms = TDatasets.get_user_datasets(info_role, only_user=False)
    ids_afs_user = TAcquisitionFramework.get_user_af(info_role, only_user=True)
    ids_afs_org = TAcquisitionFramework.get_user_af(info_role, only_user=False)
    user_cruved = cruved_scope_for_user_in_module(
        id_role=info_role.id_role, module_code="METADATA",
    )[0]

    #  get all af from the JDD filtered with cruved or af where users has rights
    ids_afs_cruved = [
        d.id_acquisition_framework for d in get_af_cruved(info_role, as_model=True)
    ]
    list_id_af = [d.id_acquisition_framework for d in datasets] + ids_afs_cruved
    afs = (
        DB.session.query(TAcquisitionFramework)
        .filter(TAcquisitionFramework.id_acquisition_framework.in_(list_id_af))
        .all()
    )


    afs_dict = []
    #  get cruved for each AF and prepare dataset
    for af in afs:
        af_dict = af.as_dict()
        af_dict["cruved"] = af.get_object_cruved(
            user_cruved, af.id_acquisition_framework, ids_afs_user, ids_afs_org,
        )
        af_dict["datasets"] = []

        iCreateur = -1
        iMaitreOuvrage = -1
        if af.cor_af_actor:
            for index, actor in enumerate(af.cor_af_actor):
                if actor.nomenclature_actor_role.mnemonique == "Maître d'ouvrage":
                    iMaitreOuvrage = index
                elif actor.nomenclature_actor_role.mnemonique == "Producteur du jeu de données":
                    iCreateur = index


        #af_dict["nom_createur"] = af.cor_af_actor[iCreateur].role.nom_role if iCreateur!=-1 else "Non renseigné"
        af_dict["mail_createur"] = af.cor_af_actor[iCreateur].role.email if iCreateur!=-1 else ""
        af_dict["nom_maitre_ouvrage"] = af.cor_af_actor[iMaitreOuvrage].organism.nom_organisme if iMaitreOuvrage!=-1 else "Non renseigné"
        afs_dict.append(af_dict)

    #  get cruved for each ds and push them in the af
    for d in datasets:
        dataset_dict = d.as_dict()
        dataset_dict["cruved"] = d.get_object_cruved(
            user_cruved, d.id_dataset, ids_dataset_user, ids_dataset_organisms,
        )
        af_of_dataset = get_af_from_id(d.id_acquisition_framework, afs_dict)
        af_of_dataset["datasets"].append(dataset_dict)

    afs_resp = {"data": afs_dict}
    if with_mtd_error:
        afs_resp["with_mtd_errors"] = True
    if not datasets:
        return afs_resp, 404
    return afs_resp


def get_af_from_id(id_af, af_list):
    found_af = None
    for af in af_list:
        if af["id_acquisition_framework"] == id_af:
            found_af = af
            break
    return found_af


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


@routes.route("/dataset_details/<id_dataset>", methods=["GET"])
@permissions.check_cruved_scope("R", True, module_code="METADATA")
@json_resp
def get_dataset_details(info_role, id_dataset):
    """
    Get one dataset with nomenclatures and af

    .. :quickref: Metadata;

    :param id_dataset: the id_dataset
    :param type: int
    :returns: dict<TDatasetDetails>
    """

    dataset = get_dataset_details_dict(id_dataset)

    if info_role.value_filter != "3":
        try:
            if info_role.value_filter == "1":
                actors = [cor["id_role"] for cor in dataset["cor_dataset_actor"]]
                assert info_role.id_role in actors
            elif info_role.value_filter == "2":
                actors = [cor["id_role"] for cor in dataset["cor_dataset_actor"]]
                organisms = [cor["id_organism"] for cor in dataset["cor_dataset_actor"]]
                assert (
                    info_role.id_role in actors or info_role.id_organisme in organisms
                )
        except AssertionError:
            raise InsufficientRightsError(
                ('User "{}" cannot read this current dataset').format(
                    info_role.id_role
                ),
                403,
            )

    return dataset


@routes.route("/upload_canvas", methods=["POST"])
@json_resp
def upload_canvas():
    """Upload the canvas as a temporary image used while generating the pdf file
    """
    data = request.data[22:]
    filepath = str(BACKEND_DIR) + '/static/images/taxa.png'
    fm.remove_file(filepath)
    if data:
        binary_data = a2b_base64(data)
        fd = open(filepath, 'wb')
        fd.write(binary_data)
        fd.close()
    return "OK"


@routes.route("/dataset/<int:ds_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="METADATA")
@json_resp
def delete_dataset(info_role, ds_id):
    """
    Delete a dataset

    .. :quickref: Metadata;
    """
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" a dataset').format(
                info_role.id_role, info_role.code_action
            ),
            403,
        )

    DB.session.query(CorDatasetActor).filter(
        CorDatasetActor.id_dataset == ds_id
    ).delete()
    
    DB.session.query(TDatasets).filter(
        TDatasets.id_dataset == ds_id
    ).delete()

    DB.session.commit()

    return "OK"


@routes.route("/activate_dataset/<int:ds_id>/<string:active>", methods=["POST"])
@permissions.check_cruved_scope("U", True, module_code="METADATA")
@json_resp
def activate_dataset(info_role, ds_id, active):
    """
    Activate or deactivate a dataset

    .. :quickref: Metadata;
    """
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" a dataset').format(
                info_role.id_role, info_role.code_action
            ),
            403,
        )

    DB.session.query(TDatasets).filter(TDatasets.id_dataset == ds_id).update({'active' : active=='true'})
    DB.session.commit()
    return "activated" if active else "deactivated"


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
        if "id_cda" in cor and cor.get("id_cda") is None:
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


@routes.route("/dataset/export_pdf/<id_dataset>", methods=["GET"])
@permissions.check_cruved_scope("E", True, module_code="METADATA")
def get_export_pdf_dataset(id_dataset, info_role):
    """
    Get a PDF export of one dataset
    """

    # Verification des droits
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" a dataset').format(info_role.id_role, "export"),
            403,
        )

    df = get_dataset_details_dict(id_dataset)

    if info_role.value_filter != "3":
        try:
            if info_role.value_filter == "1":
                actors = [cor["id_role"] for cor in df["cor_dataset_actor"]]
                assert info_role.id_role in actors
            elif info_role.value_filter == "2":
                actors = [cor["id_role"] for cor in df["cor_dataset_actor"]]
                organisms = [cor["id_organism"] for cor in df["cor_dataset_actor"]]
                assert (
                    info_role.id_role in actors or info_role.id_organisme in organisms
                )
        except AssertionError:
            raise InsufficientRightsError(
                ('User "{}" cannot read this current dataset').format(
                    info_role.id_role
                ),
                403,
            )

    if not df:
        return (
            render_template(
                "error.html",
                error="Le dataset presente des erreurs",
                redirect=current_app.config["URL_APPLICATION"] + "/#/metadata",
            ),
            404,
        )

    if len(df["dataset_desc"]) > 240:
        df["dataset_desc"] = df["dataset_desc"][:240] + "..."

    df["css"] = {
        "logo": "Logo_pdf.png",
        "bandeau": "Bandeau_pdf.png",
        "entite": "sinp",
    }

    date = dt.datetime.now().strftime("%d/%m/%Y")

    df["footer"] = {
        "url": current_app.config["URL_APPLICATION"]
        + "/#/metadata/dataset_detail/"
        + id_dataset,
        "date": date,
    }

    filename = "jdd_{}_{}_{}.pdf".format(
        id_dataset,
        df["dataset_shortname"].replace(" ", "_"),
        dt.datetime.now().strftime("%d%m%Y_%H%M%S"),
    )

    try:
        f = open(str(BACKEND_DIR) + '/static/images/taxa.png')
        f.close()
        df["chart"] = True
    except IOError:
        df["chart"] = False

    # Appel de la methode pour generer un pdf
    pdf_file = fm.generate_pdf("dataset_template_pdf.html", df, filename)
    pdf_file_posix = Path(pdf_file)
    return send_from_directory(
        str(pdf_file_posix.parent),
        pdf_file_posix.name,
        as_attachment=True
    )


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


@routes.route(
    "/acquisition_frameworks/export_pdf/<id_acquisition_framework>", methods=["GET"]
)
@permissions.check_cruved_scope("E", True, module_code="METADATA")
def get_export_pdf_acquisition_frameworks(id_acquisition_framework, info_role):
    """
    Get a PDF export of one acquisition
    """

    # Verification des droits
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" a dataset').format(info_role.id_role, "export"),
            403,
        )

    # Recuperation des données
    af = DB.session.query(TAcquisitionFrameworkDetails).get(id_acquisition_framework)
    acquisition_framework = af.as_dict(True)

    q = DB.session.query(TDatasets).distinct()
    data = q.filter(
        TDatasets.id_acquisition_framework == id_acquisition_framework
    ).all()
    dataset_ids = [d.id_dataset for d in data]
    acquisition_framework["datasets"] = [d.as_dict(True) for d in data]

    nb_data = len(dataset_ids)
    nb_taxons = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .distinct()
        .count()
    )
    nb_observations = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .count()
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
            start_date = dt.datetime.strptime(
                acquisition_framework["acquisition_framework_start_date"], "%Y-%m-%d"
            )
            acquisition_framework[
                "acquisition_framework_start_date"
            ] = start_date.strftime("%d/%m/%Y")
        if acquisition_framework["acquisition_framework_end_date"]:
            end_date = dt.datetime.strptime(
                acquisition_framework["acquisition_framework_end_date"], "%Y-%m-%d"
            )
            acquisition_framework["acquisition_framework_end_date"] = end_date.strftime(
                "%d/%m/%Y"
            )
        acquisition_framework["css"] = {
            "logo": "Logo_pdf.png",
            "bandeau": "Bandeau_pdf.png",
            "entite": "sinp",
        }
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

    filename = "{}_{}_{}.pdf".format(
        id_acquisition_framework,
        acquisition_framework["acquisition_framework_name"][0:31].replace(" ", "_"),
        dt.datetime.now().strftime("%d%m%Y_%H%M%S"),
    )

    try:
        f = open(str(BACKEND_DIR) + '/static/images/taxa.png')
        f.close()
        acquisition_framework["chart"] = True
    except IOError:
        acquisition_framework["chart"] = False

    # Appel de la methode pour generer un pdf
    pdf_file = fm.generate_pdf('cadre_acquisition_template_pdf.html', acquisition_framework, filename)

    # pprint.pprint(acquisition_framework)

    return Response(
        pdf_file,
        mimetype="application/pdf",
        headers={
            "Content-disposition": "attachment; filename=" + filename,
            "Content-type": "application/pdf"
        }
    )
    pdf_file_posix = Path(pdf_file)
    return send_from_directory(
        str(pdf_file_posix.parent),
        pdf_file_posix.name,
        as_attachment=True
    )


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


@routes.route(
    "/acquisition_framework_details/<id_acquisition_framework>", methods=["GET"]
)
@json_resp
def get_acquisition_framework_details(id_acquisition_framework):
    """
    Get one AF

    .. :quickref: Metadata;

    :param id_acquisition_framework: the id_acquisition_framework
    :param type: int
    """
    af = DB.session.query(TAcquisitionFrameworkDetails).get(id_acquisition_framework)
    if not af:
        return None
    acquisition_framework = af.as_dict(True)

    datasets = (
        acquisition_framework["datasets"] if "datasets" in acquisition_framework else []
    )
    dataset_ids = [d["id_dataset"] for d in datasets]
    geojsonData = (
        DB.session.query(func.ST_AsGeoJSON(func.ST_Extent(Synthese.the_geom_4326)))
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .first()[0]
    )
    if geojsonData:
        acquisition_framework["bbox"] = json.loads(geojsonData)
    nb_data = len(dataset_ids)
    nb_taxons = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .distinct()
        .count()
    )
    nb_observations = (
        DB.session.query(Synthese.cd_nom)
        .filter(Synthese.id_dataset.in_(dataset_ids))
        .count()
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
        return acquisition_framework
    return None


@routes.route("/acquisition_framework/<int:af_id>", methods=["DELETE"])
@permissions.check_cruved_scope("D", True, module_code="METADATA")
@json_resp
def delete_acquisition_framework(info_role, af_id):
    """
    Delete an acquisition framework
    .. :quickref: Metadata;
    """
    if info_role.value_filter == "0":
        raise InsufficientRightsError(
            ('User "{}" cannot "{}" an acquisition_framework').format(
                info_role.id_role, info_role.code_action
            ),
            403,
        )

    DB.session.query(CorAcquisitionFrameworkActor).filter(
        CorAcquisitionFrameworkActor.id_acquisition_framework == af_id
    ).delete()
    
    DB.session.query(TAcquisitionFramework).filter(
        TAcquisitionFramework.id_acquisition_framework == af_id
    ).delete()

    DB.session.commit()

    return "OK"


@routes.route("/acquisition_framework", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="METADATA")
@json_resp
def post_acquisition_framework(info_role):
    """
    Post an acquisition framework
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

