import pytest
import json

from flask import url_for
from sqlalchemy import func
from werkzeug.exceptions import Forbidden, BadRequest, Unauthorized, NotFound

from geonature.utils.env import db
from geonature.core.gn_synthese.models import TReport, BibReportsTypes, Synthese
from geonature.core.notifications.models import Notification, NotificationRule
from geonature.utils.env import db

from .fixtures import *
from .utils import logged_user_headers, set_logged_user_cookie


@pytest.fixture()
def admin_notification_rule(users):
    with db.session.begin_nested():
        new_notification_rule = NotificationRule(
            id_role=users["admin_user"].id_role,
            code_method="DB",
            code_category="OBSERVATION-COMMENT",
            subscribed=True,
        )
        db.session.add(new_notification_rule)
    return new_notification_rule


@pytest.fixture()
def self_user_notification_rule(users):
    with db.session.begin_nested():
        new_notification_rule = NotificationRule(
            id_role=users["self_user"].id_role,
            code_method="DB",
            code_category="OBSERVATION-COMMENT",
            subscribed=True,
        )
        db.session.add(new_notification_rule)
    return new_notification_rule


@pytest.fixture()
def user_notification_rule(users):
    with db.session.begin_nested():
        new_notification_rule = NotificationRule(
            id_role=users["user"].id_role,
            code_method="DB",
            code_category="OBSERVATION-COMMENT",
            subscribed=True,
        )
        db.session.add(new_notification_rule)
    return new_notification_rule


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestReports:
    def test_create_report(self, synthese_data, users):
        url = "gn_synthese.create_report"
        id_synthese = db.session.query(Synthese).first().id_synthese
        data = {"item": id_synthese, "content": "comment 4", "type": "discussion"}
        # TEST - NO AUTHENT
        response = self.client.post(url_for(url), data=data)
        assert response.status_code == 401
        # TEST NO DATA
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.post(url_for(url))
        assert response.status_code == BadRequest.code
        # TEST VALID - ADD DISCUSSION
        response = self.client.post(url_for(url), data=data)
        assert response.status_code == 204
        # TEST VALID - ADD ALERT
        response = self.client.post(
            url_for(url), data={"item": id_synthese, "content": "comment 4", "type": "alert"}
        )
        assert response.status_code == 204
        # TEST REQUIRED KEY MISSING
        data = {"content": "comment 4", "type": "discussion"}
        response = self.client.post(url_for(url), data=data)
        assert response.status_code == BadRequest.code

    def test_delete_report(self, reports_data, users):
        # NO AUTHENT
        url = "gn_synthese.delete_report"
        id_report_ko = db.session.query(func.max(TReport.id_report)).scalar() + 1
        # get id type for discussion type
        discussionIdType = (
            BibReportsTypes.query.filter(BibReportsTypes.type == "discussion").first().id_type
        )
        # get a report with discussion type
        notDiscussionReportId = (
            TReport.query.filter(TReport.id_type != discussionIdType).first().id_report
        )
        # get a report with other type (e.g alert)
        discussionReportId = (
            TReport.query.filter(
                TReport.id_type == discussionIdType, TReport.id_role == users["admin_user"].id_role
            )
            .first()
            .id_report
        )
        # get alert item
        alertIdType = BibReportsTypes.query.filter(BibReportsTypes.type == "alert").first().id_type
        alertReportId = TReport.query.filter(TReport.id_type == alertIdType).first().id_report
        # DELETE WITHOUT AUTH
        response = self.client.delete(url_for(url, id_report=discussionReportId))
        assert response.status_code == 401
        # NOT FOUND
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.delete(url_for(url, id_report=id_report_ko))
        assert response.status_code == NotFound.code
        # SUCCESS - NOT DELETE WITH DISCUSSION
        response = self.client.delete(url_for(url, id_report=discussionReportId))
        assert response.status_code == 204
        assert db.session.query(
            TReport.query.filter_by(id_report=discussionReportId).exists()
        ).scalar()
        # SUCCESS - DELETE ALERT
        response = self.client.delete(url_for(url, id_report=alertReportId))
        assert not db.session.query(
            TReport.query.filter_by(id_report=alertReportId).exists()
        ).scalar()

    def test_list_reports(self, reports_data, synthese_data, users):
        url = "gn_synthese.list_reports"
        # TEST GET WITHOUT REQUIRED ID SYNTHESE
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == NotFound.code
        ids = [s.id_synthese for s in synthese_data.values()]
        # TEST GET BY ID SYNTHESE
        response = self.client.get(
            url_for(url, idSynthese=ids[0], idRole=users["admin_user"].id_role, type="discussion")
        )
        assert response.status_code == 200
        assert len(response.json) == 1
        # TEST NO RESULT
        if len(ids) > 1:
            # not exists because ids[1] is an alert
            response = self.client.get(url_for(url, idSynthese=ids[1], type="discussion"))
            assert response.status_code == 200
            assert len(response.json) == 0
            # TEST TYPE NOT EXISTS
            response = self.client.get(url_for(url, idSynthese=ids[1], type="foo"))
            assert response.status_code == BadRequest.code
            # NO TYPE - TYPE IS NOT REQUIRED
            response = self.client.get(url_for(url, idSynthese=ids[1]))
            assert response.status_code == 200


