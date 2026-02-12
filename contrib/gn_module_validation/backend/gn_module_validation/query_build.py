from typing import Dict, Set, List, Optional

from flask import current_app, g
import sqlalchemy as sa
from sqlalchemy.orm import aliased, contains_eager, selectinload

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User

from geonature.utils.env import db
from geonature.core.gn_meta.models.datasets import TDatasets
from geonature.core.gn_synthese.models import Synthese, TReport
from geonature.core.gn_profiles.models import VConsistancyData
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from geonature.core.gn_commons.models.base import TValidations

from gn_module_validation.constant import *


def get_fields_from_params(params: Dict) -> Set[str]:
    """
    Builds the set of fields to return based on query parameters.

    Parameters
    ----------
    params : Dict
        Dictionary of query parameters. The 'fields' parameter will be extracted
        and removed from the dictionary.

    Returns
    -------
    Set[str]
        Set of field names to include in the response

    Notes
    -----
    If the 'fields' parameter is not provided, default fields are used.
    Profile fields are automatically added if profiles are enabled in the configuration.
    """
    enable_profile = current_app.config["FRONTEND"]["ENABLE_PROFILES"]
    fields_str = params.pop("fields", None)

    fields = set(list(DEFAULT_FIELDS))
    if enable_profile:
        fields.update(DEFAULT_PROFILE_FIELDS)

    if fields_str:
        fields.update({field.strip() for field in fields_str.split(",")})
    # Add configured columns
    fields.update({col["column_name"] for col in current_app.config["VALIDATION"]["COLUMN_LIST"]})
    return fields


def extract_profile_filters(params: Dict) -> Dict[str, Optional[bool]]:
    """
    Extracts and removes profile filter parameters from the parameters dictionary.

    Parameters
    ----------
    params : Dict
        Dictionary of query parameters. Profile parameters will be
        extracted and removed from this dictionary.

    Returns
    -------
    Dict[str, Optional[bool]]
        Dictionary containing profile filters:
        - 'score': Profile score
        - 'valid_distribution': Distribution validity
        - 'valid_altitude': Altitude validity
        - 'valid_phenology': Phenology validity

    Notes
    -----
    Values are None if the parameter is not present in the request.
    """
    return {
        "score": params.pop("score", None),
        "valid_distribution": params.pop("valid_distribution", None),
        "valid_altitude": params.pop("valid_altitude", None),
        "valid_phenology": params.pop("valid_phenology", None),
    }


def create_lateral_joins(synthese_alias, enable_profile: bool, use_profile_filter: bool) -> Dict:
    """
    Creates lateral joins for the last validation and consistency profile.

    Parameters
    ----------
    synthese_alias : aliased
        Alias of the Synthese table on which to create the joins
    enable_profile : bool
        Indicates if profiles are enabled in the configuration
    use_profile_filter : bool
        Indicates if profile filters are applied

    Returns
    -------
    Dict
        Dictionary mapping join aliases to corresponding relation attributes

    Notes
    -----
    Lateral joins allow efficient retrieval of:
    - The last validation for each observation
    - Consistency profile data (if enabled and used for filtering)
    """
    lateral_joins = {}

    # Last validation lateral join
    last_validation_subquery = (
        sa.select(TValidations)
        .where(TValidations.uuid_attached_row == synthese_alias.unique_id_sinp)
        .order_by(TValidations.validation_date.desc())
        .limit(1)
        .subquery()
        .lateral("last_validation")
    )
    last_validation = aliased(TValidations, last_validation_subquery)
    lateral_joins[last_validation] = Synthese.last_validation

    # Profile lateral join if enabled
    if enable_profile and use_profile_filter:
        profile_subquery = (
            sa.select(VConsistancyData)
            .where(VConsistancyData.id_synthese == synthese_alias.id_synthese)
            .limit(1)
            .subquery()
            .lateral("profile")
        )
        profile = aliased(VConsistancyData, profile_subquery)
        lateral_joins[profile] = Synthese.profile

    return lateral_joins


def get_relationships_from_fields(fields: Set[str]) -> List[str]:
    """
    Extracts relationship names to load from dotted field names.

    Parameters
    ----------
    fields : Set[str]
        Set of requested field names. Fields with dotted notation
        (e.g., 'dataset.name') indicate a relationship to load.

    Returns
    -------
    List[str]
        List of unique relationship names to load (part before the dot)

    Notes
    -----
    Fields starting with 'last_validation.' or 'profile.' are excluded as
    these relationships are handled by lateral joins.

    Examples
    --------
    >>> fields = {'id_synthese', 'dataset.name', 'taxref.cd_nom', 'profile.score'}
    >>> get_relationships_from_fields(fields)
    ['dataset', 'taxref']
    """
    return list(
        {
            field.split(".", 1)[0]
            for field in fields
            if "." in field
            and not (field.startswith("last_validation.") or field.startswith("profile."))
        }
    )


