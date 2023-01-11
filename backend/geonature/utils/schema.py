from marshmallow import fields

from geonature.core.gn_permissions.tools import get_scopes_by_action


class CruvedSchemaMixin:
    cruved = fields.Method("get_cruved", metadata={"exclude": True})

    def get_cruved(self, obj):
        module_code = self.__module_code__
        object_code = getattr(self, "__object_code__", None)
        scopes = get_scopes_by_action(module_code=module_code, object_code=object_code)
        return {action: obj.has_instance_permission(scope) for action, scope in scopes.items()}
