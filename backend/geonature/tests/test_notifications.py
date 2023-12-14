import pytest
import logging
import json
import datetime
from unittest.mock import patch

from flask import url_for
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
from geonature.tests.fixtures import celery_eager, notifications_enabled


from sqlalchemy import select, exists, delete
from .utils import set_logged_user

log = logging.getLogger()


@pytest.fixture(scope="class")
def clear_default_notification_rules():
    db.session.execute(
        delete(NotificationRule).where(NotificationRule.id_role.is_(None))
    )  # select(NotificationRule).where(NotificationRule.id_role.is_(None)).delete()


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
def rule_mail_template(rule_category):
    with db.session.begin_nested():
        new_template = NotificationTemplate(
            code_category=rule_category.code,
            code_method="EMAIL",
            content="{% if role.identifiant == 'admin_user' %}{{ message }}{% endif %}",
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
            subscribed=True,
        )
        db.session.add(new_notification_rule)
    return new_notification_rule


@pytest.mark.usefixtures(
    "client_class",
    "temporary_transaction",
    "notifications_enabled",
    "clear_default_notification_rules",
)
class TestNotification:
    def test_list_database_notification(self, users, notification_data):
        # Init data for test
        url = "notifications.list_database_notification"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER WITHOUT NOTIFICATION
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 0

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user(self.client, users["admin_user"])
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
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

        # TEST CONNECTED USER
        set_logged_user(self.client, users["admin_user"])
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
        set_logged_user(self.client, users["user"])
        response = self.client.post(
            url_for(url, id_notification=notification_data.id_notification)
        )
        assert response.status_code == Forbidden.code

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user(self.client, users["admin_user"])
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
        set_logged_user(self.client, users["user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0
        assert db.session.scalar(
            exists()
            .where(Notification.id_notification == notification_data.id_notification)
            .select()
        )

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user(self.client, users["admin_user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 1
        assert not db.session.scalar(
            exists()
            .where(Notification.id_notification == notification_data.id_notification)
            .select()
        )

    def test_list_notification_rules(self, users, notification_rule):
        # Init data for test
        url = "notifications.list_notification_rules"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 0

        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 1

    def test_update_rule(self, users, rule_method, rule_category):
        role = users["user"]
        subscribe_url = url_for(
            "notifications.update_rule",
            code_method=rule_method.code,
            code_category=rule_category.code,
            subscribe=True,
        )
        unsubscribe_url = url_for(
            "notifications.update_rule",
            code_method=rule_method.code,
            code_category=rule_category.code,
            subscribe=False,
        )

        assert not db.session.scalar(
            exists()
            .where(
                NotificationRule.id_role == role.id_role,
                NotificationRule.method == rule_method,
                NotificationRule.category == rule_category,
            )
            .select()
        )

        response = self.client.post(subscribe_url)
        assert response.status_code == Unauthorized.code, response.data

        set_logged_user(self.client, role)

        response = self.client.post(subscribe_url)
        assert response.status_code == 200, response.data

        rule = db.session.execute(
            select(NotificationRule).filter_by(
                id_role=role.id_role,
                method=rule_method,
                category=rule_category,
            )
        ).scalar_one()
        assert rule.subscribed

        response = self.client.post(unsubscribe_url)
        assert response.status_code == 200, response.data

        rule = db.session.execute(
            select(NotificationRule).filter_by(
                id_role=role.id_role,
                method=rule_method,
                category=rule_category,
            )
        ).scalar_one()
        assert not rule.subscribed

    def test_delete_all_rules(self, users, notification_rule):
        # Init data for test
        url = "notifications.delete_all_rules"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.delete(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER WITHOUT RULE
        set_logged_user(self.client, users["user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0
        assert db.session.scalar(
            exists()
            .where(
                NotificationRule.id == notification_rule.id,
            )
            .select()
        )

        # TEST CONNECTED USER WITH RULE
        set_logged_user(self.client, users["admin_user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 1
        assert not db.session.scalar(
            exists()
            .where(
                NotificationRule.id == notification_rule.id,
            )
            .select()
        )

    def test_list_methods(self, users, rule_method):
        # Init data for test
        url = "notifications.list_notification_methods"
        log.debug("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == Unauthorized.code

        # TEST CONNECTED USER
        set_logged_user(self.client, users["admin_user"])
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
        set_logged_user(self.client, users["admin_user"])
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
                subscribed=True,
            )
            db.session.add(new_rule)

        title = "test creation"
        content = "no templating"
        url = "https://geonature.fr"
        context = {}

        assert not db.session.scalar(
            exists()
            .where(
                Notification.id_role == role.id_role,
            )
            .select()
        )

        # test create database notification
        utils.dispatch_notifications(
            ["Code_CATEGORY%"],
            [users["user"].id_role],
            title,
            url,
            content=content,
            context=context,
        )

        notif = db.session.execute(
            select(Notification).filter_by(id_role=role.id_role)
        ).scalar_one()
        assert notif.title == title
        assert notif.content == content
        assert notif.url == url
        assert notif.code_status == "UNREAD"

    def test_dispatch_notifications_database_with_like(
        self, users, rule_category, rule_category_1, rule_template
    ):
        role = users["user"]

        with db.session.begin_nested():
            # Create rule for further dispatching
            new_rule = NotificationRule(
                id_role=role.id_role,
                code_method="DB",
                code_category=rule_category_1.code,
                subscribed=True,
            )
            db.session.add(new_rule)

        title = "test creation"
        content = "no templating"
        url = "https://geonature.fr"
        context = {}

        assert not db.session.scalar(
            exists()
            .where(
                Notification.id_role == role.id_role,
            )
            .select()
        )

        # test create database notification
        utils.dispatch_notifications(
            ["Code_CATEGORY%"],
            [users["user"].id_role],
            title,
            url,
            content=content,
            context=context,
        )

        notif = db.session.execute(
            select(Notification).filter_by(id_role=role.id_role)
        ).scalar_one()
        assert notif.title == title
        assert notif.content == content
        assert notif.url == url
        assert notif.code_status == "UNREAD"

    def test_dispatch_notifications_mail_with_template(
        self, users, rule_category, rule_mail_template, celery_eager
    ):
        with db.session.begin_nested():
            users["user"].email = "user@geonature.fr"
            users["admin_user"].email = "admin@geonature.fr"
            db.session.add(
                NotificationRule(
                    id_role=users["user"].id_role,
                    code_method="EMAIL",
                    code_category=rule_category.code,
                    subscribed=True,
                )
            )
            db.session.add(
                NotificationRule(
                    id_role=users["admin_user"].id_role,
                    code_method="EMAIL",
                    code_category=rule_category.code,
                    subscribed=True,
                )
            )

        title = "test creation"
        content = "no templating"
        url = "https://geonature.fr"
        context = {"message": "msg"}

        with patch("geonature.utils.utilsmails.send_mail") as mock:
            utils.dispatch_notifications(
                ["Code_CATEGORY"],
                [users["user"].id_role, users["admin_user"].id_role],
                title,
                url,
                context=context,
            )
            # user should not be notified as template evaluate to empty string
            mock.assert_called_once_with("admin@geonature.fr", f"[GeoNature] {title}", "msg")
