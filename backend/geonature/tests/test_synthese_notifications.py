from geonature.core.gn_permissions.tools import get_permissions
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
    NotificationTemplate,
)
from geonature.tests.fixtures import *
from geonature.tests.utils import assert_mock_called_partial, assert_mock_not_called_partial
from geonature.tests.test_notifications import clear_notification_rules
from geonature.core.gn_synthese.tasks import send_synthese_notifications

# The observations list is computed automatically using R SYNTHESE
TEMPLATE_SYNTHESE_OBS = """
{%- if observations -%}{{ observations | length }}{%- endif -%}
"""
# The observations list is computed manually using C VALIDATION
TEMPLATE_VALIDATION_OBS = """
{%- set permissions = get_permissions(action_code="C", module_code="VALIDATION") -%}
{%- set observations = get_obs(obs_ids, permissions=permissions) -%}
{%- if observations -%}{{ observations | length }}{%- endif -%}
"""


@pytest.mark.usefixtures(
    "client_class",
    "temporary_transaction",
    "notifications_enabled",
    "celery_eager",
    "clear_notification_rules",
)
class TestSyntheseNotification:
    @pytest.mark.parametrize(
        "template",
        [TEMPLATE_SYNTHESE_OBS, TEMPLATE_VALIDATION_OBS],
        ids=["synthese_obs", "validation_obs"],
    )
    def test_synthese_notifications(self, request, users, synthese_data, template):
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
        obs_created_db_template = db.session.scalars(
            sa.select(NotificationTemplate).where(
                NotificationTemplate.code_category == "SYNTHESE-OBS-CREATED",
                NotificationTemplate.code_method == "DB",
            )
        ).one()
        obs_updated_db_template = db.session.scalars(
            sa.select(NotificationTemplate).where(
                NotificationTemplate.code_category == "SYNTHESE-OBS-UPDATED",
                NotificationTemplate.code_method == "DB",
            )
        ).one()

        with db.session.begin_nested():
            # create rules
            db.session.add(
                NotificationRule(
                    id_role=users["stranger_user"].id_role,
                    code_method=db_method.code,
                    code_category=obs_created.code,
                    subscribed=True,
                )
            )
            # update rules
            db.session.add(
                NotificationRule(
                    id_role=users["stranger_user"].id_role,
                    code_method=db_method.code,
                    code_category=obs_updated.code,
                    subscribed=True,
                )
            )
            db.session.add(
                NotificationRule(
                    id_role=users["self_user"].id_role,
                    code_method=db_method.code,
                    code_category=obs_updated.code,
                    subscribed=True,
                )
            )
            obs_created_db_template.content = template
            obs_updated_db_template.content = template

        for synthese in synthese_data.values():
            assert synthese.meta_notification_date is None

        # Use database time to make comparison more reliable
        before_notifications = db.session.scalars(sa.select(sa.func.localtimestamp())).one()

        with (
            patch(
                "geonature.core.gn_synthese.tasks.get_permissions", wraps=get_permissions
            ) as permissions_mock,
            patch(
                "geonature.core.notifications.utils.send_notification_to_db"
            ) as notifications_mock,
        ):
            send_synthese_notifications.delay()
            # when we resolve observations ourself in the template, the celery task should not
            # compute the observations list, so get_permissions should be called once in all cases.
            permissions_mock.assert_called_once()
            if request.node.callspec.id == "synthese_obs":
                assert_mock_called_partial(
                    permissions_mock, action_code="R", module_code="SYNTHESE"
                )
            elif request.node.callspec.id == "validation_obs":
                assert_mock_called_partial(
                    permissions_mock, action_code="C", module_code="VALIDATION"
                )
            notifications_mock.assert_called_once()
            # stranger_user does not have access to all obs
            call = assert_mock_called_partial(
                notifications_mock, users["stranger_user"], "Observation(s) crée(s)", "8"
            )

        for synthese in synthese_data.values():
            assert synthese.meta_notification_date >= before_notifications

        # Increase meta_update_date to test update notifications
        # We manually modify meta_update_date as the database use NOW() which is the start time of the transaction
        with db.session.begin_nested():
            with trigger_disabled("gn_synthese.synthese", "tri_meta_dates_change_synthese"):
                synthese_data["obs1"].meta_update_date = datetime.utcnow()
                db.session.flush()  # force sqlalchemy to execute the update before trigger reactivation

        with patch("geonature.core.notifications.utils.send_notification_to_db") as mock:
            send_synthese_notifications.delay()
            # stranger_user does not have access to obs1 so only self_user is notified
            mock.assert_called_once()
            call = assert_mock_called_partial(
                mock, users["self_user"], "Observation(s) modifiée(s)", "1"
            )