def apply_profile_filters(query, profile_alias, profile_filters: Dict):
    """
    Applies consistency profile-based filters to the query.

    Parameters
    ----------
    query : Query
        SQLAlchemy query to which to apply the filters
    profile_alias : aliased
        Alias of the VConsistancyData table for filtering
    profile_filters : Dict
        Dictionary of profile filters containing:
        - 'score': Exact score to filter
        - 'valid_distribution': Distribution validity (bool)
        - 'valid_altitude': Altitude validity (bool)
        - 'valid_phenology': Phenology validity (bool)

    Returns
    -------
    Query
        SQLAlchemy query with profile filters applied

    Notes
    -----
    Filters with None values are ignored. Boolean values are
    explicitly converted to ensure correct type.
    """
    score = profile_filters.get("score")
    valid_distribution = profile_filters.get("valid_distribution")
    valid_altitude = profile_filters.get("valid_altitude")
    valid_phenology = profile_filters.get("valid_phenology")

    if score is not None:
        query = query.where(profile_alias.score == score)
    if valid_distribution is not None:
        query = query.where(profile_alias.valid_distribution.is_(bool(valid_distribution)))
    if valid_altitude is not None:
        query = query.where(profile_alias.valid_altitude.is_(bool(valid_altitude)))
    if valid_phenology is not None:
        query = query.where(profile_alias.valid_phenology.is_(bool(valid_phenology)))

    return query


def build_synthese_query(params: Dict, permissions, limit: int = MAX_PER_PAGE):
    """
    Builds the main query to retrieve synthesis data with validations.

    This function builds a complex query in three steps:
    1. Creates an ORM SQLAlchemy query with joins
    2. Converts to Core SQLAlchemy query to apply user filters
    3. Returns to ORM with contains_eager to populate relationships

    Parameters
    ----------
    params : Dict
        Dictionary of query parameters including filters, sorting, etc.
        Profile parameters and some special filters will be extracted.
    permissions : object
        Current user permissions to filter results
    limit : int, optional
        Maximum number of results to return, default is MAX_PER_PAGE

    Returns
    -------
    tuple
        Tuple containing:
        - selectable: Core SQLAlchemy query with all filters applied
        - query_statement: ORM query with contains_eager for relationships
        - fields: Set of fields to include in the response

    Notes
    -----
    The function automatically handles:
    - Joins with validatable datasets
    - Lateral joins for the last validation
    - Profile joins if enabled and filtered
    - Loading of alert reports if configured
    - Filtering of observations without geometry

    Examples
    --------
    >>> params = {'valid_distribution': True, 'no_auto': True}
    >>> selectable, statement, fields = build_synthese_query(params, user_permissions)
    """
    enable_profile = current_app.config["FRONTEND"]["ENABLE_PROFILES"]

    # Extract filters
    profile_filters = extract_profile_filters(params)
    use_profile_filter = any(v is not None for k, v in profile_filters.items() if k != "score")
    no_auto = params.pop("no_auto", False)
    modif_since_validation = params.pop("modif_since_validation", None)

    # Get fields
    fields = get_fields_from_params(params)

    # Create base synthese subquery
    synthese_subquery = (
        sa.select(Synthese)
        .order_by(Synthese.date_min.desc())
        .join(TDatasets, TDatasets.id_dataset == Synthese.id_dataset)
        .where(TDatasets.validable == True)
        .limit(limit)
        .subquery()
    )
    synthese_alias = aliased(Synthese, synthese_subquery)

    # Create lateral joins
    lateral_joins = create_lateral_joins(synthese_alias, enable_profile, use_profile_filter)

    # Get relationships and aliases
    relationship_names = get_relationships_from_fields(fields)
    base_relationships = [getattr(Synthese, rel) for rel in relationship_names]
    relationship_aliases = [aliased(rel.property.mapper.class_) for rel in base_relationships]

    # Build query
    query = db.session.query(synthese_alias, *relationship_aliases, *lateral_joins.keys())

    # Add joins for relationships
    for base_rel, alias in zip(base_relationships, relationship_aliases):
        query = query.outerjoin(alias, getattr(synthese_alias, base_rel.key))

    # Add lateral joins
    for alias in lateral_joins.keys():
        query = query.outerjoin(alias, sa.true())

    # Apply profile filters
    if enable_profile and use_profile_filter:
        profile_alias = list(lateral_joins.keys())[1] if len(lateral_joins) > 1 else None
        if profile_alias:
            query = apply_profile_filters(query, profile_alias, profile_filters)

    # Apply other filters
    last_validation_alias = list(lateral_joins.keys())[0]

    if modif_since_validation:
        query = query.where(synthese_alias.meta_update_date > last_validation_alias.validation_date)

    if no_auto:
        query = query.where(last_validation_alias.validation_auto == False)

    # Apply SyntheseQuery filters
    selectable = SyntheseQuery(
        synthese_alias,
        query.selectable,
        params,
    ).filter_query_all_filters(g.current_user, permissions)

    # Build final query statement with contains_eager
    query_statement = synthese_alias.query.options(
        *[
            contains_eager(base_rel, alias=alias)
            for base_rel, alias in zip(base_relationships, relationship_aliases)
        ]
    ).options(*[contains_eager(rel, alias=alias) for alias, rel in lateral_joins.items()])

    # Add report loading if needed
    if should_load_reports():
        fields |= {"reports.report_type.type"}
        query_statement = query_statement.options(
            selectinload(Synthese.reports).joinedload(TReport.report_type)
        )

    # Filter for valid geometries
    selectable = selectable.where(synthese_alias.the_geom_4326.isnot(None))

    return selectable, query_statement, fields


