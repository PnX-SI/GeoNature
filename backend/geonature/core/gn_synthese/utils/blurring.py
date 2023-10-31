import logging
from collections import namedtuple, defaultdict

from flask import current_app
from sqlalchemy import (case, func, and_, or_, select, column, text, union, literal)

from pypnnomenclature.models import (
    TNomenclatures,
    BibNomenclaturesTypes,
)

from geonature.core.gn_synthese.models import (CorAreaSynthese, Synthese, VSyntheseForWebApp)
from ref_geo.models import (LAreas, BibAreasTypes)
from apptax.taxonomie.models import Taxref
from geonature.utils.env import DB

class DataBlurring:
    def __init__(
        self,
        permissions,
        # TODO: try to not use sensitivity_column and diffusion_column parameters
        sensitivity_column="id_nomenclature_sensitivity",
        diffusion_column="id_nomenclature_diffusion_level",
        result_to_dict=True,
        fields_to_erase=None,
        geom_fields=[
            {
                "output_field": "st_asgeojson",
                "area_field": "geojson_4326",
            },
        ],
        data_table=VSyntheseForWebApp,
    ):
        # get the root logger
        self.log = logging.getLogger()
        self.permissions = permissions
        self.sensitivity_column = sensitivity_column
        self.diffusion_column = diffusion_column
        self.result_to_dict = result_to_dict
        self.fields_to_erase = fields_to_erase
        self.geom_fields = geom_fields
        self.data_table = data_table
        self.diffusion_levels_ids = self._get_diffusion_levels()
        self.sensitivity_ids = self._get_sensitivity_levels()
        self.non_diffusable = []

    def blurSeveralObs(self, synthese_results):
        # If no result return directly
        if synthese_results == None:
            return synthese_results

        (exact_filters, see_all) = self._compute_exact_filters()
        ignored_object = self._get_ignored_object(see_all)
        output = []
        if ignored_object == "PRIVATE_AND_SENSITIVE":
            # No need to blur, set output directly
            output = synthese_results
        else:
            # Need to blur observations
            # For iterate many times on SQLA ProxyResult
            synthese_results = list(synthese_results)

            # If no result return output directly
            if len(synthese_results) == 0:
                return output

            geojson_by_synthese_ids = self._associate_geojson_to_synthese_id(
                synthese_results,
                exact_filters,
                ignored_object,
            )

            for result in synthese_results:
                synthese_id = getattr(result, "id_synthese")
                # Blurre/Erase geometry fields if necessary
                if synthese_id in geojson_by_synthese_ids:
                    # Transform RowProxy to dictionary for update values
                    result = dict(result)
                    result = self._erase_fields(result)
                    for col in self.geom_fields:
                        blurred_geometry = geojson_by_synthese_ids[synthese_id][col["output_field"]]
                        result[col["output_field"]] = blurred_geometry
                    # Re-convert to RowProxy object
                    if not self.result_to_dict:
                        result = namedtuple("RowProxy", result.keys())(*result.values())

                # Remove result with code 4 for sensitivity or diffusion_level
                if synthese_id not in self.non_diffusable:
                    output.append(result)

        return output


    def blurObservationsQuery(self, obs_query, geojson, json_obs, with_areas):
        (exact_filters, see_all) = self._compute_exact_filters()
        ignored_object = self._get_ignored_object(see_all)

        if ignored_object == "PRIVATE_AND_SENSITIVE":
            return obs_query.cte("OBSERVATIONS")
        else:
            areas_used_to_blur = self._get_distinct_config_areas_types_codes()
            areas_sizes = self._get_areas_size_hierarchy(areas_used_to_blur)
            blurring_types = ["PRIVATE_OBSERVATION", "SENSITIVE_OBSERVATION"]

            # Replace original selected columns
            columns = [
                self.data_table.id_synthese,
                self.data_table.id_nomenclature_diffusion_level,
                self.data_table.id_nomenclature_sensitivity,
                geojson,
            ]

            if with_areas:
                columns.append(BibAreasTypes.size_hierarchy.label("priority"))
                blurring_types = self._get_blurring_types(areas_sizes)
                if len(blurring_types) == 0:
                    return obs_query.cte("OBSERVATIONS")
                else:
                    obs_query = (
                        obs_query.with_only_columns(columns)
                        .distinct(self.data_table.id_synthese, self.data_table.date_min)
                    )
            else:
                obs_query = obs_query.with_only_columns(columns)

            # Add blur CTE queries
            output_query = self._add_blurred_cte_queries(
                obs_query.cte("OBSERVATIONS"),
                exact_filters,
                json_obs,
                blurring_types,
                areas_sizes,
                with_areas,
            )
            return output_query

    def _add_blurred_cte_queries(
        self, observations_query, exact_filters, json_obs, blurring_types, areas_sizes, with_areas
    ):
        diffusion_level_ids = self._get_diffusion_levels_area_types()
        sensitivity_ids = self._get_sensitivity_area_types()

        blurred_obs_queries = []
        # TODO: avoid to build private and sensitive queries when areas aggregation type is equal of superior
        for object_type in blurring_types:
            obs_geo_queries = []
            nomenclature_ids = (
                diffusion_level_ids if object_type == "PRIVATE_OBSERVATION" else sensitivity_ids
            )

            # Group nomenclatures by areas
            sorted_nomenclature_ids = defaultdict(list)
            for key, val in sorted(nomenclature_ids.items()):
                sorted_nomenclature_ids[val].append(key)

            for (
                area_type_id,
                area_type_code,
            ), nomenclature_ids_list in sorted_nomenclature_ids.items():
                # Build obs queries giving id_synthese and area geojson dispatched by object type
                priority = int(areas_sizes[area_type_code])
                obs_geo_query = select(
                    [
                        literal(priority).label("priority"),
                        observations_query.c.id_synthese,
                        LAreas.geojson_4326.label("geojson"),
                    ],
                    distinct=observations_query.c.id_synthese,
                ).select_from(
                    CorAreaSynthese.__table__.join(
                        LAreas, LAreas.id_area == CorAreaSynthese.id_area
                    ).join(
                        observations_query,
                        observations_query.c.id_synthese == CorAreaSynthese.id_synthese,
                    )
                )
                # Handle obs geo query conditions
                obs_geo_conditions = [LAreas.id_type == area_type_id]
                if object_type == "PRIVATE_OBSERVATION":
                    obs_geo_conditions.append(
                        observations_query.c.id_nomenclature_diffusion_level.in_(
                            nomenclature_ids_list
                        )
                    )
                elif object_type == "SENSITIVE_OBSERVATION":
                    obs_geo_conditions.append(
                        observations_query.c.id_nomenclature_sensitivity.in_(nomenclature_ids_list)
                    )
                obs_geo_query = obs_geo_query.where(and_(*obs_geo_conditions))

                obs_geo_queries.append(obs_geo_query)

            object_cte = union(*obs_geo_queries).cte(name=object_type)

            # Build blurred geom by id_synthese query
            blurred_obs_query = select(
                [object_cte.c.priority, object_cte.c.id_synthese, object_cte.c.geojson]
            ).select_from(object_cte)

            # Build permissions conditions
            if (
                object_type in exact_filters
                and exact_filters[object_type]
                and len(exact_filters[object_type]) > 0
            ):
                permissions_ors = self._get_permissions_where_clause(
                    exact_filters,
                    object_type,
                    nomenclature_ids.keys(),
                )

                # Build permissions NOT IN clause
                permissions_cte = (
                    select([object_cte.c.id_synthese])
                    .select_from(
                        object_cte.join(
                            Synthese.__table__, Synthese.id_synthese == object_cte.c.id_synthese
                        )
                        .join(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
                        .join(Taxref, Taxref.cd_nom == Synthese.cd_nom)
                    )
                    .where(or_(*permissions_ors))
                    .cte(name=f"{object_type}_PERM")
                )
                blurred_obs_query = blurred_obs_query.where(
                    object_cte.c.id_synthese.notin_(
                        select([permissions_cte.c.id_synthese])
                        .select_from(permissions_cte)
                    )
                )

            blurred_obs_queries.append(blurred_obs_query)

        # Add observations with size hierarchy 0 or areas aggregation size hierarchy
        columns = [observations_query.c.id_synthese, observations_query.c.geojson]
        if with_areas:
            columns.insert(0, observations_query.c.priority)
        else:
            columns.insert(0, literal(1).label("priority"))
        blurred_obs_queries.append(select(columns).select_from(observations_query))

        # Group all observations with union
        obs_subquery = union(*blurred_obs_queries).cte("OBS_ALL")

        # Manage areas geometry output
        if not with_areas:
            geom_column = obs_subquery.c.geojson
            select_from_clause = obs_subquery.join(
                self.data_table.__table__,
                self.data_table.id_synthese == obs_subquery.c.id_synthese,
            )
        else:
            area_type = current_app.config["SYNTHESE"]["AREA_AGGREGATION_TYPE"]
            size_area = self._get_area_aggregation_size_hierarchy(area_type)

            pick_one_agg_area = (
                select([LAreas.geojson_4326.label("geojson")])
                .select_from(
                    LAreas.__table__.join(BibAreasTypes, BibAreasTypes.id_type == LAreas.id_type)
                )
                .where(
                    and_(
                        BibAreasTypes.type_code == area_type,
                        func.ST_Intersects(
                            func.ST_GeomFromGeoJSON(obs_subquery.c.geojson),
                            func.ST_GeomFromGeoJSON(LAreas.geojson_4326),
                        ),
                    )
                )
                .lateral("CONTAINED_AGG_AREA")
            )

            geom_column = case(
                [(obs_subquery.c.priority > size_area, pick_one_agg_area.c.geojson)],
                else_=obs_subquery.c.geojson,
            ).label("geojson")

            select_from_clause = obs_subquery.join(
                self.data_table.__table__,
                self.data_table.id_synthese == obs_subquery.c.id_synthese,
            ).outerjoin(pick_one_agg_area, obs_subquery.c.priority > size_area)

        # Final query => Aggregate all observation infos inside JSON
        all_obs_query = (
            select(
                [obs_subquery.c.id_synthese, obs_subquery.c.priority, geom_column, json_obs],
                distinct=obs_subquery.c.id_synthese,
            )
            .select_from(select_from_clause)
            .order_by(obs_subquery.c.id_synthese, obs_subquery.c.priority.desc())
            .cte("BLURRED_OBSERVATIONS")
        )

        return all_obs_query

    def _get_blurring_types(self, areas_sizes):
        blurring_types = []
        area_agg_type = current_app.config["SYNTHESE"]["AREA_AGGREGATION_TYPE"]
        if area_agg_type in areas_sizes:
            area_agg_size = areas_sizes[area_agg_type]
        else:
            area_agg_size = self._get_area_aggregation_size_hierarchy(area_agg_type)

        # Sensitive levels
        areas_sensitive_levels = current_app.config["DATA_BLURRING"][
            "AREA_TYPE_FOR_SENSITIVITY_LEVELS"
        ]
        sensitive_areas = set([sub["area"] for sub in areas_sensitive_levels])
        add_sensitive = False
        for area_type in sensitive_areas:
            if areas_sizes[area_type] > area_agg_size:
                add_sensitive = True
        if add_sensitive:
            blurring_types.append("SENSITIVE_OBSERVATION")

        # Diffusion levels
        areas_diffusion_levels = current_app.config["DATA_BLURRING"][
            "AREA_TYPE_FOR_DIFFUSION_LEVELS"
        ]
        diffusion_level_areas = set([sub["area"] for sub in areas_diffusion_levels])
        add_diffusion_level = False
        for area_type in diffusion_level_areas:
            if areas_sizes[area_type] > area_agg_size:
                add_diffusion_level = True
        if add_diffusion_level:
            blurring_types.append("PRIVATE_OBSERVATION")

        return blurring_types



    def _compute_exact_filters(self):
        see_all = {
            "PRIVATE_OBSERVATION": False,
            "SENSITIVE_OBSERVATION": False,
        }
        exact_filters = {}
        for perm in self.permissions:
            filters = perm["filters"]
            types = filters.keys()
            if not self._have_exact_precision(filters):
                continue
            details = {
                "GEOGRAPHIC": filters["GEOGRAPHIC"] if "GEOGRAPHIC" in types else "ALL",
                "TAXONOMIC": filters["TAXONOMIC"] if "TAXONOMIC" in types else "ALL",
            }
            if (details["GEOGRAPHIC"] == "ALL" and details["TAXONOMIC"] == "ALL"):
                if perm["object"] == 'ALL':
                    see_all["PRIVATE_OBSERVATION"] = True
                    see_all["SENSITIVE_OBSERVATION"] = True
                else:
                    see_all[perm["object"]] = True
            exact_filters.setdefault(perm["object"], []).append(details)
        return (exact_filters, see_all)

    def _have_exact_precision(self, filters):
        has_precision = True if "PRECISION" in filters else False
        return True if (has_precision and filters["PRECISION"] == "exact") else False

    def _get_ignored_object(self, see_all):
        ignored_object = None
        if see_all["PRIVATE_OBSERVATION"] and see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "PRIVATE_AND_SENSITIVE"
        elif see_all["PRIVATE_OBSERVATION"] and not see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "PRIVATE_OBSERVATION"
        elif not see_all["PRIVATE_OBSERVATION"] and see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "SENSITIVE_OBSERVATION"
        elif not see_all["PRIVATE_OBSERVATION"] and not see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "NONE"
        return ignored_object

    def _associate_geojson_to_synthese_id(self, synthese_results, exact_filters, ignored_object):
        areas_used_to_blur = self._get_distinct_config_areas_types_codes()
        areas_sizes = self._get_areas_size_hierarchy(areas_used_to_blur)

        sorted_synthese_by_area_type = self._sort_synthese_id_by_area_type_id(synthese_results, ignored_object)
        if not sorted_synthese_by_area_type:
            return {}

        diffusion_level_ids = self._get_diffusion_levels_area_types().keys()
        sensitivity_ids = self._get_sensitivity_area_types().keys()

        blurred_obs_queries = []
        for object_type, synthese_by_area_type in sorted_synthese_by_area_type.items():
            obs_geo_queries = []
            for (area_type_id, area_type_code), synthese_ids in synthese_by_area_type.items():
                # Build obs queries giving id_synthese dispatched by object and area type
                name = f"{object_type}_{area_type_code}"
                # TODO: replace by Values() with SQLAlchemy v1.4+
                # See: https://stackoverflow.com/a/66332616/13311850
                values = self._build_values_clause(synthese_ids)
                priority = int(areas_sizes[area_type_code])
                obs_cte = (
                    select([literal(priority).label("priority"), column('id_synthese')])
                    .select_from(text(f"(VALUES {values}) AS t (id_synthese)"))
                    .cte(name=name)
                )

                # Build obs queries giving id_synthese and area geojson dispatched by object type
                geom_columns = self._prepare_geom_columns(LAreas, with_compute=True)
                obs_geo_query = (
                    select(
                        [obs_cte.c.priority, obs_cte.c.id_synthese, *geom_columns],
                        distinct=obs_cte.c.id_synthese,
                    )
                    .select_from(
                        CorAreaSynthese.__table__
                        .join(LAreas, LAreas.id_area == CorAreaSynthese.id_area)
                        .join(obs_cte, obs_cte.c.id_synthese == CorAreaSynthese.id_synthese)
                    )
                    .where(LAreas.id_type == area_type_id)
                )
                obs_geo_queries.append(obs_geo_query)

            object_cte = union(*obs_geo_queries).cte(name=object_type)

            # Build blurred geom by id_synthese query
            geom_columns = self._prepare_geom_columns(object_cte)
            blurred_obs_query = (
                select([object_cte.c.priority, object_cte.c.id_synthese, *geom_columns])
                .select_from(object_cte)
            )

            # Build permissions conditions
            if object_type in exact_filters and exact_filters[object_type] and len(exact_filters[object_type]) > 0 :
                nomenclature_ids = (
                    diffusion_level_ids
                    if object_type == "PRIVATE_OBSERVATION"
                    else sensitivity_ids
                )

                permissions_ors = self._get_permissions_where_clause(
                    exact_filters,
                    object_type,
                    nomenclature_ids,
                )

                # Build permissions NOT IN clause
                permissions_cte = (
                    select([object_cte.c.id_synthese])
                    .select_from(object_cte
                        .join(Synthese.__table__, Synthese.id_synthese == object_cte.c.id_synthese)
                        .join(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
                        .join(Taxref, Taxref.cd_nom == Synthese.cd_nom)
                    )
                    .where(or_(*permissions_ors))
                    .cte(name=f"{object_type}_PERM")
                )
                blurred_obs_query = blurred_obs_query.where(
                    object_cte.c.id_synthese.notin_(
                        select([permissions_cte.c.id_synthese])
                        .select_from(permissions_cte)
                    )
                )

            blurred_obs_queries.append(blurred_obs_query)

        # Build final query
        obs_subquery = union(*blurred_obs_queries).alias("obs")
        geom_columns = self._prepare_geom_columns(obs_subquery)
        query = (
            select(
                [obs_subquery.c.id_synthese, obs_subquery.c.priority, *geom_columns],
                distinct=obs_subquery.c.id_synthese,
            )
            .select_from(obs_subquery)
            .order_by(obs_subquery.c.id_synthese, obs_subquery.c.priority.desc())
        )

        # DEBUG QUERY:
        from sqlalchemy.dialects import postgresql
        print(query.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}))
        #exit()

        results = DB.session.execute(query)
        geojson_by_synthese_ids = {}
        for result in results:
            result = dict(result)
            synthese_id = result["id_synthese"]
            del result["id_synthese"]
            geojson_by_synthese_ids[synthese_id] = result
        return geojson_by_synthese_ids

    def _prepare_geom_columns(self, table, with_compute=False):
        columns = []
        for field in self.geom_fields:
            label = field["output_field"]
            if with_compute:
                srid = func.Find_SRID("ref_geo", "l_areas", "geom")
                larea_col = getattr(table, field.get("area_field", "geom"))
                compute = field.get("compute", None)
                if compute == "x":
                    geocolumn = func.ST_X(func.ST_Transform(func.ST_Centroid(larea_col), srid))
                elif compute == "y":
                    geocolumn = func.ST_Y(func.ST_Transform(func.ST_Centroid(larea_col), srid))
                elif compute == "astext":
                    geocolumn = func.ST_AsText(func.ST_Transform(larea_col, srid))
                elif compute == "asgeojson":
                    geocolumn = func.ST_AsGeoJSON(func.ST_Transform(larea_col, srid))
                else:
                    geocolumn = larea_col
                columns.append(geocolumn.label(label))
            else:
                columns.append(column(label))
        return columns

    def _get_area_aggregation_size_hierarchy(self, area_type):
        query = (
            select([BibAreasTypes.size_hierarchy])
            .select_from(BibAreasTypes)
            .where(BibAreasTypes.type_code == area_type)
        )
        results = DB.session.execute(query)
        area_size = results.fetchone()[0]
        return int(area_size)

    def _sort_synthese_id_by_area_type_id(self, synthese_results, ignored_object):
        sorted_ids = {}
        area_type_by_diffusion_level = self._get_diffusion_levels_area_types()
        area_type_by_sensitivity = self._get_sensitivity_area_types()
        for result in synthese_results:
            if self._remove_non_diffusable(result):
                continue

            if ignored_object != "PRIVATE_OBSERVATION":
                diffusion_level_id = result[self.diffusion_column]
                if diffusion_level_id in area_type_by_diffusion_level:
                    (area_type_id, area_type_code) = area_type_by_diffusion_level[diffusion_level_id]
                    (
                        sorted_ids
                        .setdefault("PRIVATE_OBSERVATION", {})
                        .setdefault((area_type_id, area_type_code), [])
                        .append(result["id_synthese"])
                    )

            if ignored_object != "SENSITIVE_OBSERVATION":
                sensitivity_id = result[self.sensitivity_column]
                if sensitivity_id in area_type_by_sensitivity:
                    (area_type_id, area_type_code) = area_type_by_sensitivity[sensitivity_id]
                    (
                        sorted_ids
                        .setdefault("SENSITIVE_OBSERVATION", {})
                        .setdefault((area_type_id, area_type_code), [])
                        .append(result["id_synthese"])
                    )
        return sorted_ids

    def _build_values_clause(self, ids):
        values = []
        for val in ids:
            values.append(f"({val})")
        return ', '.join(values)

    def _get_diffusion_levels_area_types(self):
        area_types_by_diffusion_levels = self._get_diffusion_level_area_type_codes()
        area_type_codes = list(set(area_types_by_diffusion_levels.values()))
        area_type_ids = self._get_area_types_ids_by_codes(area_type_codes)

        area_types_by_diffusion_levels_ids = {}
        for level_code, area_type_code in area_types_by_diffusion_levels.items():
            diffusion_level_id = self.diffusion_levels_ids[level_code]
            area_type_id = area_type_ids[area_type_code]
            area_types_by_diffusion_levels_ids[diffusion_level_id] = (area_type_id, area_type_code)
        return area_types_by_diffusion_levels_ids

    def _get_diffusion_levels(self):
        query = (
            select([TNomenclatures.id_nomenclature, TNomenclatures.cd_nomenclature])
            .select_from(
                TNomenclatures.__table__.join(
                    BibNomenclaturesTypes, BibNomenclaturesTypes.id_type == TNomenclatures.id_type
                )
            )
            .where(BibNomenclaturesTypes.mnemonique == "NIV_PRECIS")
        )
        results = DB.session.execute(query)

        diffusion_levels = {}
        for (nomenclature_id, nomenclature_code) in results:
            diffusion_levels[nomenclature_code] = nomenclature_id
        return diffusion_levels

    def _get_diffusion_level_area_type_codes(self):
        cfg_parameters = current_app.config["DATA_BLURRING"]["AREA_TYPE_FOR_DIFFUSION_LEVELS"]
        area_type_for_diffusion_levels = {}
        for param in cfg_parameters:
            area_type_for_diffusion_levels[param["level"]] = param["area"]
        return area_type_for_diffusion_levels

    def _remove_non_diffusable(self, result):
        diffusion_level_id = result[self.diffusion_column]
        sensitivity_id = result[self.sensitivity_column]
        if (
            self.diffusion_levels_ids["4"] == diffusion_level_id
            or self.sensitivity_ids["4"] == sensitivity_id
        ):
            self.non_diffusable.append(result["id_synthese"])
            return True
        else:
            return False

    def _get_sensitivity_area_types(self):
        area_types_by_sensitivity = self._get_sensitivity_area_type_codes()
        area_types = list(set(area_types_by_sensitivity.values()))
        area_types_ids = self._get_area_types_ids_by_codes(area_types)

        area_types_by_sensitivity_ids = {}
        for level_code, area_type_code in area_types_by_sensitivity.items():
            sensitivity_id = self.sensitivity_ids[level_code]
            area_type_id = area_types_ids[area_type_code]
            area_types_by_sensitivity_ids[sensitivity_id] = (area_type_id, area_type_code)
        return area_types_by_sensitivity_ids

    def _get_sensitivity_area_type_codes(self):
        cfg_parameters = current_app.config["DATA_BLURRING"]["AREA_TYPE_FOR_SENSITIVITY_LEVELS"]
        area_type_for_sensitivity = {}
        for param in cfg_parameters:
            area_type_for_sensitivity[param["level"]] = param["area"]
        return area_type_for_sensitivity

    def _get_area_types_ids_by_codes(self, area_type_codes):
        query = (
            select([BibAreasTypes.id_type, BibAreasTypes.type_code])
            .where(BibAreasTypes.type_code.in_(area_type_codes))
        )
        results = DB.session.execute(query)

        area_types_ids = {}
        for (type_id, type_code) in results:
            area_types_ids[type_code] = type_id
        return area_types_ids

    def _get_sensitivity_levels(self):
        query = (
            select([TNomenclatures.id_nomenclature, TNomenclatures.cd_nomenclature])
            .select_from(
                TNomenclatures.__table__.join(
                    BibNomenclaturesTypes, BibNomenclaturesTypes.id_type == TNomenclatures.id_type
                )
            )
            .where(BibNomenclaturesTypes.mnemonique == "SENSIBILITE")
        )
        results = DB.session.execute(query)

        sensitivity_levels = {}
        for (nomenclature_id, nomenclature_code) in results:
            sensitivity_levels[nomenclature_code] = nomenclature_id
        return sensitivity_levels

    def _split_value_filter(self, data: str):
        if data == None or data == '':
            return []
        values = data.split(',')
        # Cas to integer
        values = list(map(int, values))
        return values

    def _erase_fields(self, record):
        if self.fields_to_erase:
            for field in self.fields_to_erase:
                if hasattr(record, field):
                    setattr(record, field, None)
        return record


    def blurOneObsAreas(self, obs):
        # Get area blurred types
        blurred_areas_types = []
        id_synthese = obs["id"]

        current_diffusion_level_id = obs["properties"]["id_nomenclature_diffusion_level"]
        diffusion_levels = self._get_diffusion_levels_area_types()
        if (
            current_diffusion_level_id != None
            and current_diffusion_level_id in diffusion_levels
            and not self.haveAccessToDiffusionLevels(id_synthese)
        ):
            (area_id, area_type) = diffusion_levels[current_diffusion_level_id]
            blurred_areas_types.append(area_type)
        current_sensitivity_id = obs["properties"]["id_nomenclature_sensitivity"]
        sensitivity_levels = self._get_sensitivity_area_types()
        if (
            current_sensitivity_id != None
            and current_sensitivity_id in sensitivity_levels
            and not self.haveAccessToSensitivityLevels(id_synthese)
        ):
            (area_id, area_type) = sensitivity_levels[current_sensitivity_id]
            blurred_areas_types.append(area_type)

        # Remove duplicates entries
        blurred_areas_types = list(dict.fromkeys(blurred_areas_types))

        # Get more restrictive area size
        blurred_areas_sizes = self._get_areas_size_hierarchy(blurred_areas_types)
        more_restrictive_size = None
        for size in blurred_areas_sizes.values():
            if more_restrictive_size == None or more_restrictive_size < size:
                more_restrictive_size = int(size)

        # Remove too precise areas
        if more_restrictive_size != None and "areas" in obs["properties"]:
            obs["properties"]["areas"][:] = [area for area in obs["properties"]["areas"] if DataBlurring._checkAreaSize(area, more_restrictive_size)]

        return obs

    def _get_areas_size_hierarchy(self, areas_types):
        query = (
            select([BibAreasTypes.type_code, BibAreasTypes.size_hierarchy])
            .select_from(BibAreasTypes.__table__)
            .where(BibAreasTypes.type_code.in_(areas_types))
        )
        results = DB.session.execute(query)

        areas_hierarchy = {}
        for (type_code, size) in results:
            if size == None:
                msg = f"Field size hierarchy for type {type_code} is not defined in database."
                self.log.warn(msg)
                size = 1
            areas_hierarchy[type_code] = size
        return areas_hierarchy

    def haveAccessToDiffusionLevels(self, id_synthese):
        have_access = False
        (exact_filters, see_all) = self._compute_exact_filters()

        if see_all["PRIVATE_OBSERVATION"]:
            have_access = True
        elif (
            "PRIVATE_OBSERVATION" in exact_filters
            and len(exact_filters["PRIVATE_OBSERVATION"]) > 0
        ):
            permissions_ors = self._get_permissions_where_clause(
                exact_filters,
                "PRIVATE_OBSERVATION",
                self._get_diffusion_levels_area_types().keys(),
            )

            # Build permissions query
            query = (
                select([Synthese.id_synthese])
                .select_from(Synthese.__table__
                    .join(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
                    .join(Taxref, Taxref.cd_nom == Synthese.cd_nom)
                )
                .where(or_(*permissions_ors))
                .where(Synthese.id_synthese == id_synthese)
            )

            # DEBUG QUERY:
            #from sqlalchemy.dialects import postgresql
            #print(query.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}))

            results = DB.session.execute(query)
            if results.first() is not None:
                have_access = True

        return have_access

    def haveAccessToSensitivityLevels(self, id_synthese):
        have_access = False
        (exact_filters, see_all) = self._compute_exact_filters()

        if see_all["SENSITIVE_OBSERVATION"]:
            have_access = True
        elif (
            "SENSITIVE_OBSERVATION" in exact_filters
            and len(exact_filters["SENSITIVE_OBSERVATION"]) > 0
        ):
            permissions_ors = self._get_permissions_where_clause(
                exact_filters,
                "SENSITIVE_OBSERVATION",
                self._get_sensitivity_area_types().keys(),
            )

            # Build permissions query
            query = (
                select([Synthese.id_synthese])
                .select_from(Synthese.__table__
                    .join(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
                    .join(Taxref, Taxref.cd_nom == Synthese.cd_nom)
                )
                .where(or_(*permissions_ors))
                .where(Synthese.id_synthese == id_synthese)
            )

            # DEBUG QUERY:
            #from sqlalchemy.dialects import postgresql
            #print(query.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}))

            results = DB.session.execute(query)
            if results.first() is not None:
                have_access = True

        return have_access

    def _get_permissions_where_clause(self, exact_filters, object_type, nomenclature_ids):
        permissions_ors = []
        for exact_filter in exact_filters[object_type]:
            conditions = []

            if object_type == "PRIVATE_OBSERVATION":
                conditions.append(Synthese.id_nomenclature_diffusion_level.in_(nomenclature_ids))
            elif object_type == "SENSITIVE_OBSERVATION":
                conditions.append(Synthese.id_nomenclature_sensitivity.in_(nomenclature_ids))

            if "GEOGRAPHIC" in exact_filter.keys() and exact_filter["GEOGRAPHIC"] != "ALL":
                filter_value = exact_filter["GEOGRAPHIC"]
                splited_values = self._split_value_filter(filter_value)
                conditions.append(CorAreaSynthese.id_area.in_(splited_values))

            if "TAXONOMIC" in exact_filter.keys() and exact_filter["TAXONOMIC"] != "ALL":
                filter_value = exact_filter["TAXONOMIC"]
                splited_values = self._split_value_filter(filter_value)
                stmt = (
                    DB.select([column("cd_ref")])
                    .select_from(func.taxonomie.find_all_taxons_children(splited_values))
                )
                conditions.append(Taxref.cd_ref.in_(stmt))
            permissions_ors.append(and_(*conditions))

        return permissions_ors

    @staticmethod
    def _checkAreaSize(area, more_restrictive_size):
        current_size = area['area_type']['size_hierarchy']
        return (False if current_size != None and current_size < more_restrictive_size else True)

    def _get_distinct_config_areas_types_codes(self):
        areas_codes = []
        sensitivity = self._get_sensitivity_area_type_codes()
        for code in sensitivity.values():
            areas_codes.append(code)
        diffusion = self._get_diffusion_level_area_type_codes()
        for code in diffusion.values():
            areas_codes.append(code)
        # Remove duplicates entries
        return list(dict.fromkeys(areas_codes))
