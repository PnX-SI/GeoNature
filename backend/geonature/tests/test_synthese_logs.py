from datetime import datetime, timedelta

import pytest

from flask import url_for
from sqlalchemy.dialects import postgresql
from sqlalchemy import and_
from werkzeug.exceptions import Unauthorized, BadRequest
from werkzeug.datastructures import MultiDict

from geonature.utils.env import db
from geonature.core.gn_synthese.models import SyntheseLogEntry

from pypnusershub.tests.utils import set_logged_user_cookie

from .fixtures import *


@pytest.fixture()
def delete_synthese():
    synthese = Synthese.query.first()
    with db.session.begin_nested():
        db.session.delete(synthese)
    return synthese


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestSyntheseLogs:
    def test_synthese_log_deletion_trigger(self, synthese_data):
        """
        Test delete synthese trigger insert into t_log_synthese
        """

        obs = synthese_data["obs1"]
        assert not db.session.query(
            SyntheseLogEntry.query.filter_by(id_synthese=obs.id_synthese).exists()
        ).scalar()
        with db.session.begin_nested():
            db.session.delete(obs)
        assert db.session.query(
            SyntheseLogEntry.query.filter_by(id_synthese=obs.id_synthese).exists()
        ).scalar()

    def test_list_synthese_log_entries_unauthenticated(self, users):
        url = url_for("gn_synthese.list_synthese_log_entries")

        response = self.client.get(url)
        assert response.status_code == Unauthorized.code

    def test_list_synthese_log_entries(self, users, synthese_data):
        url = url_for("gn_synthese.list_synthese_log_entries")
        set_logged_user_cookie(self.client, users["self_user"])

        created_obs = synthese_data["obs1"]
        updated_obs = synthese_data["obs2"]
        deleted_obs = synthese_data["obs3"]
        with db.session.begin_nested():
            updated_obs.comment_description = "updated"
            # Update trigger set meta_update_date to NOW(), but NOW() always
            # return the start time of a transaction, so meta_update_date is not
            # increased. As a workarround, we decrease meta_create_date (not touched
            # by the trigger) to be sure that meta_create_date < meta_update_date.
            updated_obs.meta_create_date -= timedelta(seconds=1)
            db.session.delete(deleted_obs)

        response = self.client.get(
            url,
            query_string={
                "meta_last_action_date": "gte:{}".format(datetime.now().isoformat()),
                "sort": "meta_last_action_date",
            },
        )
        assert response.status_code == 200, response.json

    def test_list_synthese_log_entries_sort(self, users, synthese_data):
        url = url_for("gn_synthese.list_synthese_log_entries")
        set_logged_user_cookie(self.client, users["self_user"])

        response = self.client.get(url, query_string={"sort": "invalid"})
        assert response.status_code == BadRequest.code, response.json

        response = self.client.get(url, query_string={"sort": "meta_last_action_date"})
        assert response.status_code == 200, response.json

        response = self.client.get(url, query_string={"sort": "meta_last_action_date:asc"})
        assert response.status_code == 200, response.json

        response = self.client.get(url, query_string={"sort": "meta_last_action_date:desc"})
        assert response.status_code == 200, response.json

    def test_list_synthese_log_entries_filter_last_action(self, users, synthese_data):
        url = url_for("gn_synthese.list_synthese_log_entries")
        set_logged_user_cookie(self.client, users["self_user"])

        created_obs = synthese_data["obs1"]
        updated_obs = synthese_data["obs2"]
        deleted_obs = synthese_data["obs3"]
        with db.session.begin_nested():
            updated_obs.comment_description = "updated"
            # see comment above
            updated_obs.meta_create_date -= timedelta(seconds=1)
            db.session.delete(deleted_obs)

        response = self.client.get(
            url,
            query_string={"id_synthese": created_obs.id_synthese, "last_action": "I"},
        )
        assert response.status_code == 200, response.json
        assert len(response.json["items"]) == 1
        (obs1,) = response.json["items"]
        assert obs1["id_synthese"] == created_obs.id_synthese
        assert obs1["last_action"] == "I"

        response = self.client.get(
            url,
            query_string={"id_synthese": created_obs.id_synthese, "last_action": "U"},
        )
        assert response.status_code == 200, response.json
        assert len(response.json["items"]) == 0

        response = self.client.get(
            url,
            query_string={"id_synthese": updated_obs.id_synthese, "last_action": "U"},
        )
        assert response.status_code == 200, response.json
        assert len(response.json["items"]) == 1
        (obs1,) = response.json["items"]
        assert obs1["id_synthese"] == updated_obs.id_synthese
        assert obs1["last_action"] == "U"

        response = self.client.get(
            url,
            query_string={"id_synthese": updated_obs.id_synthese, "last_action": "I"},
        )
        assert response.status_code == 200, response.json
        assert len(response.json["items"]) == 0

        response = self.client.get(
            url,
            query_string={"id_synthese": deleted_obs.id_synthese, "last_action": "D"},
        )
        assert response.status_code == 200, response.json
        assert len(response.json["items"]) == 1
        (obs1,) = response.json["items"]
        assert obs1["id_synthese"] == deleted_obs.id_synthese
        assert obs1["last_action"] == "D"

        response = self.client.get(
            url,
            query_string={"id_synthese": deleted_obs.id_synthese, "last_action": "U"},
        )
        assert response.status_code == 200, response.json
        assert len(response.json["items"]) == 0
