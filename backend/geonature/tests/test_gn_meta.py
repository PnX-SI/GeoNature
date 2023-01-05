import csv
import uuid
from io import StringIO
from unittest.mock import patch

import pytest
from flask import url_for
from flask_sqlalchemy import BaseQuery
from geoalchemy2.shape import to_shape

from geojson import Point
from sqlalchemy import func
from werkzeug.exceptions import BadRequest, Conflict, Forbidden, NotFound, Unauthorized
from werkzeug.datastructures import MultiDict
from ref_geo.models import BibAreasTypes, LAreas

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import (
    CorDatasetActor,
    TAcquisitionFramework,
    TDatasets,
)
from geonature.core.gn_meta.routes import get_af_from_id
from geonature.core.gn_permissions.models import (
    CorRoleActionFilterModuleObject,
    TActions,
    TFilters,
)
from geonature.core.gn_synthese.models import Synthese
from geonature.utils.env import db

from .fixtures import *
from .utils import logged_user_headers, set_logged_user_cookie


@pytest.fixture(scope="function")
def commune_without_obs():
    return LAreas.query.filter(
        LAreas.area_type.has(
            BibAreasTypes.type_code == "COM",
        ),
        ~LAreas.synthese_obs.any(),
    ).first()


def getCommBySynthese(obs):
    """
    Return area by synthese
    """
    return LAreas.query.filter(
        LAreas.area_type.has(
            BibAreasTypes.type_code == "COM",
        ),
        LAreas.synthese_obs.any(
            Synthese.id_synthese == obs.id_synthese,
        ),
    ).first()


# TODO: maybe move it to global fixture
@pytest.fixture()
def unexisted_id():
    return db.session.query(func.max(TDatasets.id_dataset)).scalar() + 1


@pytest.fixture
def af_list():
    return [
        {"id_acquisition_framework": 5},
        {"id_acquisition_framework": 2},
        {"id_acquisition_framework": 1},
    ]


@pytest.fixture
def synthese_corr():
    return {
        "identifiant_gn": "id_synthese",
        "identifiantPermanent (SINP)": "unique_id_sinp",
        "nomcite": "nom_cite",
        "jourDateDebut": "date_min",
        "jourDatefin": "date_max",
        "observateurIdentite": "observers",
    }


@pytest.fixture
def mocked_publish_mail():
    with patch("geonature.core.gn_meta.routes.publish_acquisition_framework_mail") as mock:
        yield mock


