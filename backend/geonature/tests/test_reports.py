import pytest
import json

from flask import url_for
from sqlalchemy import func
from werkzeug.exceptions import Forbidden, BadRequest, Unauthorized, NotFound

from geonature.utils.env import db
from geonature.core.gn_synthese.models import TReport, BibReportsTypes

from .fixtures import reports_data, users, bib_report_types_data
from .utils import logged_user_headers, set_logged_user_cookie

@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestReports:
    def test_create_report(self, users):
        url = "gn_synthese.create_report"        
        data = {"item": 4, "content": "comment 4", "type": "discussion"}
        response = self.client.post(
            url_for(url),
            data=data
        )
        assert response.status_code == 401
        # TEST NO DATA
        set_logged_user_cookie(self.client, users['admin_user'])
        response = self.client.post(
                url_for(url)
        )
        assert response.status_code == BadRequest.code
        # TEST VALID
        response = self.client.post(
                url_for(url),
                data=data
        )
        assert response.status_code == 204
        # TEST REQUIRED KEY MISSING
        data = {"content": "comment 4", "type": "discussion"}
        response = self.client.post(
                url_for(url),
                data = data
        )
        assert response.status_code == BadRequest.code

    def test_delete_report(self, bib_report_types_data, reports_data, users):
        # NO AUTHENT
        url = "gn_synthese.delete_report"
        id_report_ko = db.session.query(func.max(TReport.id_report)).scalar() + 1
        discussionIdType = BibReportsTypes.query.filter(BibReportsTypes.type == "discussion").first().id_type
        notDiscussionReportId = TReport.query.filter(TReport.id_type != discussionIdType).first().id_report
        discussionReportId = TReport.query.filter(TReport.id_type == discussionIdType, TReport.id_role == users['admin_user'].id_role ).first().id_report
        # DELETE WITHOUT AUTH
        response = self.client.delete(url_for(url, id_report=discussionReportId))
        assert response.status_code == 401
        # NOT FOUND
        set_logged_user_cookie(self.client, users['admin_user'])
        response = self.client.delete(url_for(url, id_report=id_report_ko))
        assert response.status_code == NotFound.code
        # SUCCESS - NOT DELETE WITH DISCUSSION
        response = self.client.delete(url_for(url, id_report=discussionReportId))
        assert response.status_code == 204
        assert db.session.query(
            TReport.query.filter_by(id_report=discussionReportId).exists()
        ).scalar()
        # SUCCESS - DELETE IF NOT DISCUSSION
        set_logged_user_cookie(self.client, users['admin_user'])
        response = self.client.delete(url_for(url, id_report=notDiscussionReportId))
        assert not db.session.query(
            TReport.query.filter_by(id_report=notDiscussionReportId).exists()
        ).scalar()

    def test_list_reports(self, reports_data, users):
        url = "gn_synthese.list_reports"
        # TEST GET WITHOUT REQUIRED ID SYNTHESE
        set_logged_user_cookie(self.client, users['admin_user'])
        response = self.client.get(url_for(url))
        assert response.status_code == NotFound.code
        # TEST GET BY ID SYNTHESE
        response = self.client.get(url_for(url, idSynthese=1, idRole=users['admin_user'].id_role, type="discussion"))
        assert response.status_code == 200
        assert len(response.json) == 1
        # TEST NO RESULT
        response = self.client.get(url_for(url, idSynthese=3, type="discussion"))
        assert response.status_code == 200
        assert len(response.json) == 1
        # TEST TYPE NOT EXISTS
        response = self.client.get(url_for(url, idSynthese=3, type="foo"))
        assert response.status_code == BadRequest.code
        # NO TYPE - TYPE IS NOT REQUIRED
        response = self.client.get(url_for(url, idSynthese=3))
        assert response.status_code == 200