def should_load_reports() -> bool:
    """
    Determines if alert reports should be loaded based on configuration.

    Returns
    -------
    bool
        True if alerts or pins are enabled for the VALIDATION module,
        False otherwise

    Notes
    -----
    Checks two configuration parameters:
    - ALERT_MODULES: List of modules with alerts enabled
    - PIN_MODULES: List of modules with pins enabled
    """
    config = current_app.config["SYNTHESE"]
    alert_active = len(config["ALERT_MODULES"]) > 0 and "VALIDATION" in config["ALERT_MODULES"]
    pin_active = len(config["PIN_MODULES"]) > 0 and "VALIDATION" in config["PIN_MODULES"]
    return alert_active or pin_active


def apply_sorting(query, params: Dict):
    """
    Applies sorting to a query based on provided parameters.

    Parameters
    ----------
    query : Query
        SQLAlchemy query to which to apply sorting
    params : Dict
        Dictionary of parameters containing:
        - 'sort': Sort direction ('asc' or 'desc')
        - 'order_by': Field name to sort by

    Returns
    -------
    Query
        SQLAlchemy query with sorting applied

    Notes
    -----
    If 'sort' or 'order_by' are missing or empty, the query is returned
    without modification. Default sort is 'desc' on 'last_validation.validation_date'.
    """
    sort = params.get("sort", "desc")
    order_by = sa.text(params.get("order_by", "last_validation.validation_date"))

    if sort and order_by is not None:
        if sort == "asc":
            return query.order_by(sa.asc(order_by))
        else:
            return query.order_by(sa.desc(order_by))

    return query


def build_validations_query(params: Dict):
    """
    Builds the query to retrieve validations with their associated information.

    Parameters
    ----------
    params : Dict
        Dictionary of query parameters containing:
        - 'fields': Additional fields ('observation', 'user_info')
        - 'format': Output format ('json', 'geojson')

    Returns
    -------
    Select
        SQLAlchemy Core query configured with appropriate joins and fields

    Notes
    -----
    Default fields always include:
    - Validation information (id, date, comment, auto)
    - Validation status nomenclature

    Optional fields include:
    - 'observation': Observation information (name, observers, dates)
    - 'user_info': Validator information (full name)
    - Geometry if format='geojson'
    """
    default_fields = [
        TValidations.id_validation,
        TValidations.validation_date,
        TValidations.validation_auto,
        TValidations.validation_comment,
        TNomenclatures.cd_nomenclature.label("nomenclature_cd_nomenclature"),
        TNomenclatures.mnemonique.label("nomenclature_mnemonique"),
        TNomenclatures.label_default.label("nomenclature_label_default"),
    ]

    fields_config = {
        "observation": (
            Synthese,
            TValidations.uuid_attached_row == Synthese.unique_id_sinp,
            [
                Synthese.id_synthese,
                Synthese.nom_cite,
                Synthese.observers,
                Synthese.date_min,
                Synthese.date_max,
            ],
        ),
        "user_info": (
            User,
            TValidations.id_validator == User.id_role,
            [User.nom_complet.label("validator")],
        ),
    }

    # Determine fields to select
    requested_fields = params.get("fields", "").split(",") if params.get("fields") else []
    format_type = params.get("format", "json")

    selected_fields = default_fields.copy()

    if "user_info" in requested_fields:
        selected_fields += fields_config["user_info"][2]

    if "observation" in requested_fields or format_type == "geojson":
        selected_fields += fields_config["observation"][2]

    if format_type == "geojson":
        selected_fields.append(sa.func.ST_AsGeoJSON(Synthese.the_geom_4326).label("the_geom_4326"))

    # Build query
    query = (
        sa.select(selected_fields)
        .select_from(TValidations)
        .join(Synthese, TValidations.uuid_attached_row == Synthese.unique_id_sinp)
        .join(TDatasets, Synthese.id_dataset == TDatasets.id_dataset)
        .join(
            TNomenclatures,
            TValidations.id_nomenclature_valid_status == TNomenclatures.id_nomenclature,
        )
        .where(TValidations.validation_auto == False)
        .where(TDatasets.validable == True)
    )

    if "user_info" in requested_fields:
        query = query.join(*fields_config["user_info"][:2])

    return query
