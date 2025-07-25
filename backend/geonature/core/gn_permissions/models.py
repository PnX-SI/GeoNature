"""
Models of gn_permissions schema
"""

from flask import current_app

from packaging import version
from datetime import datetime

from ref_geo.models import LAreas
import sqlalchemy as sa
from sqlalchemy import ForeignKey, ForeignKeyConstraint
from sqlalchemy.sql import select
from sqlalchemy.orm import foreign, joinedload, contains_eager
import flask_sqlalchemy
from utils_flask_sqla.models import qfilter

from utils_flask_sqla.serializers import serializable
from pypnusershub.db.models import User
from apptax.taxonomie.models import Taxref

from geonature.utils.env import db
from geonature.core.gn_commons.models.base import TModules


@serializable
class PermFilterType(db.Model):
    __tablename__ = "bib_filters_type"
    __table_args__ = {"schema": "gn_permissions"}
    id_filter_type = db.Column(db.Integer, primary_key=True)
    code_filter_type = db.Column(db.Unicode)
    label_filter_type = db.Column(db.Unicode)
    description_filter_type = db.Column(db.Unicode)


@serializable
class PermScope(db.Model):
    __tablename__ = "bib_filters_scope"
    __table_args__ = {"schema": "gn_permissions"}
    value = db.Column(db.Integer, primary_key=True)
    label = db.Column(db.Unicode)
    description = db.Column(db.Unicode)

    def __str__(self):
        return self.description


@serializable
class PermAction(db.Model):
    __tablename__ = "bib_actions"
    __table_args__ = {"schema": "gn_permissions"}
    id_action = db.Column(db.Integer, primary_key=True)
    code_action = db.Column(db.Unicode)
    description_action = db.Column(db.Unicode)

    def __str__(self):
        return self.description_action


cor_object_module = db.Table(
    "cor_object_module",
    db.Column(
        "id_cor_object_module",
        db.Integer,
        primary_key=True,
    ),
    db.Column(
        "id_object",
        db.Integer,
        ForeignKey("gn_permissions.t_objects.id_object"),
    ),
    db.Column(
        "id_module",
        db.Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
    ),
    schema="gn_permissions",
)


@serializable
class PermObject(db.Model):
    __tablename__ = "t_objects"
    __table_args__ = {"schema": "gn_permissions"}
    id_object = db.Column(db.Integer, primary_key=True)
    code_object = db.Column(db.Unicode)
    description_object = db.Column(db.Unicode)

    def __str__(self):
        return f"{self.code_object} ({self.description_object})"


# compat.
TObjects = PermObject


def _nice_order(model, qs):
    from geonature.core.gn_commons.models import TModules

    return (
        qs.join(model.module)
        .join(model.object)
        .join(model.action)
        .options(
            contains_eager(model.module),
            contains_eager(model.object),
            contains_eager(model.action),
        )
        .order_by(
            TModules.module_code,
            # ensure ALL at first:
            sa.case([(PermObject.code_object == "ALL", "1")], else_=PermObject.code_object),
            model.id_action,
        )
    )


class PermissionAvailable(db.Model):
    __tablename__ = "t_permissions_available"
    __table_args__ = {"schema": "gn_permissions"}

    id_module = db.Column(
        db.Integer, ForeignKey("gn_commons.t_modules.id_module"), primary_key=True
    )
    id_object = db.Column(
        db.Integer,
        ForeignKey(PermObject.id_object),
        default=select(PermObject.id_object).where(PermObject.code_object == "ALL"),
        primary_key=True,
    )
    id_action = db.Column(db.Integer, ForeignKey(PermAction.id_action), primary_key=True)
    label = db.Column(db.Unicode)

    module = db.relationship("TModules")
    object = db.relationship(PermObject)
    action = db.relationship(PermAction)

    scope_filter = db.Column(db.Boolean, server_default=sa.false())
    sensitivity_filter = db.Column(db.Boolean, server_default=sa.false(), nullable=False)
    areas_filter = db.Column(db.Boolean, server_default=sa.false(), nullable=False)
    taxons_filter = db.Column(db.Boolean, server_default=sa.false(), nullable=False)

    filters_fields = {
        "SCOPE": "scope_filter",
        "SENSITIVITY": "sensitivity_filter",
        "GEOGRAPHIC": "areas_filter",
        "TAXONOMIC": "taxons_filter",
    }

    @property
    def filters(self):
        return [k for k, v in self.filters_fields.items() if getattr(self, v)]

    def __str__(self):
        s = self.module.module_label
        if self.object.code_object != "ALL":
            object_label = self.object.code_object.title().replace("_", " ")
            s += f" | {object_label}"
        s += f" | {self.label}"
        return s

    @staticmethod
    def nice_order(**kwargs):
        # TODO fix when flask admin is compatible with
        # sqlalchemy2.0 query style
        query = PermissionAvailable.query
        return _nice_order(PermissionAvailable, query)