def get_csv_from_response(data):
    csv_data = data.decode("utf8")
    with StringIO(csv_data) as f:
        for i, row in enumerate(csv.DictReader(f, delimiter=";")):
            yield i, row


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGNMeta:
    def test_acquisition_frameworks_permissions(
        self, app, acquisition_frameworks, datasets, users
    ):
        af = acquisition_frameworks["own_af"]
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == True
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["associate_user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == False
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["stranger_user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == False
            assert af.has_instance_permission(2) == False
            assert af.has_instance_permission(3) == True

        af = acquisition_frameworks["orphan_af"]  # all DS are attached to this AF
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            # The AF has no actors, but the AF has DS on which the user is digitizer!
            assert af.has_instance_permission(1) == True
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

            nested = db.session.begin_nested()
            af.t_datasets.remove(datasets["own_dataset"])
            # Now, the AF has no DS on which user is digitizer.
            assert af.has_instance_permission(1) == False
            # But the AF has still DS on which user organism is actor.
            assert af.has_instance_permission(2) == True
            nested.rollback()
            assert datasets["own_dataset"] in af.t_datasets

        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            af_ids = [af.id_acquisition_framework for af in acquisition_frameworks.values()]
            qs = TAcquisitionFramework.query.filter(
                TAcquisitionFramework.id_acquisition_framework.in_(af_ids)
            )
            assert set(qs.filter_by_scope(0).all()) == set([])
            assert set(qs.filter_by_scope(1).all()) == set(
                [
                    acquisition_frameworks["own_af"],
                    acquisition_frameworks["orphan_af"],  # through DS
                ]
            )
            assert set(qs.filter_by_scope(2).all()) == set(
                [
                    acquisition_frameworks["own_af"],
                    acquisition_frameworks["associate_af"],
                    acquisition_frameworks["orphan_af"],  # through DS
                ]
            )
            assert set(qs.filter_by_scope(3).all()) == set(acquisition_frameworks.values())

    def test_acquisition_framework_is_deletable(self, app, acquisition_frameworks, datasets):
        assert acquisition_frameworks["own_af"].is_deletable() == True
        assert (
            acquisition_frameworks["orphan_af"].is_deletable() == False
        )  # DS are attached to this AF

    def test_create_acquisition_framework(self, users):
        set_logged_user_cookie(self.client, users["user"])

        # Post with only required attributes
        response = self.client.post(
            url_for("gn_meta.create_acquisition_framework"),
            json={
                "acquisition_framework_name": "test",
                "acquisition_framework_desc": "desc",
            },
        )

        assert response.status_code == 200

    def test_create_acquisition_framework_forbidden(self, users):
        set_logged_user_cookie(self.client, users["noright_user"])

        response = self.client.post(url_for("gn_meta.create_acquisition_framework"), data={})

        assert response.status_code == Forbidden.code

    def test_delete_acquisition_framework(self, app, users, acquisition_frameworks, datasets):
        af_id = acquisition_frameworks["orphan_af"].id_acquisition_framework

        response = self.client.delete(url_for("gn_meta.delete_acquisition_framework", af_id=af_id))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["noright_user"])

        # The user has no rights on METADATA module
        response = self.client.delete(url_for("gn_meta.delete_acquisition_framework", af_id=af_id))
        assert response.status_code == Forbidden.code
        assert "METADATA" in response.json["description"]

        set_logged_user_cookie(self.client, users["self_user"])

        # The user has right on METADATA module, but not on this specific AF
        response = self.client.delete(url_for("gn_meta.delete_acquisition_framework", af_id=af_id))
        assert response.status_code == Forbidden.code
        assert "METADATA" not in response.json["description"]

        set_logged_user_cookie(self.client, users["admin_user"])

        # The AF can not be deleted due to attached DS
        response = self.client.delete(url_for("gn_meta.delete_acquisition_framework", af_id=af_id))
        assert response.status_code == Conflict.code

        set_logged_user_cookie(self.client, users["user"])
        af_id = acquisition_frameworks["own_af"].id_acquisition_framework

        response = self.client.delete(url_for("gn_meta.delete_acquisition_framework", af_id=af_id))
        assert response.status_code == 204

    def test_update_acquisition_framework(self, users, acquisition_frameworks):
        new_name = "thenewname"
        af = acquisition_frameworks["own_af"]
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.post(
            url_for(
                "gn_meta.updateAcquisitionFramework",
                id_acquisition_framework=af.id_acquisition_framework,
            ),
            data=dict(acquisition_framework_name=new_name),
        )

        assert response.status_code == 200
        assert response.json.get("acquisition_framework_name") == new_name

    def test_get_acquisition_frameworks(self, users):
        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        response = self.client.get(
            url_for("gn_meta.get_acquisition_frameworks"),
            query_string={
                "datasets": "1",
                "creator": "1",
                "actors": "1",
            },
        )
        assert response.status_code == 200

    def test_get_post_acquisition_frameworks(self, users, commune_without_obs):
        # SIMPLE TEST WITH POST REQUEST
        response = self.client.post(
            url_for("gn_meta.get_acquisition_frameworks"),
            json={},
        )
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["admin_user"])
        # POST EMPTY REQUEST FAIL WITHOUT ANY PARAMS
        response = self.client.post(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == BadRequest.code
        # POST REQUEST WITHOUT JSON AND WITHOUT QUERY STRING
        response = self.client.post(
            url_for("gn_meta.get_acquisition_frameworks"),
            json={},
        )
        assert response.status_code == 200
        # POST REQUEST WITHOUT JSON
        response = self.client.post(
            url_for("gn_meta.get_acquisition_frameworks"),
            query_string={
                "datasets": "1",
                "creator": "1",
                "actors": "1",
            },
            json={},
        )
        assert response.status_code == 200
        # TEST RESPONSE WITH ONE FILTER AREA
        response = self.client.post(
            url_for("gn_meta.get_acquisition_frameworks"),
            json={"areas": [[commune_without_obs.id_type, commune_without_obs.id_area]]},
        )
        assert response.status_code == 200

    def test_get_acquisition_frameworks_list(self, users):
        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks_list"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks_list"))
        assert response.status_code == 200

    def test_filter_acquisition_by_geo(self, synthese_data, users, commune_without_obs):
        # security test already passed in previous tests
        set_logged_user_cookie(self.client, users["admin_user"])

        # get 2 synthese observations in two differents AF and two differents communes
        s1, s2 = synthese_data["p1_af1"], synthese_data["p3_af3"]
        comm1, comm2 = getCommBySynthese(s1), getCommBySynthese(s2)

        # prerequisite for the test:
        assert (
            s1.dataset.acquisition_framework != s2.dataset.acquisition_framework
        )  # prerequisite for the test
        assert comm1 != comm2

        # search metadata in first commune
        response = self.client.post(
            url_for("gn_meta.get_acquisition_frameworks"),
            json={"areas": [[comm1.id_type, comm1.id_area]]},
        )
        ids = [af["id_acquisition_framework"] for af in response.json]
        assert s1.dataset.id_acquisition_framework in ids
        assert s2.dataset.id_acquisition_framework not in ids

        # will test if an other CA is correctly return for an other synthese with diff location
        # get commune for this id synthese
        response = self.client.post(
            url_for("gn_meta.get_acquisition_frameworks"),
            json={"areas": [[comm2.id_type, comm2.id_area]]},
        )
        ids = [af["id_acquisition_framework"] for af in response.json]
        assert s1.dataset.id_acquisition_framework not in ids
        assert s2.dataset.id_acquisition_framework in ids

        # test no response if a commune have observations
        response = self.client.post(
            url_for("gn_meta.get_acquisition_frameworks"),
            json={"areas": [[commune_without_obs.id_type, commune_without_obs.id_area]]},
        )
        resp = response.json
        # will return empty response
        assert len(resp) == 0

    def test_get_acquisition_frameworks_list_excluded_fields(self, users):
        excluded = ["id_acquisition_framework", "id_digitizer"]
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(
            url_for("gn_meta.get_acquisition_frameworks_list"),
            query_string={"excluded_fields": ",".join(excluded), "nested": "true"},
        )

        for field in excluded:
            assert all(field not in list(dic.keys()) for dic in response.json)

    def test_get_acquisition_frameworks_list_excluded_fields_not_nested(self, users):
        excluded = ["id_acquisition_framework", "id_digitizer"]

        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(
            url_for("gn_meta.get_acquisition_frameworks_list"),
            query_string={"excluded_fields": ",".join(excluded), "nested": "true"},
        )

        # Test if a relationship is ignored
        assert all("creator" not in dic for dic in response.json)

    def test_get_acquisition_framework(self, users, acquisition_frameworks):
        af_id = acquisition_frameworks["orphan_af"].id_acquisition_framework
        get_af_url = url_for("gn_meta.get_acquisition_framework", id_acquisition_framework=af_id)

        response = self.client.get(get_af_url)
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["self_user"])
        response = self.client.get(get_af_url)
        assert response.status_code == Forbidden.code

        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(get_af_url)
        assert response.status_code == 200

    def test_get_acquisition_frameworks_search_af_name(
        self, users, acquisition_frameworks, datasets
    ):
        set_logged_user_cookie(self.client, users["admin_user"])
        af1 = acquisition_frameworks["af_1"]
        af2 = acquisition_frameworks["af_2"]
        get_af_url = url_for("gn_meta.get_acquisition_frameworks")

        response = self.client.post(get_af_url, json={"search": af1.acquisition_framework_name})

        af_list = [af["id_acquisition_framework"] for af in response.json]
        assert af1.id_acquisition_framework in af_list
        assert af2.id_acquisition_framework not in af_list

    def test_get_acquisition_frameworks_search_ds_name(
        self, users, acquisition_frameworks, datasets
    ):
        set_logged_user_cookie(self.client, users["admin_user"])
        ds = datasets["belong_af_1"]
        af1 = acquisition_frameworks["af_1"]
        af2 = acquisition_frameworks["af_2"]
        get_af_url = url_for("gn_meta.get_acquisition_frameworks")

        response = self.client.post(get_af_url, json={"search": ds.dataset_name})

        af_list = [af["id_acquisition_framework"] for af in response.json]
        assert af1.id_acquisition_framework in af_list
        assert af2.id_acquisition_framework not in af_list

    def test_get_export_pdf_acquisition_frameworks(self, users, acquisition_frameworks):
        af_id = acquisition_frameworks["own_af"].id_acquisition_framework

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.post(
            url_for(
                "gn_meta.get_export_pdf_acquisition_frameworks", id_acquisition_framework=af_id
            )
        )

        assert response.status_code == 200

    def test_get_export_pdf_acquisition_frameworks_unauthorized(self, acquisition_frameworks):
        af_id = acquisition_frameworks["own_af"].id_acquisition_framework

        response = self.client.post(
            url_for(
                "gn_meta.get_export_pdf_acquisition_frameworks", id_acquisition_framework=af_id
            )
        )

        assert response.status_code == Unauthorized.code

    def test_get_acquisition_framework_stats(
        self, users, acquisition_frameworks, datasets, synthese_data
    ):
        af = synthese_data["obs1"].dataset.acquisition_framework
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(
            url_for(
                "gn_meta.get_acquisition_framework_stats",
                id_acquisition_framework=af.id_acquisition_framework,
            )
        )
        data = response.json

        assert response.status_code == 200
        assert data["nb_dataset"] == len(af.datasets)
        assert data["nb_habitats"] == 0
        obs = [s for s in synthese_data.values() if s.dataset.acquisition_framework == af]
        assert data["nb_observations"] == len(obs)
        # Count of taxa :
        # Loop all the synthese entries, for each synthese
        # For each entry, take the max between count_min and count_max. And if
        # not provided: count_min and/or count_max is 1. Since one entry in
        # synthese is at least 1 taxon
        assert data["nb_taxons"] == sum(max(s.count_min or 1, s.count_max or 1) for s in obs)

    def test_get_acquisition_framework_bbox(self, users, acquisition_frameworks, synthese_data):
        # this AF contains at least 2 obs at different locations
        af = synthese_data["p1_af1"].dataset.acquisition_framework

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(
            url_for(
                "gn_meta.get_acquisition_framework_bbox",
                id_acquisition_framework=af.id_acquisition_framework,
            )
        )
        data = response.json

        assert response.status_code == 200
        assert data["type"] == "Polygon"

    def test_datasets_permissions(self, app, datasets, users):
        ds = datasets["own_dataset"]
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == True
            assert ds.has_instance_permission(2) == True
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["associate_user"])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == False
            assert ds.has_instance_permission(2) == True
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["stranger_user"])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == False
            assert ds.has_instance_permission(2) == False
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            ds_ids = [ds.id_dataset for ds in datasets.values()]
            qs = TDatasets.query.filter(TDatasets.id_dataset.in_(ds_ids))
            assert set(qs.filter_by_scope(0).all()) == set([])
            assert set(qs.filter_by_scope(1).all()) == set(
                [
                    datasets["own_dataset"],
                ]
            )
            assert set(qs.filter_by_scope(2).all()) == set(
                [
                    datasets["own_dataset"],
                    datasets["associate_dataset"],
                ]
            )
            assert set(qs.filter_by_scope(3).all()) == set(datasets.values())

    def test_dataset_is_deletable(self, app, synthese_data, datasets):
        assert (
            datasets["own_dataset"].is_deletable() == False
        )  # there are synthese data attached to this DS
        assert datasets["orphan_dataset"].is_deletable() == True

    def test_delete_dataset(self, app, users, synthese_data, acquisition_frameworks, datasets):
        ds_id = datasets["own_dataset"].id_dataset

        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["noright_user"])

        # The user has no rights on METADATA module
        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Forbidden.code
        assert "METADATA" in response.json["description"]

        set_logged_user_cookie(self.client, users["self_user"])

        # The user has right on METADATA module, but not on this specific DS
        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Forbidden.code
        assert "METADATA" not in response.json["description"]

        set_logged_user_cookie(self.client, users["user"])

        # The DS can not be deleted due to attached rows in synthese
        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Conflict.code

        set_logged_user_cookie(self.client, users["admin_user"])
        ds_id = datasets["orphan_dataset"].id_dataset

        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == 204

    def test_list_datasets(self, users, datasets, acquisition_frameworks):
        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == 200
        expected_ds = {dataset.id_dataset for dataset in datasets.values()}
        resp_ds = {ds["id_dataset"] for ds in response.json}
        assert expected_ds.issubset(resp_ds)
        filtered_response = self.client.get(
            url_for("gn_meta.get_datasets"),
            query_string=MultiDict(
                [
                    (
                        "id_acquisition_framework",
                        acquisition_frameworks["af_1"].id_acquisition_framework,
                    ),
                    (
                        "id_acquisition_framework",
                        acquisition_frameworks["af_2"].id_acquisition_framework,
                    ),
                ]
            ),
        )
        assert filtered_response.status_code == 200
        expected_ds = {
            dataset.id_dataset
            for key, dataset in datasets.items()
            if key in ("belong_af_1", "belong_af_2")
        }
        filtered_ds = {ds["id_dataset"] for ds in filtered_response.json}
        assert expected_ds.issubset(filtered_ds)

    def test_create_dataset(self, users):
        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == BadRequest.code

    def test_get_dataset(self, users, datasets):
        ds = datasets["own_dataset"]

        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["stranger_user"])
        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))
        assert response.status_code == Forbidden.code

        set_logged_user_cookie(self.client, users["associate_user"])
        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))
        assert response.status_code == 200

    def test_update_dataset(self, users, datasets):
        new_name = "thenewname"
        ds = datasets["own_dataset"]
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.patch(
            url_for("gn_meta.update_dataset", id_dataset=ds.id_dataset),
            data=dict(dataset_name=new_name),
        )

        assert response.status_code == 200
        assert response.json.get("dataset_name") == new_name

    def test_update_dataset_not_found(self, users, datasets, unexisted_id):
        set_logged_user_cookie(self.client, users["user"])

        response = self.client.patch(url_for("gn_meta.update_dataset", id_dataset=unexisted_id))

        assert response.status_code == NotFound.code

    def test_update_dataset_forbidden(self, users, datasets):
        ds = datasets["own_dataset"]
        set_logged_user_cookie(self.client, users["stranger_user"])

        response = self.client.patch(url_for("gn_meta.update_dataset", id_dataset=ds.id_dataset))

        assert response.status_code == Forbidden.code

    def test_dataset_pdf_export(self, users, datasets):
        unexisting_id = db.session.query(func.max(TDatasets.id_dataset)).scalar() + 1
        ds = datasets["own_dataset"]

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=ds.id_dataset)
        )
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=unexisting_id)
        )
        assert response.status_code == NotFound.code

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=ds.id_dataset)
        )
        assert response.status_code == Forbidden.code

        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=ds.id_dataset)
        )
        assert response.status_code == 200

    def test_uuid_report(self, users, synthese_data):
        observations_nbr = db.session.query(func.count(Synthese.id_synthese)).scalar()
        if observations_nbr > 1000000:
            pytest.skip("Too much observations in gn_synthese.synthese")

        response = self.client.get(url_for("gn_meta.uuid_report"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["user"])
        response = self.client.get(url_for("gn_meta.uuid_report"))
        assert response.status_code == 200

    @pytest.mark.xfail(reason="FIXME")
    def test_uuid_report_with_dataset_id(
        self, synthese_corr, users, datasets, synthese_data, unexisted_id
    ):
        dataset_id = datasets["own_dataset"].id_dataset

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(
            url_for("gn_meta.uuid_report"), query_string={"id_dataset": dataset_id}
        )
        response_empty = self.client.get(
            url_for("gn_meta.uuid_report"), query_string={"id_dataset": unexisted_id}
        )

        obs = synthese_data.values()
        assert response.status_code == 200
        rows = list(get_csv_from_response(response_empty.data))
        # TODO check result

        assert response_empty.status_code == 200
        rows = list(get_csv_from_response(response_empty.data))
        assert len(rows) == 1  # header only

    def test_sensi_report(self, users, datasets):
        dataset_id = datasets["own_dataset"].id_dataset
        response = self.client.get(
            url_for("gn_meta.sensi_report"), query_string={"id_dataset": dataset_id}
        )
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users["user"])

        response = self.client.get(
            url_for("gn_meta.sensi_report"), query_string={"id_dataset": dataset_id}
        )
        assert response.status_code == 200

    def test_sensi_report_fail(self, users):
        set_logged_user_cookie(self.client, users["admin_user"])

        response = self.client.get(url_for("gn_meta.sensi_report"))
        # BadRequest because for now id_dataset query is required
        assert response.status_code == BadRequest.code

    def test_get_af_from_id(self, af_list):
        id_af = 1

        found_af = get_af_from_id(id_af=id_af, af_list=af_list)

        assert isinstance(found_af, dict)
        assert found_af.get("id_acquisition_framework") == id_af

    def test_get_af_from_id_not_present(self, af_list):
        id_af = 12

        found_af = get_af_from_id(id_af=id_af, af_list=af_list)

        assert found_af is None

    def test_get_af_from_id_none(self):
        id_af = 1
        af_list = [{"test": 2}]

        with pytest.raises(KeyError):
            get_af_from_id(id_af=id_af, af_list=af_list)

    def test__get_create_scope(self, app, users):

        modcode = "METADATA"

        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            create = TDatasets.query._get_create_scope(module_code=modcode)

        usercreate = TDatasets.query._get_create_scope(module_code=modcode, user=users["user"])
        norightcreate = TDatasets.query._get_create_scope(
            module_code=modcode, user=users["noright_user"]
        )
        associatecreate = TDatasets.query._get_create_scope(
            module_code=modcode, user=users["associate_user"]
        )
        admincreate = TDatasets.query._get_create_scope(
            module_code=modcode, user=users["admin_user"]
        )

        assert create == 2
        assert usercreate == 2
        assert norightcreate == 0
        assert associatecreate == 2
        assert admincreate == 3

    def test___str__(self, datasets):
        dataset = datasets["associate_dataset"]

        assert isinstance(dataset.__str__(), str)
        assert dataset.__str__() == dataset.dataset_name

    def test_get_id_dataset(self, datasets):
        dataset = datasets["associate_dataset"]
        uuid_dataset = dataset.unique_dataset_id

        id_dataset = TDatasets.get_id(uuid_dataset)

        assert id_dataset == dataset.id_dataset
        assert TDatasets.get_id(uuid.uuid4()) is None

    def test_get_uuid(self, datasets):
        dataset = datasets["associate_dataset"]
        id_dataset = dataset.id_dataset

        uuid_dataset = TDatasets.get_uuid(id_dataset)

        assert uuid_dataset == dataset.unique_dataset_id
        assert TDatasets.get_uuid(None) is None

    def test_get_id_acquisition_framework(self, acquisition_frameworks):
        af = acquisition_frameworks["associate_af"]

        uuid_af = af.unique_acquisition_framework_id
        id_af = TAcquisitionFramework.get_id(uuid_af)

        assert id_af == af.id_acquisition_framework
        assert TAcquisitionFramework.get_id(uuid.uuid4()) is None

    def test_get_user_af(self, users, acquisition_frameworks):
        # Test to complete
        user = users["user"]

        afquery = TAcquisitionFramework.get_user_af(user=user, only_query=True)
        afuser = TAcquisitionFramework.get_user_af(user=user, only_user=True)
        afdefault = TAcquisitionFramework.get_user_af(user=user)

        assert isinstance(afquery, BaseQuery)
        assert isinstance(afuser, list)
        assert len(afuser) == 1
        assert isinstance(afdefault, list)
        assert len(afdefault) >= 1

    def test_actor(self, users):
        user = users["user"]

        empty = CorDatasetActor(role=None, organism=None)
        roleonly = CorDatasetActor(role=user, organism=None)
        organismonly = CorDatasetActor(role=None, organism=user.organisme)
        complete = CorDatasetActor(role=user, organism=user.organisme)

        assert empty.actor is None
        assert roleonly.actor == user
        assert organismonly.actor == user.organisme
        assert complete.actor == user

    def test_publish_acquisition_framework_no_data(
        self, mocked_publish_mail, users, acquisition_frameworks
    ):
        set_logged_user_cookie(self.client, users["user"])

        af = acquisition_frameworks["own_af"]
        response = self.client.get(
            url_for(
                "gn_meta.publish_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == Conflict.code, response.json
        mocked_publish_mail.assert_not_called()

        af = acquisition_frameworks["orphan_af"]
        response = self.client.get(
            url_for(
                "gn_meta.publish_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == Conflict.code, response.json
        mocked_publish_mail.assert_not_called()

    def test_publish_acquisition_framework_with_data(
        self, mocked_publish_mail, users, acquisition_frameworks, synthese_data
    ):
        set_logged_user_cookie(self.client, users["stranger_user"])
        af = acquisition_frameworks["af_1"]
        response = self.client.get(
            url_for(
                "gn_meta.publish_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == 200, response.json
        mocked_publish_mail.assert_called_once()
