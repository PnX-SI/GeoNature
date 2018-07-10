import json

import pytest

from flask import url_for
from cookies import Cookie

import server
from geonature.utils.env import load_config, get_config_file_path

#TODO: fixture pour mettre des données test dans la base a chaque test


@pytest.fixture
def app():
    config_path = get_config_file_path()
    config = load_config(config_path)
    app = server.get_app(config)
    app.config['TESTING'] = True
    return app


def post_json(client, url, json_dict):
    """Send dictionary json_dict as a json to the specified url """
    return client.post(url, data=json.dumps(json_dict), content_type='application/json')

def json_of_response(response):
    """Decode json from response"""
    return json.loads(response.data.decode('utf8'))

mimetype = 'application/json'
headers = {
    'Content-Type': mimetype,
    'Accept': mimetype
}

def get_token(client, login="admin", password="admin"):
    data = {
            'login': login,
            'password': password,
            'id_application': 14,
            'with_cruved': True
        }
    response = client.post(
        url_for('auth.login'),
        data = json.dumps(data),
        headers = headers
    )
    try:
        token = Cookie.from_string(response.headers['Set-Cookie'])
        return token.value
    except Exception:
        raise Exception('Invalid login {}, {}'.format(login, password))


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
            "meta_device_entry": "web",
            "comment": None,
            "id_nomenclature_obs_technique": 317,
            "observers": [1],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": 133,
            "t_occurrences_occtax": [
            {
                "id_nomenclature_naturalness": 161,
                "id_nomenclature_obs_meth": 42,
                "digital_proof": None,
                "cor_counting_occtax": [
                {
                    "unique_id_sinp_occtax": "10f937db-54e1-409d-915d-b8c85055fa32",
                    "count_min": 1,
                    "validation_comment": None,
                    "id_nomenclature_life_stage": 2,
                    "count_max": 1,
                    "id_nomenclature_valid_status": 347,
                    "id_nomenclature_sex": 172,
                    "id_validator": None,
                    "id_nomenclature_type_count": 95,
                    "id_nomenclature_obj_count": 147
                }
                ],
                "nom_cite": "Ablette = Alburnus alburnus (Linnaeus, 1758)",
                "meta_v_taxref": "Taxref V9.0",
                "id_nomenclature_blurring": 176,
                "id_nomenclature_bio_status": 30,
                "id_nomenclature_bio_condition": 158,
                "comment": None,
                "id_nomenclature_observation_status": 89,
                "id_nomenclature_determination_method": 446,
                "non_digital_proof": None,
                "id_nomenclature_exist_proof": 81,
                "cd_nom": 67111,
                "id_nomenclature_diffusion_level": 145,
                "sample_number_proof": None,
                "determiner": None
            }
            ]
        }
    }

    return data
