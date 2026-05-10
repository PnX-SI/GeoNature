import pytest
from unittest.mock import patch
from datetime import datetime

import sqlalchemy as sa

from geonature.utils.env import db
from geonature.utils.contextmanagers import trigger_disabled
from geonature.core.notifications.models import (
    NotificationCategory,
    NotificationMethod,
    NotificationRule,
)
from geonature.tests.fixtures import *
from geonature.tests.utils import assert_mock_called_partial, assert_mock_not_called_partial
from geonature.tests.test_notifications import clear_notification_rules
from geonature.core.gn_synthese.tasks import send_synthese_notifications


@pytest.mark.usefixtures(
    "client_class",
    "temporary_transaction",
    "notifications_enabled",
    "celery_eager",
    "clear_notification_rules",
)
class TestSyntheseNotification:
    def test_synthese_notifications(self, users, synthese_data):
        obs_created = db.session.scalars(
            sa.select(NotificationCategory).where(
                NotificationCategory.code == "SYNTHESE-OBS-CREATED"
            )
        ).one()
        obs_updated = db.session.scalars(
            sa.select(NotificationCategory).where(
                NotificationCategory.code == "SYNTHESE-OBS-UPDATED"
            )
        ).one()
        db_method = db.session.scalars(
            sa.select(NotificationMethod).where(NotificationMethod.code == "DB")
        ).one()

        with db.session.begin_nested():
            # create rules
            db.session.add(
                NotificationRule(
                    id_role=users["self_user"].id_role,
                    code_method=db_method.code,
                    code_category=obs_created.code,
                    subscribed=True,
                )
            )
            # update rules
            db.session.add(
                NotificationRule(
                    id_role=users["self_user"].id_role,
                    code_method=db_method.code,
                    code_category=obs_updated.code,
                    subscribed=True,
                )
            )

        for synthese in synthese_data.values():
            assert synthese.meta_notification_date is None

        # Use database time to make comparison more reliable
        before_notifications = db.session.scalars(sa.select(sa.func.localtimestamp())).one()

        with patch("geonature.core.notifications.utils.send_notification") as mock:
            send_synthese_notifications.delay()
            call = assert_mock_called_partial(mock, obs_created, db_method, users["self_user"])
            assert set(call.kwargs["context"]["observations"]) == set(synthese_data.values())

        for synthese in synthese_data.values():
            assert synthese.meta_notification_date >= before_notifications

        # Increase meta_update_date to test update notifications
        # We manually modify meta_update_date as the database use NOW() which is the start time of the transaction
        with db.session.begin_nested():
            with trigger_disabled("gn_synthese.synthese", "tri_meta_dates_change_synthese"):
                synthese_data["obs1"].meta_update_date = datetime.utcnow()
                db.session.flush()  # force sqlalchemy to execute the update before trigger reactivation

        with patch("geonature.core.notifications.utils.send_notification") as mock:
            send_synthese_notifications.delay()
            mock.assert_called_once()
            call = assert_mock_called_partial(mock, obs_updated, db_method, users["self_user"])
            assert set(call.kwargs["context"]["observations"]) == {synthese_data["obs1"]}