class PermFilter:
    def __init__(self, name, value):
        self.name = name
        self.value = value

    def __str__(self):
        if self.name == "SCOPE":
            if self.value is None:
                return """<i class="fa fa-users" aria-hidden="true"></i> de tout le monde"""
            elif self.value == 1:
                return """<i class="fa fa-user" aria-hidden="true"></i> à moi"""
            elif self.value == 2:
                return """<i class="fa fa-user-circle" aria-hidden="true"></i> de mon organisme"""
        elif self.name == "SENSITIVITY":
            if self.value:
                statut = (
                    "floutées"
                    if current_app.config["SYNTHESE"]["BLUR_SENSITIVE_OBSERVATIONS"]
                    else "exclues"
                )
                return f"""<i class="fa fa-low-vision" aria-hidden="true"></i> sensibles {statut}"""
            else:
                return """<i class="fa fa-eye" aria-hidden="true"></i>  sensible et non sensible"""
        elif self.name == "GEOGRAPHIC":
            if self.value:
                areas_names = ", ".join([a.area_name for a in self.value])
                return f"""<i class="fa fa-map-marker" aria-hidden="true"></i>  {areas_names}"""
            else:
                return (
                    """<i class="fa fa-globe" aria-hidden="true"></i>  Aucune limite géographique"""
                )
        elif self.name == "TAXONOMIC":
            if self.value:
                taxons_names = ", ".join([t.nom_vern_or_lb_nom for t in self.value])
                return f"""<i class="fa fa-tree" aria-hidden="true"></i>  {taxons_names}"""
            else:
                return """<i class="fa fa-tree" aria-hidden="true"></i>  Tous les taxons"""


cor_permission_area = db.Table(
    "cor_permission_area",
    sa.Column(
        "id_permission",
        sa.Integer,
        sa.ForeignKey("gn_permissions.t_permissions.id_permission"),
        primary_key=True,
    ),
    sa.Column("id_area", sa.Integer, sa.ForeignKey("ref_geo.l_areas.id_area"), primary_key=True),
    schema="gn_permissions",
)


cor_permission_taxref = db.Table(
    "cor_permission_taxref",
    sa.Column(
        "id_permission",
        sa.Integer,
        sa.ForeignKey("gn_permissions.t_permissions.id_permission"),
        primary_key=True,
    ),
    sa.Column("cd_nom", sa.Integer, sa.ForeignKey("taxonomie.taxref.cd_nom"), primary_key=True),
    schema="gn_permissions",
)


