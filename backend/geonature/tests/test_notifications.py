import pytest
import logging
import json
import datetime

from flask import url_for, jsonify, current_app
from werkzeug.exceptions import Forbidden, Unauthorized, BadRequest

from geonature.utils.env import db
from geonature.core.notifications.models import (
    Notification,
    NotificationCategory,
    NotificationMethod,
    NotificationRule,
    NotificationTemplate,
)
from geonature.core.notifications import utils

from .utils import set_logged_user_cookie

log = logging.getLogger()


@pytest.fixture()
def notification_data(users):
    with db.session.begin_nested():
        new_notification = Notification(
            id_role=users["admin_user"].id_role,
            title="title1",
            content="content1",
            url="https://geonature.fr/",
            creation_date=datetime.datetime.now(),
            code_status="UNREAD",
        )
        db.session.add(new_notification)
    return new_notification


@pytest.fixture()
def rule_category():
    with db.session.begin_nested():
        rule_category = NotificationCategory(
            code="Code_CATEGORY", label="Label_Categorie", description="description_categorie"
        )
        db.session.add(rule_category)
    return rule_category


@pytest.fixture()
def rule_category_1():
    rule_category_1 = NotificationCategory(
        code="Code_CATEGORY_1", label="Label_Categorie_1", description="description_categorie_1"
    )
    db.session.add(rule_category_1)
    return rule_category_1


@pytest.fixture()
def rule_method():
    with db.session.begin_nested():
        rule_method = NotificationMethod(
            code="Code_METHOD", label="Label_Method", description="description_method"
        )
        db.session.add(rule_method)
    return rule_method


@pytest.fixture()
def rule_template(rule_category, rule_method):
    with db.session.begin_nested():
        new_template = NotificationTemplate(
            code_category=rule_category.code,
            code_method=rule_method.code,
            content="{% if test == 'ok' %} message {% endif %}",
        )
        db.session.add(new_template)
    return new_template


@pytest.fixture()
def notification_rule(users, rule_method, rule_category):
    with db.session.begin_nested():
        new_notification_rule = NotificationRule(
            id_role=users["admin_user"].id_role,
            code_method=rule_method.code,
            code_category=rule_category.code,
        )
        db.session.add(new_notification_rule)
    return new_notification_rule


