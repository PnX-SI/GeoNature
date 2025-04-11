from functools import partial

from flask import g
from werkzeug.exceptions import Unauthorized

from geonature.core.gn_permissions.tools import get_scopes_by_action


class CruvedProtectedMixin:
    def is_accessible(self):
        if g.current_user is None:
            raise Unauthorized  # return False leads to Forbidden which is different
        if not g.current_user.is_authenticated:
            raise Unauthorized
        return self._can_action("R")

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


# https://github.com/flask-admin/flask-admin/issues/1807
# https://stackoverflow.com/questions/54638047/correct-way-to-register-flask-admin-views-with-application-factory
class ReloadingIterator:
    def __init__(self, iterator_factory):
        self.iterator_factory = iterator_factory

    def __iter__(self):
        return self.iterator_factory()


class DynamicOptionsMixin:
    def get_dynamic_options(self, view):
        raise NotImplementedError

    def get_options(self, view):
        return ReloadingIterator(partial(self.get_dynamic_options, view))
