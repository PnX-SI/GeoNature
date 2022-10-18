from geonature.core.gn_commons.models.base import TModules
import pytest

from datetime import datetime as dt

from flask import url_for, current_app, g
from werkzeug.exceptions import Forbidden, NotFound
from shapely.geometry import Point
from geoalchemy2.shape import from_shape
from sqlalchemy import func

from geonature.core.gn_permissions.models import VUsersPermissions
from geonature.core.gn_synthese.models import Synthese
from geonature.utils.env import db
from .utils import set_logged_user_cookie
from .fixtures import *

occtax = pytest.importorskip("occtax")

from occtax.models import DefaultNomenclaturesValue, TRelevesOccurrence
from occtax.repositories import ReleveRepository
from occtax.schemas import OccurrenceSchema, ReleveSchema


@pytest.fixture(scope="session")
def occtax_module():
    return TModules.query.filter_by(module_code="OCCTAX").one()


@pytest.fixture()
def releve_data(client, datasets):
    """
    Releve associated with dataset created by "user"
    """
    id_dataset = datasets["own_dataset"].id_dataset
    id_nomenclature_grp_typ = (
        DefaultNomenclaturesValue.query.filter_by(mnemonique_type="TYP_GRP")
        .with_entities(DefaultNomenclaturesValue.id_nomenclature)
        .scalar()
    )
    data = {
        "depth": 2,
        "geometry": {
            "type": "Point",
            "coordinates": [3.428936004638672, 44.276611357355904],
        },
        "properties": {
            "id_dataset": id_dataset,
            "id_digitiser": 1,
            "date_min": "2018-03-02",
            "date_max": "2018-03-02",
            "hour_min": None,
            "hour_max": None,
            "altitude_min": 1000,
            "altitude_max": 1200,
            "meta_device_entry": "web",
            "comment": None,
            "observers": [1],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": id_nomenclature_grp_typ,
        },
    }

    return data


@pytest.fixture()
def occurrence_data(client, releve_occtax):
    nomenclatures = DefaultNomenclaturesValue.query.all()
    dict_nomenclatures = {n.mnemonique_type: n.id_nomenclature for n in nomenclatures}
    return {
        "id_releve_occtax": releve_occtax.id_releve_occtax,
        "id_nomenclature_obs_technique": dict_nomenclatures["METH_OBS"],
        "id_nomenclature_bio_condition": dict_nomenclatures["ETA_BIO"],
        "id_nomenclature_bio_status": dict_nomenclatures["STATUT_BIO"],
        "id_nomenclature_naturalness": dict_nomenclatures["NATURALITE"],
        "id_nomenclature_exist_proof": dict_nomenclatures["PREUVE_EXIST"],
        "id_nomenclature_behaviour": dict_nomenclatures["OCC_COMPORTEMENT"],
        "id_nomenclature_observation_status": dict_nomenclatures["STATUT_OBS"],
        "id_nomenclature_blurring": dict_nomenclatures["DEE_FLOU"],
        "id_nomenclature_source_status": dict_nomenclatures["STATUT_SOURCE"],
        "determiner": "Administrateur test",
        "id_nomenclature_determination_method": dict_nomenclatures["METH_DETERMIN"],
        "nom_cite": "Canis lupus =   Canis lupus Linnaeus, 1758 - [ES - 60577]",
        "cd_nom": 60577,
        "meta_v_taxref": "Taxref v15",
        "sample_number_proof": None,
        "digital_proof": None,
        "non_digital_proof": None,
        "comment": "blah",
        "additional_fields": {},
        "cor_counting_occtax": [
            {
                "id_nomenclature_life_stage": dict_nomenclatures["STADE_VIE"],
                "id_nomenclature_sex": db.session.query(
                    func.ref_nomenclatures.get_id_nomenclature("SEXE", "3")
                ).scalar(),
                "id_nomenclature_obj_count": dict_nomenclatures["OBJ_DENBR"],
                "id_nomenclature_type_count": dict_nomenclatures["TYP_DENBR"],
                "count_min": 2,
                "count_max": 2,
                "medias": [],
                "additional_fields": {},
            },
            {
                "id_nomenclature_life_stage": dict_nomenclatures["STADE_VIE"],
                "id_nomenclature_sex": db.session.query(
                    func.ref_nomenclatures.get_id_nomenclature("SEXE", "2")
                ).scalar(),
                "id_nomenclature_obj_count": dict_nomenclatures["OBJ_DENBR"],
                "id_nomenclature_type_count": dict_nomenclatures["TYP_DENBR"],
                "count_min": 1,
                "count_max": 1,
                "medias": [],
                "additional_fields": {},
            },
        ],
    }


