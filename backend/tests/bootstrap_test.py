import pytest

import server
from geonature.utils.env import load_config, get_config_file_path

#TODO: fixture pour mettre des données test dans la base a chaque test

@pytest.fixture
def geonature_app():
    """ set the application context """
    config_path = get_config_file_path()
    config = load_config(config_path)
    app = server.get_app(config)
    ctx = app.app_context()
    ctx.push()
    yield app
    ctx.pop()


@pytest.fixture()
def releve_data(request):
    data = {
        "geometry": {
            "type": "Point",
            "coordinates": [
            3.428936004638672,
            44.276611357355904
            ]
        },
        "properties": {
            "id_dataset": 1,
            "id_digitiser": 1,
            "date_min": "2018-03-02",
            "date_max": "2018-03-02",
            "hour_min": None,
            "hour_max": None,
            "altitude_min": None,
            "altitude_max": None,
            "deleted": False,
            "meta_device_entry": "web",
            "comment": None,
            "id_nomenclature_obs_technique": 343,
            "observers": [],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": 150,
            "t_occurrences_contact": [
            {
                "id_nomenclature_naturalness": 182,
                "determination_method_as_text": "",
                "meta_create_date": "2018-03-05 10:50:11.894492",
                "meta_update_date": "2018-03-05T10:08:13.937Z",
                "id_nomenclature_obs_meth": 42,
                "digital_proof": None,
                "cor_counting_contact": [
                {
                    "unique_id_sinp_occtax": "10f937db-54e1-409d-915d-b8c85055fa32",
                    "count_min": 1,
                    "validation_comment": None,
                    "id_nomenclature_life_stage": 2,
                    "count_max": 1,
                    "id_nomenclature_valid_status": 347,
                    "id_nomenclature_sex": 194,
                    "id_validator": None,
                    "id_nomenclature_type_count": 109,
                    "id_nomenclature_obj_count": 166
                }
                ],
                "nom_cite": "Ablette = Alburnus alburnus (Linnaeus, 1758)",
                "meta_v_taxref": "Taxref V9.0",
                "id_nomenclature_blurring": 200,
                "id_nomenclature_bio_status": 30,
                "id_nomenclature_bio_condition": 178,
                "comment": None,
                "id_nomenclature_observation_status": 101,
                "id_nomenclature_determination_method": 370,
                "non_digital_proof": None,
                "id_nomenclature_exist_proof": 91,
                "cd_nom": 67111,
                "id_nomenclature_diffusion_level": 163,
                "deleted": False,
                "sample_number_proof": None,
                "determiner": None
            }
            ]
        }
    }

    return data
