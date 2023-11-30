from typing import Any
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_commons.models.additional_fields import TAdditionalFields
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_permissions.models import PermissionAvailable, PermObject
from occtax.commands import add_submodule_permissions
import pytest

from datetime import datetime as dt

from flask import Flask, url_for, current_app, g
from werkzeug.exceptions import Unauthorized, Forbidden, NotFound, BadRequest
from shapely.geometry import Point
from geoalchemy2.shape import from_shape
from sqlalchemy import func
from click.testing import CliRunner

from geonature.core.gn_synthese.models import Synthese
from geonature.utils.env import db
from geonature.utils.config import config
from .fixtures import create_module
from .utils import set_logged_user
from .fixtures import *

occtax = pytest.importorskip("occtax")
pytestmark = pytest.mark.skipif(
    "OCCTAX" in config["DISABLED_MODULES"], reason="OccTax is disabled"
)

from occtax.models import (
    DefaultNomenclaturesValue,
    TRelevesOccurrence,
    TOccurrencesOccurrence,
    CorCountingOccurrence,
)
from occtax.repositories import ReleveRepository
from occtax.schemas import OccurrenceSchema, ReleveSchema


@pytest.fixture(scope="session")
def occtax_module():
    return TModules.query.filter_by(module_code="OCCTAX").one()


@pytest.fixture()
def releve_mobile_data(client: Any, datasets: dict[Any, TDatasets]):
    """
    Releve associated with dataset created by "user"
    """
    # mnemonique_types =
    id_dataset = datasets["own_dataset"].id_dataset
    nomenclatures = DefaultNomenclaturesValue.query.all()
    dict_nomenclatures = {n.mnemonique_type: n.id_nomenclature for n in nomenclatures}
    id_nomenclature_grp_typ = (
        DefaultNomenclaturesValue.query.filter_by(mnemonique_type="TYP_GRP")
        .with_entities(DefaultNomenclaturesValue.id_nomenclature)
        .scalar()
    )
    data = {
        "geometry": {
            "type": "Point",
            "coordinates": [3.428936004638672, 44.276611357355904],
        },
        "properties": {
            "id_dataset": id_dataset,
            "id_digitiser": 1,
            "date_min": "2018-03-02",
            "date_max": "2018-03-02",
            "altitude_min": 1000,
            "altitude_max": 1200,
            "meta_device_entry": "web",
            "observers": [1],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": dict_nomenclatures["TYP_GRP"],
            "false_propertie": "",
            "t_occurrences_occtax": [
                {
                    "id_occurrence_occtax": None,
                    "cd_nom": 67111,
                    "nom_cite": "Ablette =  <i> Alburnus alburnus (Linnaeus, 1758)</i> - [ES - 67111]",
                    "false_propertie": "",
                    "cor_counting_occtax": [
                        {
                            "id_counting_occtax": None,
                            "id_nomenclature_life_stage": dict_nomenclatures["STADE_VIE"],
                            "id_nomenclature_sex": dict_nomenclatures["SEXE"],
                            "id_nomenclature_obj_count": dict_nomenclatures["OBJ_DENBR"],
                            "id_nomenclature_type_count": dict_nomenclatures["TYP_DENBR"],
                            "false_propertie": "",
                            "count_min": 1,
                            "count_max": 1,
                        }
                    ],
                }
            ],
        },
    }

    return data


@pytest.fixture()
def releve_data(client: Any, datasets: dict[Any, TDatasets]):
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
def occurrence_data(client: Any, releve_occtax: Any):
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
def additional_field(app, datasets):
    module = TModules.query.filter(TModules.module_code == "OCCTAX").one()
    obj = PermObject.query.filter(PermObject.code_object == "ALL").one()
    datasets = list(datasets.values())
    additional_field = TAdditionalFields(
        field_name="test",
        field_label="Un label",
        required=True,
        description="une descrption",
        quantitative=False,
        unity="degré C",
        field_values=["la", "li"],
        id_widget=1,
        modules=[module],
        objects=[obj],
        datasets=datasets,
    )
    with db.session.begin_nested():
        db.session.add(additional_field)
    return additional_field


@pytest.fixture()
def media_in_export_enabled(monkeypatch):
    monkeypatch.setitem(current_app.config["OCCTAX"], "ADD_MEDIA_IN_EXPORT", True)


