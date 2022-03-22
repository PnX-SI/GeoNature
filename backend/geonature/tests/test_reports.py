import pytest
import json

from flask import url_for
from sqlalchemy import func
from werkzeug.exceptions import Forbidden, BadRequest, Unauthorized, NotFound

from geonature.utils.env import db
from geonature.core.gn_synthese.models import TReport

from .fixtures import reports_data, users
from .utils import logged_user_headers, set_logged_user_cookie

@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestReports:
    def test_create_report(self, users):
        url = "gn_synthese.create_report"        
        data = {"item": 4, "content": "comment 4", "type": 1}
        response = self.client.post(
            url_for(url),
            data=data
        )
        assert response.status_code == Forbidden.code
        # TEST NO DATA
        response = self.client.post(
                url_for(url)
        )
        assert response.status_code == BadRequest.code
        # TEST AUTH USER
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.post(
                url_for(url),
                data=data
        )
        assert response.status_code == 204
        # TEST REQUIRED KEY MISSING
        data = {"content": "comment 4", "type": 1}
        response = self.client.post(
                url_for(url),
                data = data
        )
        assert response.status_code == BadRequest.code

    def test_delete_report(self, reports_data, users):
        # NO AUTHENT
        url = "gn_synthese.delete_report"
        id_report_ok = db.session.query(func.max(TReport.id_report)).scalar()
        # DELETE WITHOUT AUTH
        response = self.client.delete(url_for(url, id_report=id_report_ok))
        assert response.status_code == BadRequest.code
        # NOT FOUND
        set_logged_user_cookie(self.client, users['user'])
        id_report_ko = id_report_ok + 1
        response = self.client.delete(url_for("gn_synthese.delete_report", id_report=id_report_ko))
        assert response.status_code == NotFound.code
        # SUCCESS
        response = self.client.delete(url_for("gn_synthese.delete_report", id_report=id_report_ok))
        assert response.status_code == 204
        assert not db.session.query(
            TReport.query.filter_by(id_report=id_report_ok).exists()
        ).scalar()

    def test_list_reports(self, reports_data, users):
        url = "gn_synthese.get_report"
        # TEST GET WITHOUT REQUIRED ID SYNTHESE
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.get(url_for(url))
        assert response.status_code == BadRequest.code
        # TEST GET BY ID SYNTHESE
        response = self.client.get(url_for(url, idSynthese=1, idRole=users['user'].id_role))
        assert response.status_code == 200
        assert len(response.json['results']) == 1
        # TEST NO RESULT
        response = self.client.get(url_for(url, idSynthese=3, type=1))
        assert response.status_code == 200
        assert len(response.json['results']) == 1
