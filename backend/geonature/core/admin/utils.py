from flask import g
from werkzeug.exceptions import Unauthorized

from geonature.core.gn_permissions.tools import get_scopes_by_action


class CruvedProtectedMixin:
    def is_accessible(self):
        if g.current_user is None:
            raise Unauthorized  # return False leads to Forbidden which is different
        return True

    def _can_action(self, action):
        scope = get_scopes_by_action(
            g.current_user.id_role,
            module_code=self.module_code,
            object_code=getattr(self, "object_code", "ALL"),
        )[action]
        return scope == 3

    @property
    def can_create(self):
        return self._can_action("C")

    @property
    def can_edit(self):
        return self._can_action("U")

    @property
    def can_delete(self):
        return self._can_action("D")

    @property
    def can_export(self):
        return self._can_action("E")
