from flask import url_for
from geonature.core.gn_commons.models.base import TModules
from geonature.core.gn_permissions.models import PermAction, PermObject, Permission
from geonature.utils.env import db
from pypnusershub.db.models import (
    User,
    Organisme,
    Application,
    Profils as Profil,
    UserApplicationRight,
)
from pypnusershub.tests.utils import (
    set_logged_user,
    unset_logged_user,
    logged_user,
    logged_user_headers,
)

from sqlalchemy import select


def login(client, username="admin", password=None):
    data = {
        "login": username,
        "password": password if password else username,
    }
    response = client.post(url_for("auth.login"), json=data)
    assert response.status_code == 200


def get_scope(scope, detailed_scopes, module_code, action):
    scope = scope if scope != 3 else None
    if not module_code in detailed_scopes:
        return scope
    if not action in detailed_scopes[module_code]:
        return scope

    detailed_scope = detailed_scopes[action][module_code]
    if isinstance(detailed_scope, int) and 0 < detailed_scope < 3:
        return detailed_scope
    return scope


def create_user(
    username,
    organisme=None,
    scope=None,
    sensitivity_filter=False,
    modules_codes=[],
    detailed_scopes={},
    **kwargs
):
    app = db.session.execute(
        select(Application).where(Application.code_application == "GN")
    ).scalar_one()

    profil = db.session.execute(select(Profil).where(Profil.nom_profil == "Lecteur")).scalar_one()

    modules_query = select(TModules)
    if len(modules_codes) > 0:
        modules_query = modules_query.where(TModules.module_code.in_(modules_codes))

    modules = db.session.scalars(modules_query).all()

    actions = {
        code: db.session.execute(select(PermAction).filter_by(code_action=code)).scalar_one()
        for code in "CRUVED"
    }

    # do not commit directly on current transaction, as we want to rollback all changes at the end of tests
    with db.session.begin_nested():
        user = User(groupe=False, active=True, identifiant=username, password=username, **kwargs)
        db.session.add(user)
        user.organisme = organisme
    # user must have been commited for user.id_role to be defined
    with db.session.begin_nested():
        # login right
        right = UserApplicationRight(
            id_role=user.id_role, id_application=app.id_application, id_profil=profil.id_profil
        )
        db.session.add(right)
        if scope > 0 or detailed_scopes:
            object_all = db.session.execute(
                select(PermObject).filter_by(code_object="ALL")
            ).scalar_one()
            for action in actions.values():
                for module in modules:
                    for obj in [object_all] + module.objects:
                        scope_value = scope
                        permission = Permission(
                            action=action,
                            module=module,
                            object=obj,
                            scope_value=get_scope(
                                scope, detailed_scopes, module.module_code, action.code_action
                            ),
                            sensitivity_filter=sensitivity_filter,
                        )
                        db.session.add(permission)
                        permission.role = user
    return user


jsonschema_definitions = {
    "geometries": {
        "BoundingBox": {
            "type": "array",
            "minItems": 4,
            "items": {"type": "number"},
        },
        "PointCoordinates": {"type": "array", "minItems": 2, "items": {"type": "number"}},
        "Point": {
            "title": "GeoJSON Point",
            "type": "object",
            "required": ["type", "coordinates"],
            "properties": {
                "type": {"type": "string", "enum": ["Point"]},
                "coordinates": {
                    "$ref": "#/definitions/geometries/PointCoordinates",
                },
                "bbox": {
                    "$ref": "#/definitions/geometries/BoundingBox",
                },
            },
        },
    },
    "feature": {
        "title": "GeoJSON Feature",
        "type": "object",
        "required": ["type", "properties", "geometry"],
        "properties": {
            "type": {"type": "string", "enum": ["Feature"]},
            "id": {"oneOf": [{"type": "number"}, {"type": "string"}]},
            "properties": {
                "oneOf": [
                    {"type": "null"},
                    {"$ref": "#/$defs/props"},
                ],
            },
            "geometry": {
                "oneOf": [
                    {"type": "null"},
                    {"$ref": "#/definitions/geometries/Point"},
                    # {"$ref": "#/definitions/geometries/LineString"},
                    # {"$ref": "#/definitions/geometries/Polygon"},
                    # {"$ref": "#/definitions/geometries/MultiPoint"},
                    # {"$ref": "#/definitions/geometries/MultiLineString"},
                    # {"$ref": "#/definitions/geometries/MultiPolygon"},
                    # {"$ref": "#/definitions/geometries/GeometryCollection"},
                ],
            },
            "bbox": {
                "$ref": "#/definitions/geometries/BoundingBox",
            },
        },
    },
    "featurecollection": {
        "title": "GeoJSON FeatureCollection",
        "type": "object",
        "required": ["type", "features"],
        "properties": {
            "type": {
                "type": "string",
                "enum": ["FeatureCollection"],
            },
            "features": {
                "type": "array",
                "items": {
                    "$ref": "#/definitions/feature",
                },
            },
            "bbox": {
                "$ref": "#/definitions/geometries/BoundingBox",
            },
        },
    },
}
