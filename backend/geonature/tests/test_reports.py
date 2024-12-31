import json

from datetime import datetime
import pytest
from flask import url_for
from sqlalchemy import func, select, exists
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
        url = "gn_synthese.reports.create_report"
        id_synthese = db.session.scalars(select(Synthese).limit(1)).first().id_synthese
        data = {"item": id_synthese, "content": "comment 4", "type": "discussion"}
        # TEST - NO AUTHENT
        response = self.client.post(url_for(url), data=data)

        assert response.status_code == 401
        # TEST NO DATA
        set_logged_user(self.client, users["admin_user"])
        response = self.client.post(url_for(url), data=None)
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
        url = "gn_synthese.reports.delete_report"
        id_report_ko = db.session.execute(select(func.max(TReport.id_report))).scalar_one() + 1
        # get id type for discussion type
        discussionIdType = (
            db.session.scalars(
                select(BibReportsTypes).where(BibReportsTypes.type == "discussion").limit(1)
            )
            .first()
            .id_type
        )
        # get a report with discussion type
        notDiscussionReportId = (
            db.session.scalars(select(TReport).where(TReport.id_type != discussionIdType))
            .first()
            .id_report
        )
        # get a report with other type (e.g alert)
        discussionReportId = (
            db.session.scalars(
                select(TReport)
                .where(
                    TReport.id_type == discussionIdType,
                    TReport.id_role == users["admin_user"].id_role,
                )
                .limit(1)
            )
            .first()
            .id_report
        )
        # get alert item
        alertIdType = (
            db.session.scalars(
                select(BibReportsTypes).where(BibReportsTypes.type == "alert").limit(1)
            )
            .first()
            .id_type
        )
        alertReportId = (
            db.session.scalars(select(TReport).where(TReport.id_type == alertIdType))
            .first()
            .id_report
        )
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
        assert db.session.scalar(exists().where(TReport.id_report == discussionReportId).select())

        # SUCCESS - DELETE ALERT
        response = self.client.delete(url_for(url, id_report=alertReportId))
        assert not db.session.scalar(exists().where(TReport.id_report == alertReportId).select())

    def test_list_reports(self, reports_data, synthese_data, users):
        url = "gn_synthese.reports.list_reports"
        ids = [s.id_synthese for s in synthese_data.values()]

        # User: noright_user
        set_logged_user(self.client, users["noright_user"])
        response = self.client.get(
            url_for(
                url, id_synthese=ids[0], idRole=users["noright_user"].id_role, type="discussion"
            )
        )
        assert response.status_code == Forbidden.code

        # User: admin_user
        set_logged_user(self.client, users["admin_user"])

        # TEST GET BY ID SYNTHESE
        response = self.client.get(
            url_for(url, id_synthese=ids[0], idRole=users["admin_user"].id_role, type="discussion")
        )
        assert response.status_code == 200
        assert len(response.json) == 1

        # TEST INVALID - TYPE DOES NOT EXISTS
        response = self.client.get(
            url_for(
                url,
                id_synthese=ids[0],
                idRole=users["admin_user"].id_role,
                type="UNKNOW-REPORT-TYPE",
            )
        )
        assert response.status_code == 400
        assert response.json["description"] == "This report type does not exist"

        # TEST VALID - ADD PIN
        response = self.client.get(
            url_for(url, id_synthese=ids[0], idRole=users["admin_user"].id_role, type="pin")
        )
        assert response.status_code == 200
        assert len(response.json) == 0
        # TEST NO RESULT
        if len(ids) > 1:
            # not exists because ids[1] is an alert
            response = self.client.get(url_for(url, id_synthese=ids[1], type="discussion"))
            assert response.status_code == 200
            assert len(response.json) == 0
            # TEST TYPE NOT EXISTS
            response = self.client.get(url_for(url, id_synthese=ids[1], type="foo"))
            assert response.status_code == BadRequest.code
            # NO TYPE - TYPE IS NOT REQUIRED
            response = self.client.get(url_for(url, id_synthese=ids[1]))
            assert response.status_code == 200

    @pytest.mark.parametrize(
        "sort,orderby,expected_error",
        [
            ("asc", "creation_date", False),
            ("desc", "creation_date", False),
            ("asc", "user.nom_complet", False),
            ("asc", "content", False),
            ("asc", "nom_cite", True),
        ],
    )
    def test_list_all_reports(
        self, sort, orderby, expected_error, reports_data, synthese_data, users
    ):
        url = "gn_synthese.reports.list_all_reports"
        set_logged_user(self.client, users["admin_user"])
        # TEST GET WITHOUT REQUIRED ID SYNTHESE
        response = self.client.get(url_for(url, type="discussion"))
        assert response.status_code == 200
        assert "items" in response.json
        assert isinstance(response.json["items"], list)
        assert len(response.json["items"]) >= 0

        # TEST WITH MY_REPORTS TRUE
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for(url, type="discussion", my_reports="true"))
        assert response.status_code == 200
        items = response.json["items"]
        expected_ids = [
            10001,  # User is observer
            10003,  # User is report owner
            10004,  # User is report owner
        ]
        # Missing cases:
        # - User is digitiser
        # - User has post a report in the same synthese
        # They involve adding data to the `synthese_data` fixture, which could cause other tests to fail.
        item_ids = [item["id_report"] for item in items]
        item_ids.sort()
        assert expected_ids == item_ids

        # Test undefined type
        response = self.client.get(url_for(url, type="UNKNOW-REPORT-TYPE", my_reports="true"))
        assert response.status_code == 400
        assert response.json["description"] == "This report type does not exist"

        # TEST SORT AND PAGINATION
        if expected_error:
            # Test with invalid orderby
            response = self.client.get(url_for(url, orderby=orderby, sort=sort))
            assert response.status_code == BadRequest.code
        else:
            response = self.client.get(url_for(url, orderby=orderby, sort=sort, page=1, per_page=5))
            assert response.status_code == 200
            assert "items" in response.json
            assert len(response.json["items"]) <= 5

            # Verify sorting
            items = response.json["items"]
            reverse_sort = sort == "desc"
            if orderby == "creation_date":
                dates = [
                    datetime.strptime(item["creation_date"], "%a, %d %b %Y %H:%M:%S %Z")
                    for item in items
                ]
                assert dates == sorted(dates, reverse=reverse_sort)
            elif orderby == "content":
                contents = [item["content"] for item in items]
                assert contents == sorted(contents, reverse=reverse_sort, key=str.casefold)
            elif orderby == "user.nom_complet":
                names = [item["user"]["nom_complet"] for item in items]
                assert names == sorted(names, reverse=reverse_sort)