@pytest.fixture()
def notifications_enabled(monkeypatch):
    monkeypatch.setitem(current_app.config["NOTIFICATION"], "ENABLED", True)


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestNotification:
    def test_list_database_notification(self, users, notification_data):
        # Init data for test
        url = "notifications.list_database_notification"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER WITHOUT NOTIFICATION
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 0

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 1

    def test_count_notification(self, users, notification_data):
        # Init data for test
        url = "notifications.count_notification"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER NO DATA
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 1

    def test_update_notification(self, users, notification_data):
        # Init data for test
        url = "notifications.update_notification"
        log.debug(
            "Url d'appel %s", url_for(url, id_notification=notification_data.id_notification)
        )

        response = self.client.post(
            url_for(url, id_notification=notification_data.id_notification)
        )
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER BUT NOTIFICATION DOES NOT EXIST FOR THIS USER
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(
            url_for(url, id_notification=notification_data.id_notification)
        )
        assert response.status_code == Forbidden.code

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.post(
            url_for(url, id_notification=notification_data.id_notification)
        )
        assert response.status_code == 200

    def test_delete_all_notifications(self, users, notification_data):
        # Init data for test
        url = "notifications.delete_all_notifications"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.delete(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER WITHOUT NOTIFICATION
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0
        assert db.session.query(
            Notification.query.filter_by(
                id_notification=notification_data.id_notification
            ).exists()
        ).scalar()

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 1
        assert not db.session.query(
            Notification.query.filter_by(
                id_notification=notification_data.id_notification
            ).exists()
        ).scalar()

    def test_list_notification_rules(self, users, notification_rule):
        # Init data for test
        url = "notifications.list_notification_rules"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 0

        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 1

    def test_create_rule_ko(self, users, rule_method, rule_category):
        # Init data for test
        url = "notifications.create_rule"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.put(url_for(url), content_type="application/json")
        assert response.status_code == 401

        # TEST CONNECTED USER WITHOUT DATA
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.put(url_for(url))
        assert response.status_code == 400

        # TEST CONNECTED USER WITH DATA BUT WRONG KEY
        set_logged_user_cookie(self.client, users["admin_user"])
        data = {"method": rule_method.code, "categorie": rule_category.code}
        response = self.client.put(url_for(url), json=data, content_type="application/json")
        assert response.status_code == BadRequest.code

        # TEST CONNECTED USER WITH DATA BUT WRONG VALUE
        set_logged_user_cookie(self.client, users["admin_user"])
        data = {"code_method": 1, "code_category": rule_category.code}
        response = self.client.put(url_for(url), json=data, content_type="application/json")
        assert response.status_code == BadRequest.code

    def test_create_rule_ok(self, users, rule_method, rule_category):

        url = "notifications.create_rule"
        log.debug("Url d'appel %s", url_for(url))

        # TEST SUCCESSFULL RULE CREATION
        set_logged_user_cookie(self.client, users["user"])
        data = {"code_method": rule_method.code, "code_category": rule_category.code}
        response = self.client.put(url_for(url), json=data, content_type="application/json")
        assert response.status_code == 200, response.data

        newRule = response.get_json()
        assert newRule.get("code_method") == rule_method.code
        assert newRule.get("code_category") == rule_category.code
        assert newRule.get("id_role") == users["user"].id_role

    def test_delete_all_rules(self, users, notification_rule):
        # Init data for test
        url = "notifications.delete_all_rules"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.delete(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER WITHOUT RULE
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0
        assert db.session.query(
            NotificationRule.query.filter_by(
                id=notification_rule.id,
            ).exists()
        ).scalar()

        # TEST CONNECTED USER WITH RULE
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 1
        assert not db.session.query(
            NotificationRule.query.filter_by(
                id=notification_rule.id,
            ).exists()
        ).scalar()

    def test_delete_rule(self, users, notification_rule):
        # Init data for test
        url = "notifications.delete_rule"
        log.debug("Url d'appel %s", url_for(url, id=1))

        # TEST NO USER
        response = self.client.delete(url_for(url, id=1))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER WITHOUT RULE
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(url_for(url, id=notification_rule.id))
        assert response.status_code == Forbidden.code
        assert db.session.query(
            NotificationRule.query.filter_by(
                id=notification_rule.id,
            ).exists()
        ).scalar()

        # TEST CONNECTED USER WITH RULE
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.delete(url_for(url, id=notification_rule.id))
        assert response.status_code == 204
        assert not db.session.query(
            NotificationRule.query.filter_by(
                id=notification_rule.id,
            ).exists()
        ).scalar()

    def test_list_methods(self, users, rule_method):

        # Init data for test
        url = "notifications.list_notification_methods"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) > 0

    def test_list_notification_categories(self, users):

        # Init data for test
        url = "notifications.list_notification_categories"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) > 0

    # test only notification insertion in database whitout dispatch
    def test_send_db_notification(self, users):

        result = utils.send_db_notification(
            users["admin_user"], "test creation", "no templating", "https://geonature.fr"
        )
        assert result is not None
        assert result.user == users["admin_user"]
        assert result.code_status == "UNREAD"
        assert result.content == "no templating"

    def test_dispatch_notifications_database_with_like(
        self, users, rule_category, rule_category_1, rule_template, notifications_enabled
    ):
        role = users["user"]

        with db.session.begin_nested():
            # Create rule for further dispatching
            new_rule = NotificationRule(
                id_role=role.id_role,
                code_method="DB",
                code_category=rule_category_1.code,
            )
            db.session.add(new_rule)

        title = "test creation"
        content = "no templating"
        url = "https://geonature.fr"
        context = {}

        assert not db.session.query(
            Notification.query.filter_by(
                id_role=role.id_role,
            ).exists()
        ).scalar()

        # test create database notification
        utils.dispatch_notifications(
            ["Code_CATEGORY%"],
            [users["user"].id_role],
            title,
            url,
            content=content,
            context=context,
        )

        notif = Notification.query.filter_by(id_role=role.id_role).one()
        assert notif.title == title
        assert notif.content == content
        assert notif.url == url
        assert notif.code_status == "UNREAD"

    def test_dispatch_notifications_database_with_like(
        self, users, rule_category, rule_category_1, rule_template, notifications_enabled
    ):
        role = users["user"]

        with db.session.begin_nested():
            # Create rule for further dispatching
            new_rule = NotificationRule(
                id_role=role.id_role,
                code_method="DB",
                code_category=rule_category_1.code,
            )
            db.session.add(new_rule)

        title = "test creation"
        content = "no templating"
        url = "https://geonature.fr"
        context = {}

        assert not db.session.query(
            Notification.query.filter_by(
                id_role=role.id_role,
            ).exists()
        ).scalar()

        # test create database notification
        utils.dispatch_notifications(
            ["Code_CATEGORY%"],
            [users["user"].id_role],
            title,
            url,
            content=content,
            context=context,
        )

        notif = Notification.query.filter_by(id_role=role.id_role).one()
        assert notif.title == title
        assert notif.content == content
        assert notif.url == url
        assert notif.code_status == "UNREAD"
