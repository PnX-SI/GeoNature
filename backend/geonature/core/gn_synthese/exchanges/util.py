from flask import session

from pypnnomenclature.repository import get_nomenclature_id_term, get_nomenclature_list

from ..models import TSources
from geonature.core.gn_meta.models import TDatasets
from geonature.utils.env import DB


SYNTHESE_NOMENCLATURE_TYPES = {
    "id_nomenclature_geo_object_nature": "NAT_OBJ_GEO",
    "id_nomenclature_grp_typ": "TYP_GRP",
    "id_nomenclature_obs_technique": "METH_OBS",
    "id_nomenclature_bio_status": "STATUT_BIO",
    "id_nomenclature_bio_condition": "ETA_BIO",
    "id_nomenclature_naturalness": "NATURALITE",
    "id_nomenclature_exist_proof": "PREUVE_EXIST",
    "id_nomenclature_valid_status": "STATUT_VALID",
    "id_nomenclature_diffusion_level": "NIV_PRECIS",
    "id_nomenclature_life_stage": "STADE_VIE",
    "id_nomenclature_sex": "SEXE",
    "id_nomenclature_obj_count": "OBJ_DENBR",
    "id_nomenclature_type_count": "TYP_DENBR",
    "id_nomenclature_sensitivity": "SENSIBILITE",
    "id_nomenclature_observation_status": "STATUT_OBS",
    "id_nomenclature_blurring": "DEE_FLOU",
    "id_nomenclature_source_status": "STATUT_SOURCE",
    "id_nomenclature_info_geo_type": "TYP_INF_GEO",
    "id_nomenclature_behaviour": "OCC_COMPORTEMENT",
    "id_nomenclature_determination_method": "METH_DETERMIN",
}


class ApiSyntheseException(Exception):
    """
    Exception pour l'api post

    msg : message pour expliquer l'erreur
    code : code de l'erreur

        1 : cd_nomenclature mal défini
        2 : source non définie
        3 : jdd non défini
    """

    def __init__(self, msg, code, data=None):
        self.msg = msg
        self.code = code
        self.data = data

    def as_dict(self):
        return {"code": self.code, "msg": self.msg, "data": self.data}


def get_nomenclatures_synthese():
    """
    données nomenclatures stockée en session
    """

    nomenclatures_synthese = session.get("nomenclatures_synthese")

    if nomenclatures_synthese:
        return nomenclatures_synthese

    nomenclatures_synthese = {}

    for var_id in SYNTHESE_NOMENCLATURE_TYPES:
        code_type = SYNTHESE_NOMENCLATURE_TYPES.get(var_id)
        nomenclatures_synthese[code_type] = get_nomenclature_list(code_type=code_type)

    session["nomenclatures_synthese"] = nomenclatures_synthese

    return nomenclatures_synthese


def get_nomenclature(code_type, value, field_name):
    nomenclatures = get_nomenclatures_synthese().get(code_type)
    nomenclature = list(filter(lambda x: x.get(field_name) == value, nomenclatures.get("values")))
    return nomenclature and nomenclature[0] or {}


def process_nomenclatures(data, cd_to_id):
    """
    cd_to_id :
        True : cd_nomenclature -> id_nomenclature
        False : id_nomenclature -> cd_nomenclature
    """

    for var_id in SYNTHESE_NOMENCLATURE_TYPES:
        var_preffix = var_id.replace("id_nomenclature", "")
        code_type = SYNTHESE_NOMENCLATURE_TYPES.get(var_id)

        if cd_to_id:
            field_name_in = "cd_nomenclature"
            field_name_out = "id_nomenclature"
        else:
            field_name_in = "id_nomenclature"
            field_name_out = "cd_nomenclature"

        var_in = field_name_in + var_preffix
        var_out = field_name_out + var_preffix

        if var_in not in data:
            continue

        value_in = data.get(var_in)

        del data[var_in]
        if not value_in:
            data[var_out] = None
            continue

        value_out = get_nomenclature(code_type, value_in, field_name_in).get(field_name_out)

        # ici on leve une exception si
        #     value_in non None
        #  et value_out None
        if not value_out:
            raise ApiSyntheseException(
                "Nomenclature {}: il n'y a pas de correspondance pour la nomenclature (code_type, {})=({}, {})".format(
                    var_in, field_name_in, code_type, value_in
                ),
                1,
                [
                    {
                        "id_nomenclature": n["id_nomenclature"],
                        "cd_nomenclature": n["cd_nomenclature"],
                        "label_fr": n["label_fr"],
                    }
                    for n in get_nomenclatures_synthese().get(code_type).get("values")
                ],
            )
        data[var_out] = value_out


def pre_process_synthese_data(data, is_post):
    """
    process data
        - convert nomenclature cd_nomenclature to id_nomenclature
        - ...
    """

    data_out = {}
    for key in data:
        data_out[key] = data[key]

    properties = data_out["properties"]

    process_nomenclatures(properties, True)

    check_model(TSources, properties, "id_source", 2, is_post)

    check_model(TDatasets, properties, "id_dataset", 3, is_post)

    return data_out


def check_model(TModel, data, field_name, exception_code, is_post):
    """
    verifie si la source existe bien

    i.e il existe un element de TModel tel que TModel.<field_name> = data[<field_name>]

    si non on lève l'exception

    is_post: on ne teste que si défini
    """

    if (not field_name in data) and (not is_post):
        return

    value = data.get(field_name)
    if not value:
        raise ApiSyntheseException("{} non defini".format(field_name), exception_code)

    try:
        (DB.session.query(TModel).filter(getattr(TModel, field_name) == value).one)

    except Exception as e:
        raise Exception("{}  avec ({}={}) n'existe pas".format(TModel, field_name, value))

    return


def post_process_synthese_data(data):
    """
    process data
        - convert nomenclature id_nomenclature to cd_nomenclature
        - ...
    """
    data_out = {}
    for key in data:
        data_out[key] = data[key]

    process_nomenclatures(data_out["properties"], False)

    return data_out
