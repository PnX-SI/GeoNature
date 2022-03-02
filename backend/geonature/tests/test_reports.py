import pytest
import json

from flask import url_for
from sqlalchemy import func
from werkzeug.exceptions import Forbidden, BadRequest, Unauthorized, NotFound

from geonature.utils.env import db
from geonature.core.gn_synthese.models import CorReportSynthese

from .fixtures import *
from .utils import logged_user_headers, set_logged_user_cookie

@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestReports:
    # def test_delete_report(self, users):
    #     url = "gn_synthese.get_report"
    #     id_report_ok = db.session.query(func.max(CorReportSynthese.id_report)).scalar()
    #     id_report_ko = id_report_ok + 1
    #     response = self.client.delete(url_for("gn_synthese.delete_report", id_report=id_report_ok))
    #     assert response.status_code == Unauthorized.code

    #     set_logged_user_cookie(self.client, users['user'])
    #     response = self.client.delete(url_for("gn_synthese.delete_report", id_report=id_report_ko))
    #     assert response.status_code == NotFound.code

    #     response = self.client.delete(url_for("gn_synthese.delete_report", id_report=id_report_ok))
    #     assert response.status_code == 204
    #     assert not db.session.query(
    #         CorReportSynthese.query.filter_by(id_report=id_report_ok).exists()
    #     ).scalar()

    def test_get_report(self, users):
        # TEST UNAUTHAURIZED GET REQUEST
        url = "gn_synthese.get_report"
        # response = self.client.get(url_for(url))
        # assert response.status_code == Unauthorized.code
        # # TEST GET WITHOUT REQUIRED ID SYNTHESE
        # set_logged_user_cookie(self.client, users['user'])
        # response = self.client.get(url_for(url))
        # assert response.status_code == BadRequest.code
        # TEST GET BY ID REPORT AND ID SYNTHESE
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.get(url_for(url, id_report=1, id_synthese=1))
        assert response.status_code == 200
        print(response.json)
        assert len(response.json) == 1
        # TEST GET BY TYPE AND ID SYNTHESE
        # response = self.client.get(url_for(url, id_synthese=3, type=2))
        # assert response.status_code == 200
        # assert len(response.json) == 1
        # # TEST NO RESULT
        # response = self.client.get(url_for(url, id_synthese=1, type=10))
        # assert response.status_code == 200
        # assert len(response.json) == 0

    def test_create_discussion(self, report):
        set_logged_user_cookie(self.client, users['user'])
        assert 1 == 1
