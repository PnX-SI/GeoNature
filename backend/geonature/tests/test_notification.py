import pytest
import logging
import json

from flask import url_for

from geonature.core.notifications.models import (
    Notification,
    NotificationMethod,
    NotificationRule,
    NotificationTemplate,
)
from geonature.core.notifications.utils import NotificationUtil

from .utils import set_logged_user_cookie

log = logging.getLogger()


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestNotification:
    def test_list_database_notification(self, users):
        # Init data for test
        url = "notifications.list_database_notification"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 0

    def test_count_notification(self, users):
        # Init data for test
        url = "notifications.count_notification"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

    def test_update_notification(self, users):
        # Init data for test
        url = "notifications.update_notification"
        log.info("Url d'appel %s", url_for(url, id_notification=1))

        response = self.client.post(url_for(url, id_notification=1))
        assert response.status_code == 401

        # TEST CONNECTED USER BUT NOTIFICATION DOES NOT EXIST
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.post(url_for(url, id_notification=1))
        assert response.status_code == 404

    def test_list_notification_rules(self, users):
        # Init data for test
        url = "notifications.list_notification_rules"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.get(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.get(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert len(data) == 0

    def test_delete_all_notifications(self, users):
        # Init data for test
        url = "notifications.delete_all_notifications"
        log.info("Url d'appel %s", url_for(url))

        # TEST NO USER
        response = self.client.delete(url_for(url))
        assert response.status_code == 401

        # TEST CONNECTED USER
        set_logged_user_cookie(self.client, users["admin_user"])
        response = self.client.delete(url_for(url))
        assert response.status_code == 200
        data = response.get_json()
        assert data == 0

    def test_create_rule(self, users):
        # Init data for test
        url = "notifications.create_rule"
        log.info("Url d'appel %s", url_for(url))
        response = self.client.put(url_for(url))

    def test_delete_all_rules(self, users):
        # Init data for test
        url = "notifications.delete_all_rules"
        log.info("Url d'appel %s", url_for(url))

    def test_delete_rule(self, users):
        # Init data for test
        url = "notifications.delete_rule"
        log.info("Url d'appel %s", url_for(url, id_notification_rules=1))

    def test_list_methods(self, users):

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

        # use id_role from fixture users
        # id_role = users["admin_user"].id_role
        # response = NotificationUtil.create_database_notification(id_role, title, content, url)
        # assert response == json.dumps({"success": True, "information": "Notification saved"})
