from enum import Enum
from geonature.core.imports.models import Entity
from sqlalchemy import func, select
from geonature.utils.env import db
import json


class Key(str, Enum):
    CODE_ENTITY = "code_entity"
    NAME_FIELD = "field_name"
    IS_RELEVANT = "is_relevant"


def get_valid_bbox(imprt):
    """Get the valid bounding box for a given import.
    Parameters
    ----------
    imprt : geonature.core.imports.models.TImports
        The import object.
    entity : geonature.core.imports.models.Entity
        The entity object (e.g.: observation, station...).
    Returns
    -------
    dict or None
        The valid bounding box as a JSON object, or None if no valid bounding box.
    Raises
    ------
    NotImplementedError
        If the function is not implemented for the destination of the import.
    """
    # Retrieve the name of the field and the name of the entity to retrieve geometries from
    if "get_bbox_computation_infos" not in imprt.destination.module._imports_:
        raise NotImplementedError(
            f"function get_valid_bbox not implemented for an import with destination '{imprt.destination.code}, needs `get_bbox_computation_infos` function"
        )
    infos = imprt.destination.module._imports_["get_bbox_computation_infos"]()

    if not Key.IS_RELEVANT in infos:
        raise NotImplementedError(
            f"The function get_valid_bbox implementation for an import with destination '{imprt.destination.code}' is incomplete. It requires '{Key.IS_RELEVANT}' field"
        )
    if not infos[Key.IS_RELEVANT]:
        return None

    if not Key.CODE_ENTITY in infos:
        raise NotImplementedError(
            f"The function get_valid_bbox implementation for an import with destination '{imprt.destination.code}' is incomplete. It requires '{Key.CODE_ENTITY}' field"
        )
    code_entity = infos[Key.CODE_ENTITY]

    if not Key.NAME_FIELD in infos:
        raise NotImplementedError(
            f"The function get_valid_bbox implementation for an import with destination '{imprt.destination.code}' is incomplete. It requires '${Key.NAME_FIELD}' field"
        )
    name_geom_4326_field = infos[Key.NAME_FIELD]

    # Retrieve the where clause to filter data for the given import
    if "get_where_clause_id_import" not in imprt.destination.module._imports_:
        raise NotImplementedError(
            f"function get_valid_bbox not implemented for an import with destination '{imprt.destination.code}, needs `get_where_clause_id_import` function"
        )

    entity = Entity.query.filter_by(destination=imprt.destination, code=code_entity).one()

    where_clause_id_import = imprt.destination.module._imports_["get_where_clause_id_import"](imprt)

    # Build the statement to retrieve the valid bounding box
    statement = None
    if imprt.loaded == True:
        # Compute from entries in the transient table and related to the import
        transient_table = imprt.destination.get_transient_table()
        statement = (
            select(func.ST_AsGeojson(func.ST_Extent(transient_table.c[name_geom_4326_field])))
            .where(where_clause_id_import)
            .where(transient_table.c[entity.validity_column] == True)
        )
    else:
        destination_table = entity.get_destination_table()
        # Compute from entries in the destination table and related to the import
        statement = select(
            func.ST_AsGeojson(func.ST_Extent(destination_table.c[name_geom_4326_field]))
        ).where(where_clause_id_import)

    # Execute the statement to eventually retrieve the valid bounding box
    (valid_bbox,) = db.session.execute(statement).fetchone()

    # Return the valid bounding box or None
    if valid_bbox:
        return json.loads(valid_bbox)
