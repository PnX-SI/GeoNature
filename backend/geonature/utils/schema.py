from marshmallow import fields

from geonature.core.gn_permissions.tools import get_scopes_by_action


class CruvedSchemaMixin:
    """
    This mixin add a cruved field which serialize to a dict "{action: boolean}".
        example: {"C": False, "R": True, "U": True, "V": False, "E": True, "D": False}
    The schema must have a __module_code__ property (and optionally a __object_code__property)
    to indicate from which permissions must be verified.
    The model must have an has_instance_permission method which take the scope and retrurn a boolean.
    The cruved field is excluded by default and may be added to serialization with only=["+cruved"].
    """

    cruved = fields.Method("get_cruved", metadata={"exclude": True})

    def get_cruved(self, obj):
        module_code = self.__module_code__
        object_code = getattr(self, "__object_code__", None)
        scopes = get_scopes_by_action(module_code=module_code, object_code=object_code)
        return {action: obj.has_instance_permission(scope) for action, scope in scopes.items()}
