from geonature.utils.env import MA
from marshmallow import pre_load, fields, EXCLUDE
from .models import (
    TDatasets,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
    CorDatasetActor,
    TBibliographicReference
)
from pypnusershub.schemas import UserSchema, OrganismeSchema
from pypnnomenclature.schemas import NomenclatureSchema
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_commons.schemas import ModuleSchema

class MetadataSchema(MA.SQLAlchemyAutoSchema):
    cruved = fields.Method("get_user_cruved")

    def get_user_cruved(self, obj):
        if 'info_role' in self.context and 'user_cruved' in self.context:
            return obj.get_object_cruved(self.context['info_role'], self.context['user_cruved'])
        return None


class DatasetActorSchema(MA.SQLAlchemyAutoSchema):
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

class DatasetSchema(MetadataSchema):
    class Meta:
        model = TDatasets
        load_instance = True
        include_fk = True

    meta_create_date = fields.DateTime(dump_only=True)
    meta_update_date = fields.DateTime(dump_only=True)
    cor_dataset_actor = MA.Nested(
        DatasetActorSchema,
        many=True,
        unknown=EXCLUDE
    )
    modules = MA.Nested(
        ModuleSchema, 
        many=True, 
        exclude=("meta_create_date", "meta_update_date")
    )

    creator = MA.Nested(UserSchema, dump_only=True)
    nomenclature_data_type = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_dataset_objectif = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_collecting_method = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_data_origin = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_source_status = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_resource_type = MA.Nested(NomenclatureSchema, dump_only=True)
    cor_territories = MA.Nested(
        NomenclatureSchema,
        many=True
    )
    acquisition_framework = MA.Nested("AcquisitionFrameworkSchema", exclude=("t_datasets",), dump_only=True)


class BibliographicReferenceSchema(MetadataSchema):
    class Meta:
        model = TBibliographicReference
        load_instance = True
        include_fk = True

    acquisition_framework = MA.Nested("AcquisitionFrameworkSchema", exclude=("bibliographical_references",), dump_only=True)

    @pre_load
    def make_biblio_ref(self, data, **kwargs):
        print(data)
        if data.get("id_bibliographic_reference") is None:
            data.pop("id_bibliographic_reference", None)
        return data


class AcquisitionFrameworkActorSchema(MA.SQLAlchemyAutoSchema):
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


class AcquisitionFrameworkSchema(MetadataSchema):
    class Meta:
        model = TAcquisitionFramework
        load_instance = True
        include_fk = True
    meta_create_date = fields.DateTime(dump_only=True)
    meta_update_date = fields.DateTime(dump_only=True)
    t_datasets = MA.Nested(
        DatasetSchema(
            exclude=(
                "acquisition_framework",
                "modules",
                "nomenclature_dataset_objectif",
                "nomenclature_collecting_method",
                "nomenclature_data_origin",
                "nomenclature_source_status",
                "nomenclature_resource_type",
            ),
            many=True,
        ),
        many=True
    )
    bibliographical_references = MA.Nested(
        BibliographicReferenceSchema(
            exclude=(
                "acquisition_framework",
            ),
            many=True,
        )
        , many=True,
    )
    cor_af_actor = MA.Nested(
        AcquisitionFrameworkActorSchema,
        many=True,
        unknown=EXCLUDE
    )
    cor_volets_sinp = MA.Nested(
        NomenclatureSchema,
        many=True,
    )
    cor_objectifs = MA.Nested(
        NomenclatureSchema,
        many=True
    )
    cor_territories = MA.Nested(
        NomenclatureSchema,
        many=True,
        unknown=EXCLUDE
    )
    nomenclature_territorial_level = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_financing_type = MA.Nested(NomenclatureSchema, dump_only=True)
    creator = MA.Nested(UserSchema, dump_only=True)