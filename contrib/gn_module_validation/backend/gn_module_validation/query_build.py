from typing import Dict, Optional, Set

import sqlalchemy as sa
from flask import current_app, g
from geonature.core.gn_commons.models.base import TValidations
from geonature.core.gn_meta.models.datasets import TDatasets
from geonature.core.gn_profiles.models import VConsistencyData
from geonature.core.gn_synthese.models import Synthese, TReport
from geonature.core.gn_synthese.utils.query_select_sqla import SyntheseQuery
from gn_module_validation.constant import *
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from sqlalchemy.orm import (
    aliased,
    joinedload,
    raiseload,
)


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

    """
    return {
        "score": params.pop("score", None),
        "valid_distribution": params.pop("valid_distribution", None),
        "valid_altitude": params.pop("valid_altitude", None),
        "valid_phenology": params.pop("valid_phenology", None),
    }


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
    query
    """
    enable_profile = current_app.config["FRONTEND"]["ENABLE_PROFILES"]

    # Extract filters
    profile_filters = extract_profile_filters(params)
    use_profile_filter = any(v is not None for k, v in profile_filters.items() if k != "score")
    no_auto = params.pop("no_auto", False)
    modif_since_validation = params.pop("modif_since_validation", None)

    # Get fields
    fields = get_fields_from_params(params)

    # Séparer les colonnes de Synthese et celles des relations
    synthese_columns = []
    relation_fields = {}  # Dict: {relation_name: [column_names]}
    relation_aliases = {}  # Dictionnaire pour stocker les alias des relations

    for field in fields:
        if "." not in field and hasattr(Synthese, field):
            synthese_columns.append(getattr(Synthese, field))
        elif "." in field:
            relation_name, column_name = field.split(".", 1)
            if relation_name not in relation_fields:
                relation_fields[relation_name] = []
            relation_fields[relation_name].append(column_name)

    # Create base synthese query
    query = (
        sa.select(Synthese)
        .order_by(Synthese.date_min.desc())
        .where(TDatasets.validable == True)
        .where(Synthese.the_geom_4326.isnot(None))
        .limit(limit)
    )
    query = query.options(raiseload("*"))

    query_builder = SyntheseQuery(
        Synthese,
        query,
        params,
    )
    query_builder.add_join(
        TDatasets, TDatasets.id_dataset, Synthese.id_dataset
    )  # prevent multiple same joins
    query_builder.apply_all_filters(g.current_user, permissions)
    query = query_builder.build_query()

    # Last validation lateral join
    last_validation_subquery = (
        sa.select(TValidations)
        .where(TValidations.uuid_attached_row == Synthese.unique_id_sinp)
        .order_by(TValidations.validation_date.desc())
        .limit(1)
        .subquery()
        .lateral("last_validation")
    )
    last_validation = aliased(TValidations, last_validation_subquery)
    relation_aliases["last_validation"] = last_validation
    query = query.outerjoin(last_validation, sa.true())

    # Profile lateral join if enabled
    if enable_profile and use_profile_filter:
        profile_subquery = (
            sa.select(VConsistencyData)
            .where(VConsistencyData.id_synthese == Synthese.id_synthese)
            .limit(1)
            .subquery()
            .lateral("profile")
        )
        profile = aliased(VConsistencyData, profile_subquery)
        relation_aliases["profile"] = profile
        query = query.outerjoin(profile, sa.true())
        query = apply_profile_filters(query, profile, profile_filters)

    if modif_since_validation:
        query = query.where(Synthese.meta_update_date > last_validation.validation_date)

    if no_auto:
        query = query.where(last_validation.validation_auto == False)

    if should_load_reports():
        fields |= {"reports.report_type.type"}
        query = query.options(joinedload(Synthese.reports).joinedload(TReport.report_type))

    for relation_name in relation_fields.keys():
        # ignore lateral joins
        if relation_name in relation_aliases:
            continue

        if hasattr(Synthese, relation_name):
            # Fetch relationship in the Synthese
            rel_property = getattr(Synthese.__mapper__.relationships, relation_name, None)

            if rel_property:
                # Fetch the class of the model of the entities fetched by the relationship
                related_model = rel_property.mapper.class_

                # Required for the join
                rel_alias = aliased(related_model)
                relation_aliases[relation_name] = rel_alias

                local_col = list(rel_property.local_columns)[0]  # for ex, synthese.id_dataset
                remote_col = list(rel_property.remote_side)[0]  # for ex t_datasets.id_dataset

                query = query.outerjoin(rel_alias, local_col == getattr(rel_alias, remote_col.name))

    # Creating the list of columns in the final SELECT
    final_columns = [col for col in synthese_columns]

    # add column fetched from relationships entities
    for relation_name, column_names in relation_fields.items():
        rel_alias = relation_aliases.get(relation_name)

        if rel_alias:
            for column_name in column_names:
                if hasattr(rel_alias, column_name):
                    final_columns.append(
                        getattr(rel_alias, column_name).label(f"{relation_name}.{column_name}")
                    )

    # Set columns
    query = query.with_only_columns(*final_columns + [Synthese.the_geom_4326])

    return query


def should_load_reports() -> bool:
    """
    Determines if alert reports should be loaded based on configuration.

    Returns
    -------
    bool
        True if alerts or pins are enabled for the VALIDATION module,
        False otherwise
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
        .where(TValidations.validation_auto == False)
        .where(TDatasets.validable == True)
    )
    initial_joins = (
        Synthese.__table__.join(
            TValidations, TValidations.uuid_attached_row == Synthese.unique_id_sinp
        )
        .join(TDatasets, Synthese.id_dataset == TDatasets.id_dataset)
        .join(
            TNomenclatures,
            TValidations.id_nomenclature_valid_status == TNomenclatures.id_nomenclature,
        )
    )

    if "user_info" in requested_fields:
        initial_joins = initial_joins.join(User, TValidations.id_validator == User.id_role)

    return query, initial_joins
