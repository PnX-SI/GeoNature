from geonature.utils.env import MA
from marshmallow import pre_load, fields
from .models import (
    TDatasets,
    TAcquisitionFramework,
    CorAcquisitionFrameworkActor,
    CorDatasetActor,
    CorAcquisitionFrameworkVoletSINP,
    CorAcquisitionFrameworkObjectif,
    TBibliographicReference
)
from pypnusershub.db.models import User
from geonature.core.users.models import BibOrganismes
from pypnnomenclature.models import TNomenclatures
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_commons.models import CorModuleDataset, TModules


class MetadataSchema(MA.SQLAlchemyAutoSchema):
    cruved = fields.Method("get_user_cruved")

    def get_user_cruved(self, obj):
        if 'info_role' in self.context and 'user_cruved' in self.context:
            return obj.get_object_cruved(self.context['info_role'], self.context['user_cruved'])
        return None;

class UserSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = User
        load_instance = True
        exclude = (
            "_password",
            "_password_plus",
            "active",
            "date_insert",
            "date_update",
            "desc_role",
            "email",
            "groupe",
            "remarques",
            "identifiant",
        )

    nom_complet = fields.Function(
        lambda obj: (obj.nom_role if obj.nom_role else "")
        + (" " + obj.prenom_role if obj.prenom_role else "")
    )

    @pre_load
    def make_observer(self, data, **kwargs):
        if isinstance(data, int):
            return dict({"id_role": data})
        return data

class OrganismeSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = BibOrganismes
        load_instance = True

class ModuleSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TModules
        load_instance = True
        exclude = (
            "module_picto",
            "module_desc",
            "module_group",
            "module_path",
            "module_external_url",
            "module_target",
            "module_comment",
            "active_frontend",
            "active_backend",
            "module_doc_url",
            "module_order",
        )

class NomenclatureSchema(MA.SQLAlchemyAutoSchema):
    class Meta:
        model = TNomenclatures
        load_instance = True
        exclude = (
            "label_en",
            "definition_en",
            "label_es",
            "definition_es",
            "label_de",
            "definition_de",
            "label_it",
            "definition_it",
        )

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

    cor_dataset_actor = MA.Nested(
        DatasetActorSchema,
        many=True
    )
    modules = MA.Nested("ModuleSchema", many=True)

    creator = MA.Nested(UserSchema, dump_only=True)
    nomenclature_data_type = MA.Nested(UserSchema, dump_only=True)
    nomenclature_dataset_objectif = MA.Nested(UserSchema, dump_only=True)
    nomenclature_collecting_method = MA.Nested(UserSchema, dump_only=True)
    nomenclature_data_origin = MA.Nested(UserSchema, dump_only=True)
    nomenclature_source_status = MA.Nested(UserSchema, dump_only=True)
    nomenclature_resource_type = MA.Nested(UserSchema, dump_only=True)
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
        many=True
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
        many=True
    )
    nomenclature_territorial_level = MA.Nested(NomenclatureSchema, dump_only=True)
    nomenclature_financing_type = MA.Nested(NomenclatureSchema, dump_only=True)
    creator = MA.Nested(UserSchema, dump_only=True)
    #stats = fields.Method("get_af_stats")
    #bbox = fields.Method("get_af_bbox")

    #def get_af_stats(self, obj):
    #    return self.context['stats'] if "stats" in self.context else None

    #def get_af_bbox(self, obj):
    #    return self.context['bbox'] if "bbox" in self.context else None