@pytest.fixture(scope="function")
def releve_occtax(app: Flask, users: dict, releve_data: dict[str, Any], occtax_module: Any):
    g.current_module = occtax_module
    data = releve_data["properties"]
    data["geom_4326"] = releve_data["geometry"]
    data["observers"] = [users["user"].id_role]
    releve_db = ReleveSchema().load(data)
    with db.session.begin_nested():
        db.session.add(releve_db)
    return releve_db


@pytest.fixture(scope="function")
def releve_module_1(
    app: Flask,
    users: dict,
    releve_data: dict[str, Any],
    datasets: dict[Any, TDatasets],
    module: TModules,
):
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
def occurrence(app: Flask, occurrence_data: dict[str, Any]):
    occ = OccurrenceSchema().load(occurrence_data)
    with db.session.begin_nested():
        db.session.add(occ)
    return occ


@pytest.fixture(scope="function")
def unexisting_id_releve():
    return (db.session.query(func.max(TRelevesOccurrence.id_releve_occtax)).scalar() or 0) + 1


@pytest.mark.usefixtures("client_class", "temporary_transaction", "datasets")
class TestOcctaxReleve:
    def test_get_releve(self, users: dict, releve_occtax: Any):
        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"))

        assert response.status_code == 200
        json_resp = response.json
        assert json_resp["total"] >= 1
        assert releve_occtax.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_one_releve(self, users: dict, releve_occtax: Any):
        set_logged_user(self.client, users["stranger_user"])
        response = self.client.get(
            url_for("pr_occtax.getOneReleve", id_releve=releve_occtax.id_releve_occtax)
        )
        assert response.status_code == Forbidden.code
        set_logged_user(self.client, users["user"])
        response = self.client.get(
            url_for("pr_occtax.getOneReleve", id_releve=releve_occtax.id_releve_occtax)
        )
        assert response.status_code == 200

    def test_insertOrUpdate_releve(
        self, users: dict, releve_mobile_data: dict[str, dict[str, Any]]
    ):
        set_logged_user(self.client, users["stranger_user"])
        response = self.client.post(
            url_for("pr_occtax.insertOrUpdateOneReleve"), json=releve_mobile_data
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.post(
            url_for("pr_occtax.insertOrUpdateOneReleve"), json=releve_mobile_data
        )
        assert response.status_code == 200
        result = db.get_or_404(TRelevesOccurrence, response.json["id"])
        assert result

        # Passage en Update
        releve_mobile_data["properties"]["altitude_min"] = 200
        releve_mobile_data["properties"]["id_releve_occtax"] = response.json["id"]

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.post(
            url_for("pr_occtax.insertOrUpdateOneReleve"), json=releve_mobile_data
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.post(
            url_for("pr_occtax.insertOrUpdateOneReleve"), json=releve_mobile_data
        )
        assert response.status_code == 200
        result = db.get_or_404(TRelevesOccurrence, response.json["id"])
        assert result.altitude_min == 200

    def test_update_releve(self, users: dict, releve_occtax: Any, releve_data: dict[str, Any]):
        set_logged_user(self.client, users["stranger_user"])
        response = self.client.post(
            url_for("pr_occtax.updateReleve", id_releve=releve_occtax.id_releve_occtax),
            json=releve_data,
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.post(
            url_for("pr_occtax.updateReleve", id_releve=releve_occtax.id_releve_occtax),
            json=releve_data,
        )
        assert response.status_code == 200
        response = self.client.post(
            url_for("pr_occtax.updateReleve", id_releve=0), json=releve_data
        )
        assert response.status_code == 404

    def test_delete_releve(self, users: dict, releve_occtax: Any):
        set_logged_user(self.client, users["stranger_user"])
        response = self.client.delete(
            url_for("pr_occtax.deleteOneReleve", id_releve=releve_occtax.id_releve_occtax)
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["admin_user"])
        response = self.client.delete(
            url_for("pr_occtax.deleteOneReleve", id_releve=releve_occtax.id_releve_occtax)
        )
        assert response.status_code == 200

    def test_post_releve(self, users: dict, releve_data: dict[str, Any]):
        # post with cruved = C = 2
        set_logged_user(self.client, users["user"])

        response = self.client.post(url_for("pr_occtax.createReleve"), json=releve_data)
        assert response.status_code == 200

        releve_data["date_min"] = "sdusbuzebushbdjuhezuiefbuziefh"
        response = self.client.post(url_for("pr_occtax.createReleve"), json=releve_data)
        assert response.status_code == BadRequest.code

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.post(url_for("pr_occtax.createReleve"), json=releve_data)
        assert response.status_code == Forbidden.code

    def test_post_releve_in_module_bis(
        self,
        users: dict,
        releve_data: dict[str, Any],
        module: TModules,
        datasets: dict[Any, TDatasets],
    ):
        set_logged_user(self.client, users["admin_user"])
        # change id_dataset to a dataset associated whith module_1
        releve_data["properties"]["id_dataset"] = datasets["with_module_1"].id_dataset
        response = self.client.post(
            url_for("pr_occtax.createReleve", module_code=module.module_code), json=releve_data
        )
        assert response.status_code == 200
        data = response.json
        assert data["properties"]["id_module"] == module.id_module


@pytest.mark.usefixtures("client_class", "temporary_transaction", "datasets", "module")
class TestOcctaxOccurrence:
    def test_post_occurrence(self, users: dict, occurrence_data: dict[str, Any]):
        set_logged_user(self.client, users["stranger_user"])
        response = self.client.post(
            url_for("pr_occtax.createOccurrence", id_releve=occurrence_data["id_releve_occtax"]),
            json=occurrence_data,
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.post(
            url_for("pr_occtax.createOccurrence", id_releve=occurrence_data["id_releve_occtax"]),
            json=occurrence_data,
        )
        assert response.status_code == 200
        json_resp = response.json
        assert len(json_resp["cor_counting_occtax"]) == 2

        occurrence_data["additional_fields"] = None
        response = self.client.post(
            url_for("pr_occtax.createOccurrence", id_releve=occurrence_data["id_releve_occtax"]),
            json=occurrence_data,
        )
        assert response.status_code == BadRequest.code

        # TODO : test dans la synthese qu'il y a bien 2 ligne pour l'UUID couting

    def test_update_occurrence(self, users: dict, occurrence: Any):
        set_logged_user(self.client, users["user"])
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

    def test_delete_occurrence(self, users: dict, occurrence):
        set_logged_user(self.client, users["stranger_user"])
        response = self.client.delete(
            url_for("pr_occtax.deleteOneOccurence", id_occ=occurrence.id_occurrence_occtax)
        )
        assert response.status_code == Forbidden.code
        set_logged_user(self.client, users["user"])
        occ = db.session.get(TOccurrencesOccurrence, occurrence.id_occurrence_occtax)
        assert occ
        response = self.client.delete(
            url_for("pr_occtax.deleteOneOccurence", id_occ=occurrence.id_occurrence_occtax)
        )
        occ = db.session.get(TOccurrencesOccurrence, occurrence.id_occurrence_occtax)
        assert response.status_code == 204
        assert not occ


@pytest.mark.usefixtures("client_class", "temporary_transaction", "datasets", "module")
class TestOcctax:
    def test_post_releve_in_module_bis(
        self,
        users: dict,
        releve_data: dict[str, Any],
        module: TModules,
        datasets: dict[Any, TDatasets],
    ):
        set_logged_user(self.client, users["admin_user"])
        # change id_dataset to a dataset associated whith module_1
        releve_data["properties"]["id_dataset"] = datasets["with_module_1"].id_dataset
        response = self.client.post(
            url_for("pr_occtax.createReleve", module_code=module.module_code), json=releve_data
        )
        assert response.status_code == 200
        data = response.json
        assert data["properties"]["id_module"] == module.id_module

    def test_get_defaut_nomenclatures(self, users: dict):
        response = self.client.get(url_for("pr_occtax.getDefaultNomenclatures"))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getDefaultNomenclatures"))
        assert response.status_code == 200

        response = self.client.get(url_for("pr_occtax.getDefaultNomenclatures", id_type="test"))
        assert response.status_code == NotFound.code

    def test_get_one_counting(self, occurrence: Any, users: dict):
        set_logged_user(self.client, users["stranger_user"])
        response = self.client.get(
            url_for(
                "pr_occtax.getOneCounting",
                id_counting=occurrence.cor_counting_occtax[0].id_counting_occtax,
            )
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(
            url_for(
                "pr_occtax.getOneCounting",
                id_counting=occurrence.cor_counting_occtax[0].id_counting_occtax,
            )
        )
        assert response.status_code == 200

    def test_delete_occurrence_counting(self, users: dict, occurrence):
        id_counting = occurrence.cor_counting_occtax[0].id_counting_occtax

        set_logged_user(self.client, users["stranger_user"])
        response = self.client.delete(
            url_for(
                "pr_occtax.deleteOneOccurenceCounting",
                id_count=id_counting,
            )
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])

        count = db.session.get(CorCountingOccurrence, id_counting)
        assert count

        response = self.client.delete(
            url_for(
                "pr_occtax.deleteOneOccurenceCounting",
                id_count=id_counting,
            )
        )
        count = db.session.get(CorCountingOccurrence, id_counting)
        assert response.status_code == 204
        assert not count

    def test_command_permission_module(self, module):
        client_command_line = CliRunner()
        with db.session.begin_nested():
            db.session.add(module)

        client_command_line.invoke(add_submodule_permissions, [module.module_code])
        permission_available = (
            db.select(PermissionAvailable)
            .join(TModules)
            .where(TModules.module_code == module.module_code)
        )
        permission_available = db.session.scalars(permission_available).all()

        assert len(permission_available) == 5


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestOcctaxGetReleveFilter:
    def test_get_releve_filter_observers_not_present(self, users: dict, releve_occtax: Any):
        query_string = {"observers": [users["admin_user"].id_role]}

        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax not in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_observers(self, users: dict, releve_occtax: Any):
        query_string = {"observers": [users["user"].id_role]}

        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_altitude_min(self, users: dict, releve_occtax: Any):
        query_string = {"altitude_min": releve_occtax.altitude_min - 1}

        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releve_filter_altitude_min_not_present(self, users: dict, releve_occtax: Any):
        query_string = {"altitude_min": releve_occtax.altitude_min + 1}

        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 200
        json_resp = response.json
        assert releve_occtax.id_releve_occtax not in [
            int(releve_json["id"]) for releve_json in json_resp["items"]["features"]
        ]

    def test_get_releves_by_submodule(
        self,
        users: dict,
        module: TModules,
        datasets: dict[Any, TDatasets],
        releve_module_1: Any,
        occtax_module: Any,
    ):
        set_logged_user(self.client, users["admin_user"])

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

    def test_jwt(self, users: dict):
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(
            url_for("pr_occtax.getReleves"),
        )
        assert response.status_code == 200

    def test_export_occtax(
        self,
        users: dict,
        datasets: dict[Any, TDatasets],
        additional_field,
        occurrence,
        media_in_export_enabled,
    ):
        set_logged_user(self.client, users["user"])
        response = self.client.get(
            url_for(
                "pr_occtax.export", format="csv", id_dataset=datasets["own_dataset"].id_dataset
            ),
        )
        assert response.status_code == 200

        response = self.client.get(
            url_for("pr_occtax.export", id_dataset=datasets["own_dataset"].id_dataset),
        )
        assert response.status_code == 200

        response = self.client.get(
            url_for(
                "pr_occtax.export",
                format="shapefile",
                id_dataset=datasets["own_dataset"].id_dataset,
            ),
        )
        assert response.status_code == 200

    def test_export_occtax_no_additional(
        self, users: dict, datasets: dict[Any, TDatasets], occurrence
    ):
        set_logged_user(self.client, users["user"])
        response = self.client.get(
            url_for(
                "pr_occtax.export", format="csv", id_dataset=datasets["own_dataset"].id_dataset
            ),
        )
        assert response.status_code == 200

        response = self.client.get(
            url_for("pr_occtax.export", id_dataset=datasets["own_dataset"].id_dataset),
        )
        assert response.status_code == 200

        response = self.client.get(
            url_for(
                "pr_occtax.export",
                format="shapefile",
                id_dataset=datasets["own_dataset"].id_dataset,
            ),
        )
        assert response.status_code == 200


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
    def test_get_releve_filter_wrong_type(self, users: dict, wrong_value):
        query_string = wrong_value
        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("pr_occtax.getReleves"), query_string=query_string)

        assert response.status_code == 500  # FIXME 500 should not be possible