@pytest.fixture(scope="function")
def releve_occtax(app, users, releve_data, occtax_module):
    g.current_module = occtax_module
    data = releve_data["properties"]
    data["geom_4326"] = releve_data["geometry"]
    data["observers"] = [users["user"].id_role]
    releve_db = ReleveSchema().load(data)
    with db.session.begin_nested():
        db.session.add(releve_db)
    return releve_db


@pytest.fixture(scope="function")
def releve_module_1(app, users, releve_data, datasets, module):
    g.current_module = module
    data = releve_data["properties"]
    data["geom_4326"] = releve_data["geometry"]
    data["observers"] = [users["user"].id_role]
    data["id_dataset"] = datasets["with_module_1"].id_dataset
    releve_db = ReleveSchema().load(data)
    with db.session.begin_nested():
        db.session.add(releve_db)
    return releve_db


@pytest.fixture(scope="function")
def occurrence(app, occurrence_data):
    occ = OccurrenceSchema().load(occurrence_data)
    with db.session.begin_nested():
        db.session.add(occ)
    return occ


@pytest.fixture(scope="function")
def unexisting_id_releve():
    return (db.session.query(func.max(TRelevesOccurrence.id_releve_occtax)).scalar() or 0) + 1


@pytest.fixture(scope="function")
def permission(users):
    return db.session.query(VUsersPermissions).filter_by(id_role=users["user"].id_role).first()


