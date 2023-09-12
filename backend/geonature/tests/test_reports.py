import json

import pytest
from flask import url_for
from sqlalchemy import func
from werkzeug.exceptions import BadRequest, Forbidden, NotFound, Unauthorized

from geonature.core.gn_synthese.models import BibReportsTypes, Synthese, TReport
from geonature.core.notifications.models import Notification, NotificationRule
from geonature.utils.env import db

from .fixtures import *
from .utils import logged_user_headers, set_logged_user


def add_notification_rule(user):
    with db.session.begin_nested():
        new_notification_rule = NotificationRule(
            id_role=user.id_role,
            code_method="DB",
            code_category="OBSERVATION-COMMENT",
            subscribed=True,
        )
        db.session.add(new_notification_rule)
    return new_notification_rule


@pytest.fixture()
def admin_notification_rule(users):
    return add_notification_rule(users["admin_user"])


@pytest.fixture()
def associate_user_notification_rule(users):
    return add_notification_rule(users["associate_user"])


@pytest.fixture()
def user_notification_rule(users):
    return add_notification_rule(users["user"])


@pytest.fixture()
def self_user_notification_rule(users):
    return add_notification_rule(users["self_user"])


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
        set_logged_user(self.client, users["admin_user"])
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
        # TEST VALID - ADD PIN
        response = self.client.post(
            url_for(url), data={"item": id_synthese, "content": "", "type": "pin"}
        )
        assert response.status_code == 204
        # TEST INVALID - ADD PIN
        response = self.client.post(
            url_for(url), data={"item": id_synthese, "content": "", "type": "pin"}
        )
        assert response.status_code == 409

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
        set_logged_user(self.client, users["admin_user"])
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
        set_logged_user(self.client, users["admin_user"])
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
    def post_comment(self, synthese, user):
        """Post a comment on a synthese row as a user"""
        set_logged_user(self.client, user)
        url = "gn_synthese.create_report"
        id_synthese = synthese.id_synthese
        data = {"item": id_synthese, "content": "comment 4", "type": "discussion"}
        return self.client.post(url_for(url), data=data)

    def test_report_notification_on_own_obs(
        self,
        synthese_data,
        users,
        admin_notification_rule,
        user_notification_rule,
        self_user_notification_rule,
    ):
        """
        Given:
        - user and admin_user are observer of a synthese data
        - self_user is the digitiser
        When
        - user adds a comment
        Then
        - admin_user and self_user receives a notification
        - user does not receive a notification since user wrote a comment
        """
        synthese = synthese_data["obs1"]

        response = self.post_comment(synthese=synthese, user=users["user"])

        # Just test that the comment had been sent
        assert response.status_code == 204

        # Check that admin_user (observer) and self_user (digitiser) are notified
        id_roles = {user.id_role for user in (users["admin_user"], users["self_user"])}
        notifications = Notification.query.filter(Notification.id_role.in_(id_roles)).all()

        assert {notification.id_role for notification in notifications} == id_roles
        assert all(synthese.nom_cite in notif.content for notif in notifications)
        # Check that user is not notified since he posted the comment
        assert (
            Notification.query.filter(Notification.id_role == users["user"].id_role).first()
            is None
        )

    def test_report_notification_on_not_own_obs(
        self,
        synthese_data,
        users,
        admin_notification_rule,
        user_notification_rule,
        self_user_notification_rule,
        associate_user_notification_rule,
    ):
        """
        Given:
        - user and admin_user are observer of a synthese data
        - self_user is the digitiser
        When
        - associate_user adds a comment
        Then
        - user, admin_user and self_user receives a notification
        - associate_user does not receive a notification since associate_user wrote a comment
        """

        synthese = synthese_data["obs1"]
        response = self.post_comment(synthese=synthese, user=users["associate_user"])

        # Just test that the comment had been sent
        assert response.status_code == 204

        # Check that user, admin_user (observers) and self_user (digitiser) are notified
        id_roles = {
            user.id_role for user in (users["user"], users["admin_user"], users["self_user"])
        }
        notifications = Notification.query.filter(Notification.id_role.in_(id_roles)).all()

        assert {notification.id_role for notification in notifications} == id_roles
        assert all(synthese.nom_cite in notif.content for notif in notifications)
        # But check also that associate_user is not notified for the comment he posted
        assert (
            Notification.query.filter(
                Notification.id_role == users["associate_user"].id_role
            ).first()
            is None
        )

    def test_report_notification_on_obs_commented(
        self,
        synthese_data,
        users,
        associate_user_notification_rule,
        admin_notification_rule,
        user_notification_rule,
        self_user_notification_rule,
    ):
        """
        Given:
        - user and admin_user are observer of a synthese data
        - self_user is the digitiser
        When
        - associate_user adds a comment
        - admin_user adds a comment afterwards
        Then
        - after the first comment is posted, associate_user does not receive a notification
        - user, admin_user and self_user receives a notification since associate_user commented
        - associate_user receives a notification since admin_user commented on the observation
        associate_user commented on
        """
        synthese = synthese_data["obs1"]

        # Post first comment so that associate_user can be notified on future comments
        _ = self.post_comment(synthese=synthese, user=users["associate_user"])
        # Check that associate_user is not notified (just in case)
        assert (
            Notification.query.filter(
                Notification.id_role == users["associate_user"].id_role
            ).first()
            is None
        )
        # Post second comment to notify associate_user on future comments
        _ = self.post_comment(synthese=synthese, user=users["admin_user"])

        # Check that all these roles are notified. Careful, even admin_user is notified
        # because of the first comment
        user_roles = {
            user.id_role
            for user in (
                users["associate_user"],
                users["admin_user"],
                users["self_user"],
                users["user"],
            )
        }
        notifications = Notification.query.filter(Notification.id_role.in_(user_roles)).all()

        assert {notification.id_role for notification in notifications} == user_roles