@pytest.mark.usefixtures("client_class", "notifications_enabled", "temporary_transaction")
class TestReportsNotifications:
    def post_comment(self, synthese, user):
        """Post a comment on a synthese row as a user"""
        set_logged_user(self.client, user)
        url = "gn_synthese.reports.create_report"
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
        notifications = db.session.scalars(
            select(Notification).where(Notification.id_role.in_(id_roles))
        ).all()

        assert {notification.id_role for notification in notifications} == id_roles
        assert all(synthese.nom_cite in notif.content for notif in notifications)
        # Check that user is not notified since he posted the comment
        assert (
            db.session.scalars(
                select(Notification).where(Notification.id_role == users["user"].id_role).limit(1)
            ).first()
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
        notifications = db.session.scalars(
            select(Notification).where(Notification.id_role.in_(id_roles))
        ).all()

        assert {notification.id_role for notification in notifications} == id_roles
        assert all(synthese.nom_cite in notif.content for notif in notifications)
        # But check also that associate_user is not notified for the comment he posted
        assert (
            db.session.scalars(
                select(Notification)
                .where(Notification.id_role == users["associate_user"].id_role)
                .limit(1)
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
            db.session.scalars(
                select(Notification)
                .where(Notification.id_role == users["associate_user"].id_role)
                .limit(1)
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
        notifications = db.session.scalars(
            select(Notification).where(Notification.id_role.in_(user_roles))
        ).all()

        assert {notification.id_role for notification in notifications} == user_roles