@pytest.mark.usefixtures("client_class", "temporary_transaction", "datasets")
class TestOcctax:
    def test_get_releve(self, users, releve_occtax):
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"))

        assert response.status_code == 200
        json_resp = response.json
        assert json_resp["total"] >= 1
        assert releve_occtax.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_post_releve(self, users, releve_data):
        # post with cruved = C = 2
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(url_for("pr_occtax.createReleve"), json=releve_data)
        assert response.status_code == 200

        set_logged_user_cookie(self.client, users["noright_user"])
        response = self.client.post(url_for("pr_occtax.createReleve"), json=releve_data)
        assert response.status_code == Forbidden.code

    def test_post_occurrence(self, users, occurrence_data):
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(
            url_for("pr_occtax.createOccurrence", id_releve=occurrence_data["id_releve_occtax"]),
            json=occurrence_data,
        )
        assert response.status_code == 200
        json_resp = response.json
        assert len(json_resp["cor_counting_occtax"]) == 2

        # TODO : test dans la synthese qu'il y a bien 2 ligne pour l'UUID couting

    def test_update_occurrence(self, users, occurrence):
        set_logged_user_cookie(self.client, users["user"])
        occ_dict = OccurrenceSchema(exclude=("taxref",)).dump(occurrence)
        # change the cd_nom (occurrence level)
        occ_dict["cd_nom"] = 4516
        occ_dict["nom_cite"] = "Etourneau sansonnet"
        # change counting
        occ_dict["cor_counting_occtax"][0]["count_max"] = 3
        occ_dict["cor_counting_occtax"][1]["count_max"] = 5
        response = self.client.post(
            url_for("pr_occtax.updateOccurrence", id_occurrence=occurrence.id_occurrence_occtax),
            json=occ_dict,
        )
        assert response.status_code == 200
        occ = response.json
        # check if in synthese all the UUID has been updated with the new cd_nom
        # -> it check the trigger update occ and update counting
        uuid_counting = [
            counting["unique_id_sinp_occtax"] for counting in occ["cor_counting_occtax"]
        ]
        synthese_data = Synthese.query.filter(Synthese.unique_id_sinp.in_(uuid_counting))
        for s in synthese_data:
            assert s.cd_nom == 4516
        {3, 5}.issubset([s.count_max for s in synthese_data])

    def test_post_releve_in_module_bis(self, users, releve_data, module, datasets):
        set_logged_user_cookie(self.client, users["admin_user"])
        # change id_dataset to a dataset associated whith module_1
        releve_data["properties"]["id_dataset"] = datasets["with_module_1"].id_dataset
        response = self.client.post(
            url_for("pr_occtax.createReleve", module_code=module.module_code), json=releve_data
        )
        assert response.status_code == 200
        data = response.json
        assert data["properties"]["id_module"] == module.id_module

    def test_get_defaut_nomenclatures(self):
        response = self.client.get(url_for("pr_occtax.getDefaultNomenclatures"))
        assert response.status_code == 200


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestOcctaxGetReleveFilter:
    def test_get_releve_filter_observers_not_present(self, users, releve_occtax):
        query_string = {"observers": [users["admin_user"].id_role]}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax not in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_observers(self, users, releve_occtax):
        query_string = {"observers": [users["user"].id_role]}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_altitude_min(self, users, releve_occtax):
        query_string = {"altitude_min": releve_occtax.altitude_min - 1}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_altitude_min_not_present(self, users, releve_occtax):
        query_string = {"altitude_min": releve_occtax.altitude_min + 1}

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax not in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releves_by_submodule(
        self, users, module, datasets, releve_module_1, occtax_module
    ):
        set_logged_user_cookie(self.client, users["admin_user"])

        # get occtax data of OCCTAX_DS module
        # must return only releve of dataset associated with
        response = self.client.get(
            url_for("pr_occtax.getReleves", module_code=module.module_code),
        )
        assert response.status_code == 200
        assert len(response.json["items"]["features"]) == 1
        for r in response.json["items"]["features"]:
            assert r["properties"]["id_dataset"] == datasets["with_module_1"].id_dataset

        # get occtax data of 'Occtax' module must be empty
        response = self.client.get(
            url_for("pr_occtax.getReleves"),
        )
        assert response.status_code == 200
        for feature in response.json["items"]["features"]:
            assert feature["properties"]["id_module"] == occtax_module.id_module


@pytest.mark.usefixtures("client_class", "temporary_transaction")
@pytest.mark.parametrize(
    "wrong_value",
    (
        {"cd_nom": "wrong"},
        {"date_up": 42},
        {"date_low": 42},
        {"date_eq": 42},
        {"altitude_min": "wrong"},
        {"altitude_max": "wrong"},
        {"organism": "wrong"},
    ),
)
class TestOcctaxGetReleveFilterWrongType:
    def test_get_releve_filter_wrong_type(self, users, wrong_value):
        query_string = wrong_value
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 500


@pytest.mark.usefixtures("temporary_transaction")
class TestReleveRepository:
    def test_get_one(self, releve_occtax, permission):
        repository = ReleveRepository(TRelevesOccurrence)
        repo = repository.get_one(id_releve=releve_occtax.id_releve_occtax, info_user=permission)

        assert repo[0].id_releve_occtax == releve_occtax.id_releve_occtax

    def test_get_one_not_found(self, unexisting_id_releve, permission):
        repository = ReleveRepository(TRelevesOccurrence)

        with pytest.raises(NotFound):
            repository.get_one(id_releve=unexisting_id_releve, info_user=permission)

    def test_delete(self, releve_occtax, permission):
        repository = ReleveRepository(TRelevesOccurrence)

        rel = repository.delete(releve_occtax.id_releve_occtax, permission)

        assert rel.id_releve_occtax == releve_occtax.id_releve_occtax

    def test_delete_not_found(self, unexisting_id_releve):
        repository = ReleveRepository(TRelevesOccurrence)

        with pytest.raises(NotFound):
            repository.delete(unexisting_id_releve, permission)
