import pytest

from flask import url_for, current_app
from werkzeug.exceptions import Unauthorized, BadRequest

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework

from pypnusershub.db.tools import user_to_token

from .fixtures import acquisition_frameworks, datasets
from .utils import set_logged_user_cookie, logged_user_headers


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGNMeta:
    def test_acquisition_frameworks_permissions(self, app, acquisition_frameworks, datasets, users):
        af = acquisition_frameworks['own_af']
        with app.test_request_context(headers=logged_user_headers(users['user'])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == True
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users['associate_user'])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == False
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users['stranger_user'])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == False
            assert af.has_instance_permission(2) == False
            assert af.has_instance_permission(3) == True

        af = acquisition_frameworks['orphan_af']  # all DS are attached to this AF
        with app.test_request_context(headers=logged_user_headers(users['user'])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            # The AF has no actors, but the AF has DS on which the user is digitizer!
            assert af.has_instance_permission(1) == True
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

            nested = db.session.begin_nested()
            datasets['own_dataset'].acquisition_framework = acquisition_frameworks['own_af']
            # Now, the AF has no DS on which user is digitizer.
            assert af.has_instance_permission(1) == False
            # But the AF has still DS on which user organism is actor.
            assert af.has_instance_permission(2) == True
            nested.rollback()

        with app.test_request_context(headers=logged_user_headers(users['user'])):
            app.preprocess_request()
            af_ids = [ af.id_acquisition_framework for af in acquisition_frameworks.values() ]
            qs = TAcquisitionFramework.query.filter(
                    TAcquisitionFramework.id_acquisition_framework.in_(af_ids)
            )
            assert set(qs.filter_by_scope(0).all()) == set([])
            assert set(qs.filter_by_scope(1).all()) == set([
                acquisition_frameworks['own_af'],
                acquisition_frameworks['orphan_af'],  # through DS
            ])
            assert set(qs.filter_by_scope(2).all()) == set([
                acquisition_frameworks['own_af'],
                acquisition_frameworks['associate_af'],
                acquisition_frameworks['orphan_af'],  # through DS
            ])
            assert set(qs.filter_by_scope(3).all()) == set(acquisition_frameworks.values())

    def test_get_acquisition_frameworks(self, users):
        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users['admin_user'])

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks"))
        assert response.status_code == 200

    def test_get_acquisition_frameworks_list(self, users):
        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks_list"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users['admin_user'])

        response = self.client.get(url_for("gn_meta.get_acquisition_frameworks_list"))
        assert response.status_code == 200

    def test_datasets_permissions(self, app, datasets, users):
        ds = datasets['own_dataset']
        with app.test_request_context(headers=logged_user_headers(users['user'])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == True
            assert ds.has_instance_permission(2) == True
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users['associate_user'])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == False
            assert ds.has_instance_permission(2) == True
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users['stranger_user'])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == False
            assert ds.has_instance_permission(2) == False
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users['user'])):
            app.preprocess_request()
            ds_ids = [ ds.id_dataset for ds in datasets.values() ]
            qs = TDatasets.query.filter(
                    TDatasets.id_dataset.in_(ds_ids)
            )
            assert set(qs.filter_by_scope(0).all()) == set([])
            assert set(qs.filter_by_scope(1).all()) == set([
                datasets['own_dataset'],
            ])
            assert set(qs.filter_by_scope(2).all()) == set([
                datasets['own_dataset'],
                datasets['associate_dataset'],
            ])
            assert set(qs.filter_by_scope(3).all()) == set(datasets.values())

    def test_get_datasets(self, users):
        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users['admin_user'])

        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == 200

    def test_create_dataset(self, users):
        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == Unauthorized.code

        set_logged_user_cookie(self.client, users['admin_user'])

        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == BadRequest.code
