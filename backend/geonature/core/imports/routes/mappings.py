from flask import request, jsonify, current_app, g
from geonature.core.imports.schemas import MappingSchema
from werkzeug.exceptions import Forbidden, Conflict, BadRequest, NotFound
from sqlalchemy.orm.attributes import flag_modified
import sqlalchemy as sa

from geonature.utils.env import db
from geonature.core.gn_permissions import decorators as permissions

from geonature.core.imports.models import (
    MappingTemplate,
    FieldMapping,
    ContentMapping,
    ObserverMapping,
)

from geonature.core.imports.blueprint import blueprint


@blueprint.url_value_preprocessor
def check_mapping_type(endpoint, values):
    if current_app.url_map.is_endpoint_expecting(endpoint, "mappingtype"):
        if values["mappingtype"] not in ["field", "content"]:
            raise NotFound
        values["mappingtype"] = values["mappingtype"].upper()
        if current_app.url_map.is_endpoint_expecting(endpoint, "id_mapping"):
            mapping = MappingTemplate.query.get_or_404(values.pop("id_mapping"))
            if mapping.destination != values.pop("destination"):
                raise NotFound
            if mapping.type != values.pop("mappingtype"):
                raise NotFound
            values["mapping"] = mapping


@blueprint.route("/<destination>/<mappingtype>mappings/", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="MAPPING")
def list_mappings(destination, mappingtype, scope):
    """
    .. :quickref: Import; Return all active named mappings.

    Return all active named (non-temporary) mappings.

    :param type: Filter mapping of the given type.
    :type type: str
    """
    mappings = (
        db.session.scalars(
            sa.select(MappingTemplate).where(
                MappingTemplate.destination == destination,
                MappingTemplate.type == mappingtype,
                MappingTemplate.active == True,
                MappingTemplate.filter_by_scope(scope),
            )
        )
        .unique()
        .all()
    )
    return jsonify(MappingSchema(many=True).dump(mappings))


@blueprint.route("/<destination>/<mappingtype>mappings/<int:id_mapping>/", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="MAPPING")
def get_mapping(mapping, scope):
    """
    .. :quickref: Import; Return a mapping.

    Return a mapping. Mapping has to be active.
    """
    if not mapping.public and not mapping.has_instance_permission(scope):
        raise Forbidden
    if mapping.active is False:
        raise Forbidden(description="Mapping is not active.")
    return jsonify(MappingSchema().dump(mapping))


@blueprint.route("/<destination>/<mappingtype>mappings/", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="MAPPING")
def add_mapping(destination, mappingtype, scope):
    """
    .. :quickref: Import; Add a mapping.
    """
    label = request.args.get("label")
    if not label:
        raise BadRequest("Missing label")

    # check if name already exists
    if db.session.scalar(
        sa.exists(MappingTemplate)
        .where(
            MappingTemplate.destination == destination,
            MappingTemplate.type == mappingtype,
            MappingTemplate.label == label,
        )
        .select()
    ):
        raise Conflict(description="Un mapping de ce type portant ce nom existe déjà")

    MappingClass = FieldMapping
    if mappingtype == "CONTENT":
        MappingClass = ContentMapping
    elif mappingtype == "OBSERVER":
        MappingClass = ObserverMapping
    try:
        MappingClass.validate_values(request.json)
    except ValueError as e:
        raise BadRequest(*e.args)

    mapping = MappingClass(
        destination=destination,
        type=mappingtype,
        label=label,
        owners=[g.current_user],
        values=request.json,
    )
    db.session.add(mapping)
    db.session.commit()
    return jsonify(mapping.as_dict())


@blueprint.route("/<destination>/<mappingtype>mappings/<int:id_mapping>/", methods=["POST"])
@permissions.check_cruved_scope("U", get_scope=True, module_code="IMPORT", object_code="MAPPING")
def update_mapping(mapping, scope):
    """
    .. :quickref: Import; Update a mapping (label and/or content).
    """
    if not mapping.has_instance_permission(scope):
        raise Forbidden

    label = request.args.get("label")
    if label:
        # check if name already exists
        template_exists = db.session.scalar(
            sa.exists(MappingTemplate)
            .where(
                MappingTemplate.type == mapping.type,
                MappingTemplate.label == label,
            )
            .select()
        )
        if template_exists:
            raise Conflict(description="Un mapping de ce type portant ce nom existe déjà")
        mapping.label = label
    if request.is_json:
        try:
            mapping.validate_values(request.json)
        except ValueError as e:
            raise BadRequest(*e.args)

        if mapping.type == "CONTENT":
            for key, value in request.json.items():
                if key not in mapping.values:
                    mapping.values[key] = value
                else:
                    mapping.values[key].update(value)
            flag_modified(mapping, "values")  # nested dict modification not detected by MutableDict
        else:  # FIELD and OBSERVER
            mapping.values.update(request.json)
    db.session.commit()
    return jsonify(mapping.as_dict())


@blueprint.route("/<destination>/<mappingtype>mappings/<int:id_mapping>/", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True, module_code="IMPORT", object_code="MAPPING")
def delete_mapping(mapping, scope):
    """
    .. :quickref: Import; Delete a mapping.
    """
    if not mapping.has_instance_permission(scope):
        raise Forbidden
    db.session.delete(mapping)
    db.session.commit()
    return "", 204
