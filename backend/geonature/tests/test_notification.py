import pytest
import logging
import json
import datetime

from flask import url_for

from geonature.utils.env import db
from geonature.core.notifications.models import (
    Notification,
    NotificationCategory,
    NotificationMethod,
    NotificationRule,
    NotificationTemplate,
)
from geonature.core.notifications.utils import NotificationUtil

from .utils import set_logged_user_cookie

log = logging.getLogger()


@pytest.fixture()
def notification_data(users):

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
def rule_categorie():
    new_categorie = NotificationCategory(
        code="Code_CATEGORIE", label="Label_Categorie", description="description_categorie"
    )
    db.session.add(new_categorie)
    return new_categorie


@pytest.fixture()
def rule_method():
    new_method = NotificationMethod(
        code="Code_METHOD", label="Label_Method", description="description_method"
    )
    db.session.add(new_method)
    return new_method


@pytest.fixture()
def rule_template(rule_method, rule_categorie):
    new_template = NotificationTemplate(
        code_categorie=rule_categorie.code,
        code_method=rule_method.code,
        content="template {{ toto }}",
    )
    db.session.add(new_template)

    return new_template


@pytest.fixture()
def notification_rule(users, rule_method, rule_categorie):
    new_notification_rule = NotificationRule(
        id_role=users["admin_user"].id_role,
        code_method=rule_method.code,
        code_category=rule_categorie.code,
    )
    db.session.add(new_notification_rule)

    return new_notification_rule


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestNotification:
    def test_list_database_notification(self, users, notification_data):
        # Init data for test
        url = "notifications.list_database_notification"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER WITHOUT NOTIFICATION
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 0

        # TEST CONNECTED USER WIT NOTIFICATION
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 1

    def test_count_notification(self, users, notification_data):
        # Init data for test
        url = "notifications.count_notification"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

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
        log.info("Url d'appel %s", url_for(url, id_notification=1))

        response = self.client.post(url_for(url, id_notification=1))
        assert response.status_code == 401

        # TEST CONNECTED USER BUT NOTIFICATION DOES NOT EXIST FOR THIS USER
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.post(
            url_for(url, id_notification=notification_data.id_notification)
        )
        assert response.status_code == 403

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.post(
            url_for(url, id_notification=notification_data.id_notification)
        )
        assert response.status_code == 200

    def test_delete_all_notifications(self, users, notification_data):
        # Init data for test
        url = "notifications.delete_all_notifications"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.delete(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER WITHOUT NOTIFICATION
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

        # TEST CONNECTED USER WITH NOTIFICATION
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 1

    def test_list_notification_rules(self, users, notification_rule):
        # Init data for test
        url = "notifications.list_notification_rules"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

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

    def test_create_rule(self, users, rule_method, rule_categorie):
        # Init data for test
        url = "notifications.create_rule"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.put(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER WITHOUT DATA
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.put(url_for(url))
        assert response.status_code == 400

        # TEST CONNECTED USER WITH DATA BUT WRONG KEY
        set_logged_user_cookie(self.client, users["admin_user"])
        data = {"method": rule_method.code, "categorie": rule_categorie.code}
        response = self.client.put(url_for(url, data=data))
        assert response.status_code == 400

        # TEST CONNECTED USER WITH DATA BUT WRONG VALUE
        set_logged_user_cookie(self.client, users["admin_user"])
        data = {"code_method": 1, "code_category": rule_categorie.code}
        response = self.client.put(url_for(url, data=data))
        assert response.status_code == 400

    def test_delete_all_rules(self, users, notification_rule):
        # Init data for test
        url = "notifications.delete_all_rules"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.delete(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER WITHOUT RULE
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

        # TEST CONNECTED USER WITH RULE
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 1

    def test_delete_rule(self, users, notification_rule):
        # Init data for test
        url = "notifications.delete_rule"
        log.info("Url d'appel %s", url_for(url, id_notification_rules=1))

        # TEST NO USER
        response = self.client.delete(url_for(url, id_notification_rules=1))
        assert response.status_code == 401

        # TEST CONNECTED USER WITHOUT RULE
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(url_for(url, id_notification_rules=1))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

        # TEST CONNECTED USER WITH RULE
        set_logged_user_cookie(self.client, users["user"])
        response = self.client.delete(
            url_for(url, id_notification_rules=notification_rule.id_notification_rules)
        )
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

    def test_list_methods(self, users, rule_method):

        # Init data for test
        url = "notifications.list_notification_methods"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) > 0

    def test_list_notification_categories(self, users):

        # Init data for test
        url = "notifications.list_notification_categories"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) > 0

    def test_notification_database_creation(self, users):
        empty_id_role = ""
        title = "test creation"
        content = "after templating"
        url = "ta"

        # Id role does not exist
        response = NotificationUtil.create_database_notification(
            empty_id_role, title, content, url
        )
        assert response == json.dumps(
            {"success": False, "information": "Could not save notification in database"}
        )

    def test_notification_creation(self, users, rule_categorie, notification_rule, rule_method):
        empty_id_role = ""
        title = "test creation"
        content = "after templating"
        url = "ta"

        # Category missing
        notificationData = {"category": "test"}
        response = NotificationUtil.create_notification(notificationData)
        assert response == json.dumps(
            {"success": False, "information": "Category is missing from the request"}
        )

        # Categorie does not exist
        notificationData = {"categories": ["test"]}
        response = NotificationUtil.create_notification(notificationData)
        assert response == json.dumps(
            {
                "result": [
                    {
                        "success": False,
                        "category": "test",
                        "information": "This category of notification is not implemented yet",
                    }
                ]
            }
        )

        # Categorie exist but no user
        notificationData = {"categories": [rule_categorie.code]}
        response = NotificationUtil.create_notification(notificationData)
        assert response == json.dumps(
            {
                "result": [
                    {
                        "success": False,
                        "category": "Code_CATEGORIE",
                        "information": "Notification is missing id_role to be notified",
                    }
                ]
            }
        )

        # Categorie exist and user witout rules
        notificationData = {
            "categories": [rule_categorie.code],
            "id_roles": [users["user"].id_role],
        }
        response = NotificationUtil.create_notification(notificationData)
        assert response == json.dumps(
            {
                "result": [
                    {
                        "success": False,
                        "category": "Code_CATEGORIE",
                        "role": users["user"].id_role,
                        "information": "No rules for this user/category",
                    }
                ]
            }
        )