@serializable
class Permission(db.Model):
    __tablename__ = "t_permissions"
    __table_args__ = (
        ForeignKeyConstraint(
            ["id_module", "id_object", "id_action"],
            [
                "gn_permissions.t_permissions_available.id_module",
                "gn_permissions.t_permissions_available.id_object",
                "gn_permissions.t_permissions_available.id_action",
            ],
        ),
        {"schema": "gn_permissions"},
    )

    id_permission = db.Column(db.Integer, primary_key=True)
    id_role = db.Column(db.Integer, ForeignKey("utilisateurs.t_roles.id_role"), nullable=False)
    id_action = db.Column(db.Integer, ForeignKey(PermAction.id_action), nullable=False)
    id_module = db.Column(db.Integer, ForeignKey("gn_commons.t_modules.id_module"), nullable=False)
    id_object = db.Column(
        db.Integer,
        ForeignKey(PermObject.id_object),
        default=select(PermObject.id_object).where(PermObject.code_object == "ALL"),
        nullable=False,
    )
    created_on = db.Column(sa.DateTime, server_default=sa.func.now())
    expire_on = db.Column(db.DateTime)
    validated = db.Column(sa.Boolean, server_default=sa.true())

    role = db.relationship(User, backref=db.backref("permissions", cascade_backrefs=False))
    action = db.relationship(PermAction)
    module = db.relationship(TModules)
    object = db.relationship(PermObject)

    scope_value = db.Column(db.Integer, ForeignKey(PermScope.value), nullable=True)
    scope = db.relationship(PermScope)
    sensitivity_filter = db.Column(db.Boolean, server_default=sa.false(), nullable=False)
    areas_filter = db.relationship(LAreas, secondary=cor_permission_area)
    taxons_filter = db.relationship(Taxref, secondary=cor_permission_taxref)

    availability = db.relationship(
        PermissionAvailable,
        backref=db.backref("permissions", overlaps="action, object, module"),  # overlaps expected
        overlaps="action, object, module",  # overlaps expected
    )

    filters_fields = {
        "SCOPE": "scope_value",
        "SENSITIVITY": "sensitivity_filter",
        "GEOGRAPHIC": "areas_filter",
        "TAXONOMIC": "taxons_filter",
    }

    def __repr__(self):
        return f"""Permission {self.id_permission} 
        - Role: {self.role.nom_complet or self.role.identifiant} 
        - Module: {self.module.module_label} 
        - Action : {self.action.code_action}
        - Scope : {self.scope_value}
        - Taxons Filter : {self.taxons_filter}
        - Areas Filter : {self.areas_filter}
        - Object: {self.object}
        - Floutage : {"Oui" if self.sensitivity_filter else "Non"}
        - Expire le : {self.expire_on}\n"""

    @staticmethod
    def __SCOPE_le__(a, b):
        return b is None or (a is not None and a <= b)

    @staticmethod
    def __SENSITIVITY_le__(a, b):
        # False only if: A is False and b is True
        return (not a) <= (not b)

    @staticmethod
    def __GEOGRAPHIC_le__(a, b):
        return (a and set(a).issubset(b)) or not b

    @staticmethod
    def __TAXONOMIC_le__(a, b):
        # True if *all* taxons of a is included in *any* taxons of b
        return (a and any(all((_a <= _b for _a in a)) for _b in b)) or not b

    @staticmethod
    def __default_le__(a, b):
        return a == b or b is None

    def __le__(self, other):
        """
        Return True if this permission is supersed by 'other' permission.
        This requires all filters to be supersed by 'other' filters.
        """
        for name, field in self.filters_fields.items():
            # Get filter comparison function or use default comparison function
            __le_fct__ = getattr(self, f"__{name}_le__", Permission.__default_le__)
            self_value, other_value = getattr(self, field), getattr(other, field)
            if not __le_fct__(self_value, other_value):
                return False
        return True

    @property
    def filters(self):
        filters = []
        for name, field in self.filters_fields.items():
            value = getattr(self, field)
            mapper = self.__mapper__
            if field in mapper.columns:
                column = mapper.columns[field]
                if column.nullable:
                    if value is None:
                        continue
                if column.type.python_type is bool:
                    if not value:
                        continue
            elif field in mapper.relationships:
                if value == []:
                    continue
            filters.append(PermFilter(name, value))
        return filters

    def has_other_filters_than(self, *expected_filters):
        for flt in self.filters:
            if flt.name not in expected_filters:
                return True
        return False

    @qfilter(query=True)
    def nice_order(cls, **kwargs):
        return _nice_order(cls, kwargs["query"])

    @property
    def is_active(self):
        return (
            self.expire_on is None or self.expire_on > datetime.now()
        ) and self.validated is True

    @classmethod
    def active_filter(cls):
        return sa.and_(
            sa.or_(cls.expire_on.is_(sa.null()), cls.expire_on > datetime.now()),
            cls.validated.is_(True),
        )
