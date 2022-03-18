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
    def test_delete_report(self, users):
        # NO AUTHENT
        url = "gn_synthese.delete_report"
        id_report_ok = db.session.query(func.max(CorReportSynthese.id_report)).scalar()
        id_report_ko = id_report_ok + 1
        response = self.client.delete(url_for(url, id_report=id_report_ok))
        assert response.status_code == BadRequest.code
        # NOT FOUND
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.delete(url_for("gn_synthese.delete_report", id_report=id_report_ko))
        assert response.status_code == NotFound.code
        
        # SUCCESS
        response = self.client.delete(url_for("gn_synthese.delete_report", id_report=id_report_ok))
        assert response.status_code == 204
        assert not db.session.query(
            CorReportSynthese.query.filter_by(id_report=id_report_ok).exists()
        ).scalar()

    def test_get_report(self, users):
        url = "gn_synthese.get_report"
        # TEST GET WITHOUT REQUIRED ID SYNTHESE
        set_logged_user_cookie(self.client, users['user'])
        response = self.client.get(url_for(url))
        assert response.status_code == BadRequest.code
        # TEST GET BY ID SYNTHESE
        response = self.client.get(url_for(url, idSynthese=2))
        assert response.status_code == 200
        # TEST NO RESULT
        response = self.client.get(url_for(url, idSynthese=2, type=10))
        assert response.status_code == 200

    def test_create_report(self, report):
        set_logged_user_cookie(self.client, users['user'])
        assert 1 == 1