@pytest.mark.usefixtures("client_class", "notifications_enabled", "temporary_transaction")
class TestReportsNotifications:
    def test_report_notification_on_own_obs(self, synthese_data, users, admin_notification_rule):
        set_logged_user_cookie(self.client, users["user"])
        url = "gn_synthese.create_report"
        synthese = synthese_data["obs1"]
        id_synthese = synthese.id_synthese
        data = {"item": id_synthese, "content": "comment 4", "type": "discussion"}
        response = self.client.post(url_for(url), data=data)

        # Just test that the comment had been sent
        assert response.status_code == 204

        notifications = Notification.query.filter(
            Notification.id_role == users["admin_user"].id_role
        ).all()
        assert len(notifications) > 0
        assert all(synthese.nom_cite in notif.content for notif in notifications)
        assert (
            Notification.query.filter(Notification.id_role == users["user"].id_role).first()
            is None
        )

    def test_report_notification_on_not_own_obs(
        self, synthese_data, users, admin_notification_rule, user_notification_rule
    ):
        set_logged_user_cookie(self.client, users["self_user"])
        url = "gn_synthese.create_report"
        synthese = synthese_data["obs1"]
        id_synthese = synthese.id_synthese
        data = {"item": id_synthese, "content": "comment 4", "type": "discussion"}
        response = self.client.post(url_for(url), data=data)

        # Just test that the comment had been sent
        assert response.status_code == 204

        notifications = Notification.query.filter(
            Notification.id_role.in_(
                (user.id_role for user in (users["user"], users["admin_user"]))
            )
        ).all()

        assert len(notifications) > 0
        assert all(synthese.nom_cite in notif.content for notif in notifications)
        assert (
            Notification.query.filter(Notification.id_role == users["self_user"].id_role).first()
            is None
        )

    def test_report_notification_on_obs_commented(
        self, synthese_data, users, self_user_notification_rule
    ):
        # TODO: refact this to make a function/fixture
        set_logged_user_cookie(self.client, users["self_user"])
        url = "gn_synthese.create_report"
        synthese = synthese_data["obs1"]
        id_synthese = synthese.id_synthese
        data = {"item": id_synthese, "content": "comment 4", "type": "discussion"}
        _ = self.client.post(url_for(url), data=data)
        assert (
            Notification.query.filter(Notification.id_role == users["self_user"].id_role).first()
            is None
        )
        set_logged_user_cookie(self.client, users["user"])
        data = {"item": id_synthese, "content": "comment 5", "type": "discussion"}
        _ = self.client.post(url_for(url), data=data)

        notifications = Notification.query.filter(
            Notification.id_role == users["self_user"].id_role
        ).all()

        assert len(notifications) > 0
