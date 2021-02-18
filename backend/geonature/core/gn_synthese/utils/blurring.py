import json
from collections import namedtuple

from flask import current_app
from sqlalchemy import (func, not_, and_, or_, select, column)

from pypnnomenclature.models import (
    TNomenclatures,
    BibNomenclaturesTypes,
)

from geonature.core.gn_synthese.models import (CorAreaSynthese, Synthese)
from geonature.core.ref_geo.models import (LAreas, BibAreasTypes)
from geonature.core.taxonomie.models import Taxref
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
        ]
    ):
        self.permissions = permissions
        self.sensitivity_column = sensitivity_column
        self.diffusion_column = diffusion_column
        self.result_to_dict = result_to_dict
        self.fields_to_erase = fields_to_erase
        self.geom_fields = geom_fields
        self.diffusion_levels_ids = self._get_diffusion_levels()
        self.sensitivity_ids = self._get_sensitivity_levels()
        self.non_diffusable = []

    def blurre(self, synthese_results):
        (exact_filters, see_all) = self._compute_exact_filters()
        ignored_object = self._get_ignored_object(see_all)
        
        output = []
        if ignored_object == "NONE":
            output = synthese_results
        else:
            # For iterate many times on SQLA ProxyResult
            synthese_results = list(synthese_results)
            geojson_by_synthese_ids = self._associate_geojson_to_synthese_id(
                synthese_results, 
                exact_filters,
                ignored_object,
            )

            for result in synthese_results:
                synthese_id = getattr(result, "id_synthese")
                # Blurre/Erase geometry fields if necessary
                if synthese_id in geojson_by_synthese_ids.keys():
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
                see_all[perm["object"]] = True
            exact_filters.setdefault(perm["object"], []).append(details)
        return (exact_filters, see_all)

    def _have_exact_precision(self, filters):
        has_precision = True if "PRECISION" in filters.keys() else False
        return True if (has_precision and filters["PRECISION"] == "exact") else False

    def _get_ignored_object(self, see_all):
        ignored_object = None
        if see_all["PRIVATE_OBSERVATION"] and see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "NONE"
        elif see_all["PRIVATE_OBSERVATION"] and not see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "PRIVATE_OBSERVATION"
        elif not see_all["PRIVATE_OBSERVATION"] and see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "SENSITIVE_OBSERVATION"
        elif not see_all["PRIVATE_OBSERVATION"] and not see_all["SENSITIVE_OBSERVATION"]:
            ignored_object = "PRIVATE_AND_SENSITIVE"
        return ignored_object

    def _associate_geojson_to_synthese_id(self, synthese_results, exact_filters, ignored_object):
        sorted_synthese_by_area_type = self._sort_synthese_id_by_area_type_id(synthese_results, ignored_object)
        diffusion_level_ids = self._get_diffusion_levels_area_types().keys()
        sensitivity_ids = self._get_sensitivity_area_types().keys()
        columns = self._prepare_geom_columns()
        
        query = (DB.session
            .query(CorAreaSynthese.id_synthese, *columns)
            .join(LAreas, LAreas.id_area == CorAreaSynthese.id_area)
        )

        ors_object_types = []
        for object_type, synthese_by_area_type in sorted_synthese_by_area_type.items():
            ors_area_types = []
            for area_type_id, synthese_ids in synthese_by_area_type.items():
                ors_area_types.append(LAreas.id_type == area_type_id)
                ors_area_types.append(CorAreaSynthese.id_synthese.in_(synthese_ids))

            if exact_filters[object_type] and len(exact_filters[object_type]) > 0 :
                ors = []
                for exact_filter in exact_filters[object_type]:
                    conditions = []
                    
                    if object_type == "PRIVATE_OBSERVATION":
                        conditions.append(Synthese.id_nomenclature_diffusion_level.in_(diffusion_level_ids))
                    elif object_type == "SENSITIVE_OBSERVATION":
                        conditions.append(Synthese.id_nomenclature_sensitivity.in_(sensitivity_ids))

                    if "GEOGRAPHIC" in exact_filter.keys() and exact_filter["GEOGRAPHIC"] != "ALL":
                        filter_value = exact_filter["GEOGRAPHIC"]
                        splited_values = self._split_value_filter(filter_value)
                        conditions.append(CorAreaSynthese.id_area.in_(splited_values))
                    
                    if "TAXONOMIC" in exact_filter.keys() and exact_filter["TAXONOMIC"] != "ALL":
                        filter_value = exact_filter["TAXONOMIC"]
                        splited_values = self._split_value_filter(filter_value)
                        stmt = (
                            DB.select([column("cd_ref")])
                            .select_from(func.taxonomie.find_all_taxons_children(*splited_values))
                        )
                        conditions.append(Taxref.cd_ref.in_(stmt))
                    ors.append(and_(*conditions))
                
                # TODO: replace not_ in_ by NOT EXISTS (most efficient)
                subquery = (DB.session
                    .query(Synthese.id_synthese)
                    .join(CorAreaSynthese, CorAreaSynthese.id_synthese == Synthese.id_synthese)
                    .join(Taxref, Taxref.cd_nom == Synthese.cd_nom)
                    .filter(or_(*ors))
                    .subquery()
                )
                ors_area_types.append(not_(CorAreaSynthese.id_synthese.in_(subquery)))
            
            ors_object_types.append(and_(*ors_area_types))
            
        query = query.filter(or_(*ors_object_types))

        #from sqlalchemy.dialects import postgresql
        #print(query.statement.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}))
        
        results = query.all()
        geojson_by_synthese_ids = {}
        for result in results:
            # TODO: try to find an alternative to _asdict()
            result = result._asdict()
            synthese_id = result["id_synthese"] 
            del result["id_synthese"]
            geojson_by_synthese_ids[synthese_id] = result
        return geojson_by_synthese_ids

    def _prepare_geom_columns(self):
        columns = []
        for field in self.geom_fields:
            larea_col = getattr(LAreas, field.get("area_field", "geom"))
            srid = field.get("srid", 4326)
            label = field["output_field"]
            compute = field.get("compute", None)
            if compute == "x":
                column = func.ST_X(func.ST_Transform(func.ST_Centroid(larea_col), srid))
            elif compute == "y":
                column = func.ST_Y(func.ST_Transform(func.ST_Centroid(larea_col), srid))
            elif compute == "astext":
                column = func.ST_AsText(func.ST_Transform(larea_col, srid))
            elif compute == "asgeojson":
                column = func.ST_AsGeoJSON(func.ST_Transform(larea_col, srid))
            else:
                column = larea_col
            columns.append(column.label(label))
        return columns

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
                    area_type_id = area_type_by_diffusion_level[diffusion_level_id]
                    (
                        sorted_ids
                        .setdefault("PRIVATE_OBSERVATION", {})
                        .setdefault(area_type_id, [])
                        .append(result["id_synthese"])
                    )
            
            if ignored_object != "SENSITIVE_OBSERVATION":
                sensitivity_id = result[self.sensitivity_column]
                if sensitivity_id in area_type_by_sensitivity:
                    area_type_id = area_type_by_sensitivity[sensitivity_id]
                    (
                        sorted_ids
                        .setdefault("SENSITIVE_OBSERVATION", {})
                        .setdefault(area_type_id, [])
                        .append(result["id_synthese"])
                    )
        return sorted_ids


    def _get_diffusion_levels_area_types(self):
        area_types_by_diffusion_levels = self._get_diffusion_level_area_type_codes()
        area_type_codes = list(set(area_types_by_diffusion_levels.values()))
        area_type_ids = self._get_area_types_ids_by_codes(area_type_codes)
        
        area_types_by_diffusion_levels_ids = {}
        for level_code, area_type_code in area_types_by_diffusion_levels.items():
            diffusion_level_id = self.diffusion_levels_ids[level_code]
            area_type_id = area_type_ids[area_type_code]
            area_types_by_diffusion_levels_ids[diffusion_level_id] = area_type_id
        return area_types_by_diffusion_levels_ids


    def _get_diffusion_levels(self):
        query = (DB.session
            .query(TNomenclatures.id_nomenclature, TNomenclatures.cd_nomenclature)
            .join(BibNomenclaturesTypes, BibNomenclaturesTypes.id_type == TNomenclatures.id_type)
            .filter(BibNomenclaturesTypes.mnemonique == "NIV_PRECIS")
        )
        results = query.all()

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
            area_types_by_sensitivity_ids[sensitivity_id] = area_type_id
        return area_types_by_sensitivity_ids


    def _get_sensitivity_area_type_codes(self):
        cfg_parameters = current_app.config["DATA_BLURRING"]["AREA_TYPE_FOR_SENSITIVITY_LEVELS"]
        area_type_for_sensitivity = {}
        for param in cfg_parameters:
            area_type_for_sensitivity[param["level"]] = param["area"]
        return area_type_for_sensitivity


    def _get_area_types_ids_by_codes(self, area_type_codes):
        query = (DB.session
            .query(BibAreasTypes.id_type, BibAreasTypes.type_code)
            .filter(BibAreasTypes.type_code.in_(area_type_codes))
        )
        results = query.all()
    
        area_types_ids = {}
        for (type_id, type_code) in results:
            area_types_ids[type_code] = type_id
        return area_types_ids


    def _get_sensitivity_levels(self):
        query = (DB.session
            .query(TNomenclatures.id_nomenclature, TNomenclatures.cd_nomenclature)
            .join(BibNomenclaturesTypes, BibNomenclaturesTypes.id_type == TNomenclatures.id_type)
            .filter(BibNomenclaturesTypes.mnemonique == "SENSIBILITE")
        )
        results = query.all()

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
