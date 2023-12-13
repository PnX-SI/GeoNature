from sqlalchemy import inspect
from marshmallow import pre_load, post_dump, fields, EXCLUDE
from flask import g

from .models import (
    TDatasets,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
    CorDatasetActor,
    TBibliographicReference,
)
from geonature.utils.env import MA
from geonature.utils.schema import CruvedSchemaMixin
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_commons.schemas import ModuleSchema
from geonature.core.gn_permissions.tools import get_scopes_by_action

from utils_flask_sqla.schema import SmartRelationshipsMixin
from pypnusershub.schemas import UserSchema, OrganismeSchema
from pypnnomenclature.schemas import NomenclatureSchema


class DatasetActorSchema(SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema):
    class Meta:
        model = CorDatasetActor
        load_instance = True
        include_fk = True

    role = MA.Nested(UserSchema, dump_only=True)
    nomenclature_actor_role = MA.Nested(NomenclatureSchema, dump_only=True)
    organism = MA.Nested(OrganismeSchema, dump_only=True)

    @pre_load
    def make_dataset_actor(self, data, **kwargs):
        if data.get("id_cda") is None:
            data.pop("id_cda", None)
        return data


class DatasetSchema(CruvedSchemaMixin, SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TDatasets
        load_instance = True
        include_fk = True

    __module_code__ = "METADATA"

    meta_create_date = fields.DateTime(dump_only=True)
    meta_update_date = fields.DateTime(dump_only=True)
    cor_dataset_actor = MA.Nested(DatasetActorSchema, many=True, unknown=EXCLUDE)
    modules = MA.Nested(
        ModuleSchema, many=True, exclude=("meta_create_date", "meta_update_date"), unknown=EXCLUDE
    )

    creator = MA.Nested(UserSchema, dump_only=True)
    nomenclature_data_type = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_dataset_objectif = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_collecting_method = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_data_origin = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_source_status = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_resource_type = MA.Nested(NomenclatureSchema, dump_only=True)
    cor_territories = MA.Nested(NomenclatureSchema, many=True, unknown=EXCLUDE)
    acquisition_framework = MA.Nested("AcquisitionFrameworkSchema", dump_only=True)
    sources = MA.Nested("SourceSchema", many=True, dump_only=True)

    @post_dump(pass_many=False, pass_original=True)
    def module_input(self, item, original, many, **kwargs):
        if "modules" in item:
            for i, module in enumerate(original.modules):
                if not hasattr(module, "generate_input_url_for_dataset"):
                    continue
                object_code = getattr(module.generate_input_url_for_dataset, "object_code", "ALL")
                create_scope = get_scopes_by_action(
                    id_role=g.current_user.id_role,
                    module_code=module.module_code,
                    object_code=object_code,
                )["C"]
                if not original.has_instance_permission(create_scope):
                    continue
                item["modules"][i].update(
                    {
                        "input_url": module.generate_input_url_for_dataset(original),
                        "input_label": module.generate_input_url_for_dataset.label,
                    }
                )
        return item

    # retro-compatibility with mobile app
    @post_dump(pass_many=True, pass_original=True)
    def mobile_app_compat(self, data, original, many, **kwargs):
        if self.context.get("mobile_app"):
            if many:
                for ds, orig_ds in zip(data, original):
                    ds["meta_create_date"] = str(orig_ds.meta_create_date)
                data = {"data": data}
            else:
                data["meta_create_date"] = str(original.meta_create_date)
        return data


class BibliographicReferenceSchema(SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TBibliographicReference
        load_instance = True
        include_fk = True

    acquisition_framework = MA.Nested("AcquisitionFrameworkSchema", dump_only=True)

    @pre_load
    def make_biblio_ref(self, data, **kwargs):
        if data.get("id_bibliographic_reference") is None:
            data.pop("id_bibliographic_reference", None)
        return data


class AcquisitionFrameworkActorSchema(SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema):
    class Meta:
        model = CorAcquisitionFrameworkActor
        load_instance = True
        include_fk = True

    role = MA.Nested(UserSchema, dump_only=True)
    nomenclature_actor_role = MA.Nested(NomenclatureSchema, dump_only=True)
    organism = MA.Nested(OrganismeSchema, dump_only=True)
    cor_volets_sinp = MA.Nested(OrganismeSchema, dump_only=True)

    @pre_load
    def make_af_actor(self, data, **kwargs):
        if data.get("id_cafa") is None:
            data.pop("id_cafa", None)
        return data


class AcquisitionFrameworkSchema(
    CruvedSchemaMixin, SmartRelationshipsMixin, MA.SQLAlchemyAutoSchema
):
    class Meta:
        model = TAcquisitionFramework
        load_instance = True
        include_fk = True

    __module_code__ = "METADATA"

    meta_create_date = fields.DateTime(dump_only=True)
    meta_update_date = fields.DateTime(dump_only=True)
    t_datasets = MA.Nested(DatasetSchema, many=True)
    datasets = MA.Nested(DatasetSchema, many=True)
    bibliographical_references = MA.Nested(BibliographicReferenceSchema, many=True)
    cor_af_actor = MA.Nested(AcquisitionFrameworkActorSchema, many=True, unknown=EXCLUDE)
    cor_volets_sinp = MA.Nested(NomenclatureSchema, many=True, unknown=EXCLUDE)
    cor_objectifs = MA.Nested(NomenclatureSchema, many=True, unknown=EXCLUDE)
    cor_territories = MA.Nested(NomenclatureSchema, many=True, unknown=EXCLUDE)
    nomenclature_territorial_level = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_financing_type = MA.Nested(NomenclatureSchema, dump_only=True)
    creator = MA.Nested(UserSchema, dump_only=True)
