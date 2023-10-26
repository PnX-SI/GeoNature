import datetime
from uuid import UUID
from packaging import version

from flask import g
import flask_sqlalchemy
import sqlalchemy as sa
from sqlalchemy import ForeignKey, or_, and_
from sqlalchemy.sql import select, func, exists
from sqlalchemy.orm import relationship, exc, synonym
from sqlalchemy.dialects.postgresql import UUID as UUIDType
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.schema import FetchedValue
from utils_flask_sqla.generic import testDataType
from werkzeug.exceptions import BadRequest, NotFound
import marshmallow as ma

if version.parse(flask_sqlalchemy.__version__) >= version.parse("3"):
    from flask_sqlalchemy.query import Query
else:
    from flask_sqlalchemy import BaseQuery as Query

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User, Organisme
from utils_flask_sqla.serializers import serializable

from geonature.utils.errors import GeonatureApiError
from geonature.utils.env import DB, db
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_commons.models import cor_field_dataset, cor_module_dataset

from ref_geo.models import LAreas


class DateFilterSchema(ma.Schema):
    year = ma.fields.Integer()
    month = ma.fields.Integer()
    day = ma.fields.Integer()


class MetadataFilterSchema(ma.Schema):
    class Meta:
        unknown = ma.EXCLUDE

    uuid = ma.fields.UUID(allow_none=True)
    name = ma.fields.String()
    date = ma.fields.Nested(DateFilterSchema)
    person = ma.fields.Integer()
    organism = ma.fields.Integer()
    areas = ma.fields.List(ma.fields.Integer())
    search = ma.fields.String()

    @ma.post_load(pass_many=False)
    def convert_date(self, data, **kwargs):
        if "date" in data:
            date = data["date"]
            try:
                data["date"] = datetime.date(
                    year=date["year"], month=date["month"], day=date["day"]
                )
            except TypeError as exc:
                raise ma.ValidationError(*exc.args, field_name="date") from exc
        return data


class CorAcquisitionFrameworkObjectif(DB.Model):
    __tablename__ = "cor_acquisition_framework_objectif"
    __table_args__ = {"schema": "gn_meta"}
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    )
    id_nomenclature_objectif = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )

    nomenclature_objectif = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_objectif),
    )


class CorAcquisitionFrameworkVoletSINP(DB.Model):
    __tablename__ = "cor_acquisition_framework_voletsinp"
    __table_args__ = {"schema": "gn_meta"}
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    )
    id_nomenclature_voletsinp = DB.Column(
        "id_nomenclature_voletsinp",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )

    nomenclature_voletsinp = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_voletsinp),
    )


class CorAcquisitionFrameworkTerritory(DB.Model):
    __tablename__ = "cor_acquisition_framework_territory"
    __table_args__ = {"schema": "gn_meta"}
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    )
    id_nomenclature_territory = DB.Column(
        "id_nomenclature_territory",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )

    nomenclature_territory = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_territory),
    )


@serializable
class CorAcquisitionFrameworkActor(DB.Model):
    __tablename__ = "cor_acquisition_framework_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cafa = DB.Column(DB.Integer, primary_key=True)
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role))
    id_organism = DB.Column(DB.Integer, ForeignKey(Organisme.id_organisme))
    id_nomenclature_actor_role = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("ROLE_ACTEUR"),
    )

    nomenclature_actor_role = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_actor_role),
    )

    role = DB.relationship(
        User,
        lazy="joined",
    )

    organism = relationship(
        Organisme,
        lazy="joined",
    )


@serializable(exclude=["actor"])
class CorDatasetActor(DB.Model):
    __tablename__ = "cor_dataset_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cda = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role))
    id_organism = DB.Column(DB.Integer, ForeignKey(Organisme.id_organisme))

    id_nomenclature_actor_role = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("ROLE_ACTEUR"),
    )
    nomenclature_actor_role = DB.relationship(
        TNomenclatures,
        lazy="joined",
        foreign_keys=[id_nomenclature_actor_role],
    )

    role = DB.relationship(User, lazy="joined")
    organism = DB.relationship(Organisme, lazy="joined")

    @hybrid_property
    def actor(self):
        if self.role is not None:
            return self.role
        else:
            return self.organism

    @hybrid_property
    def display(self):
        if self.role:
            actor = self.role.nom_complet
        else:
            actor = self.organism.nom_organisme
        return "{} ({})".format(actor, self.nomenclature_actor_role.label_default)


@serializable
class CorDatasetProtocol(DB.Model):
    __tablename__ = "cor_dataset_protocol"
    __table_args__ = {"schema": "gn_meta"}
    id_cdp = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_protocol = DB.Column(DB.Integer, ForeignKey("gn_meta.sinp_datatype_protocols.id_protocol"))


@serializable
class CorDatasetTerritory(DB.Model):
    __tablename__ = "cor_dataset_territory"
    __table_args__ = {"schema": "gn_meta"}
    id_dataset = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    )
    id_nomenclature_territory = DB.Column(
        "id_nomenclature_territory",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )

    nomenclature_territory = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_territory),
    )


@serializable
class TBibliographicReference(db.Model):
    __tablename__ = "t_bibliographical_references"
    __table_args__ = {"schema": "gn_meta"}
    id_bibliographic_reference = DB.Column(DB.Integer, primary_key=True)
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    publication_url = DB.Column(DB.Unicode)
    publication_reference = DB.Column(DB.Unicode)


class TDatasetsQuery(Query):
    def _get_read_scope(self, user=None):
        if user is None:
            user = g.current_user
        cruved = get_scopes_by_action(id_role=user.id_role, module_code="METADATA")
        return cruved["R"]

    def _get_create_scope(self, module_code, user=None, object_code=None):
        if user is None:
            user = g.current_user
        cruved = get_scopes_by_action(
            id_role=user.id_role, module_code=module_code, object_code=object_code
        )
        return cruved["C"]

    def filter_by_scope(self, scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            self = self.filter(sa.false())
        elif scope in (1, 2):
            ors = [
                TDatasets.id_digitizer == user.id_role,
                TDatasets.cor_dataset_actor.any(id_role=user.id_role),
                TDatasets.acquisition_framework.has(id_digitizer=user.id_role),
                TDatasets.acquisition_framework.has(
                    TAcquisitionFramework.cor_af_actor.any(id_role=user.id_role),
                ),
            ]
            # if organism is None => do not filter on id_organism even if level = 2
            if scope == 2 and user.id_organisme is not None:
                ors += [
                    TDatasets.cor_dataset_actor.any(id_organism=user.id_organisme),
                    TDatasets.acquisition_framework.has(
                        TAcquisitionFramework.cor_af_actor.any(id_organism=user.id_organisme),
                    ),
                ]
            self = self.filter(or_(*ors))
        return self

    def filter_by_params(self, params={}, _af_search=True):
        class DatasetFilterSchema(MetadataFilterSchema):
            active = ma.fields.Boolean()
            orderby = ma.fields.String()
            module_code = ma.fields.String()
            id_acquisition_frameworks = ma.fields.List(ma.fields.Integer(), allow_none=True)

        params = DatasetFilterSchema().load(params)

        active = params.get("active")
        if active is not None:
            self = self.filter(TDatasets.active == active)

        module_code = params.get("module_code")
        if module_code:
            self = self.filter(TDatasets.modules.any(module_code=module_code))

        af_ids = params.get("id_acquisition_frameworks")
        if af_ids:
            self = self.filter(
                sa.or_(*[TDatasets.id_acquisition_framework == af_id for af_id in af_ids])
            )

        uuid = params.get("uuid")
        if uuid:
            self = self.filter(TDatasets.unique_dataset_id == uuid)

        name = params.get("name")
        if name:
            self = self.filter(TDatasets.dataset_name.ilike(f"%{name}%"))

        date = params.get("date")
        if date:
            self = self.filter(sa.cast(TDatasets.meta_create_date, sa.DATE) == date)

        actors = []
        person = params.get("person")
        if person:
            actors.append(TDatasets.cor_dataset_actor.any(CorDatasetActor.id_role == person))
        organism = params.get("organism")
        if organism:
            actors.append(TDatasets.cor_dataset_actor.any(CorDatasetActor.id_organism == organism))
        if actors:
            self = self.filter(sa.or_(*actors))

        areas = params.get("areas")
        if areas:
            self = self.filter_by_areas(areas)

        search = params.get("search")
        if search:
            ors = [
                TDatasets.dataset_name.ilike(f"%{search}%"),
                sa.cast(TDatasets.id_dataset, sa.String) == search,
            ]
            # enable uuid search only with at least 5 characters
            if len(search) >= 5:
                ors.append(sa.cast(TDatasets.unique_dataset_id, sa.String).like(f"{search}%"))
            try:
                date = datetime.datetime.strptime(search, "%d/%m/%Y").date()
            except ValueError:
                pass
            else:
                ors.append(sa.cast(TDatasets.meta_create_date, sa.DATE) == date)
            if _af_search:
                ors.append(
                    TDatasets.acquisition_framework.has(
                        TAcquisitionFramework.query.filter_by_params(
                            {"search": search},
                            _ds_search=False,
                        ).whereclause
                    )
                )
            self = self.filter(or_(*ors))
        return self

    def filter_by_readable(self, user=None):
        """
        Return the datasets where the user has autorization via its CRUVED
        """
        return self.filter_by_scope(self._get_read_scope(user))

    def filter_by_creatable(self, module_code, user=None, object_code=None):
        """
        Return all dataset where user have read rights minus those who user to not have
        create rigth
        """
        query = self.filter(TDatasets.modules.any(module_code=module_code))
        scope = self._get_read_scope(user)
        create_scope = self._get_create_scope(module_code, user=user, object_code=object_code)
        if create_scope < scope:
            scope = create_scope
        return query.filter_by_scope(scope)

    def filter_by_areas(self, areas):
        from geonature.core.gn_synthese.models import Synthese

        areaFilter = []
        for id_area in areas:
            areaFilter.append(LAreas.id_area == id_area)
        return self.filter(TDatasets.synthese_records.any(Synthese.areas.any(sa.or_(*areaFilter))))


@serializable(exclude=["user_actors", "organism_actors"])
class TDatasets(db.Model):
    __tablename__ = "t_datasets"
    __table_args__ = {"schema": "gn_meta"}
    query_class = TDatasetsQuery

    id_dataset = DB.Column(DB.Integer, primary_key=True)
    unique_dataset_id = DB.Column(
        UUIDType(as_uuid=True), default=select(func.uuid_generate_v4())
    )
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    acquisition_framework = DB.relationship(
        "TAcquisitionFramework", lazy="joined"
    )  # join AF as required for permissions checks
    dataset_name = DB.Column(DB.Unicode)
    dataset_shortname = DB.Column(DB.Unicode)
    dataset_desc = DB.Column(DB.Unicode)
    id_nomenclature_data_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("DATA_TYP"),
    )
    keywords = DB.Column(DB.Unicode)
    marine_domain = DB.Column(DB.Boolean)
    terrestrial_domain = DB.Column(DB.Boolean)
    id_nomenclature_dataset_objectif = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("JDD_OBJECTIFS"),
    )
    bbox_west = DB.Column(DB.Float)
    bbox_east = DB.Column(DB.Float)
    bbox_south = DB.Column(DB.Float)
    bbox_north = DB.Column(DB.Float)
    id_nomenclature_collecting_method = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("METHO_RECUEIL"),
    )
    id_nomenclature_data_origin = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("DS_PUBLIQUE"),
    )
    id_nomenclature_source_status = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("STATUT_SOURCE"),
    )
    id_nomenclature_resource_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("RESOURCE_TYP"),
    )
    meta_create_date = DB.Column(DB.DateTime, server_default=FetchedValue())
    meta_update_date = DB.Column(DB.DateTime, server_default=FetchedValue())
    active = DB.Column(DB.Boolean, default=True)
    validable = DB.Column(DB.Boolean, server_default=FetchedValue())
    id_digitizer = DB.Column(DB.Integer, ForeignKey(User.id_role))
    digitizer = DB.relationship(User, lazy="joined")  # joined for permission check
    id_taxa_list = DB.Column(DB.Integer)
    modules = DB.relationship("TModules", secondary=cor_module_dataset, backref="datasets")

    creator = DB.relationship(User, lazy="joined", overlaps="digitizer")  # = digitizer
    nomenclature_data_type = DB.relationship(
        TNomenclatures,
        lazy="select",
        foreign_keys=[id_nomenclature_data_type],
    )
    nomenclature_dataset_objectif = DB.relationship(
        TNomenclatures,
        lazy="select",
        foreign_keys=[id_nomenclature_dataset_objectif],
    )
    nomenclature_collecting_method = DB.relationship(
        TNomenclatures,
        lazy="select",
        foreign_keys=[id_nomenclature_collecting_method],
    )
    nomenclature_data_origin = DB.relationship(
        TNomenclatures,
        lazy="select",
        foreign_keys=[id_nomenclature_data_origin],
    )
    nomenclature_source_status = DB.relationship(
        TNomenclatures,
        lazy="select",
        foreign_keys=[id_nomenclature_source_status],
    )
    nomenclature_resource_type = DB.relationship(
        TNomenclatures,
        lazy="select",
        foreign_keys=[id_nomenclature_resource_type],
    )

    cor_territories = DB.relationship(
        TNomenclatures,
        lazy="select",
        secondary=CorDatasetTerritory.__table__,
        primaryjoin=(CorDatasetTerritory.id_dataset == id_dataset),
        secondaryjoin=(
            CorDatasetTerritory.id_nomenclature_territory == TNomenclatures.id_nomenclature
        ),
        foreign_keys=[
            CorDatasetTerritory.id_dataset,
            CorDatasetTerritory.id_nomenclature_territory,
        ],
        backref=DB.backref("territory_dataset", lazy="select", overlaps="nomenclature_territory"),
        overlaps="nomenclature_territory",
    )

    # because CorDatasetActor could be an User or an Organisme object...
    cor_dataset_actor = relationship(
        CorDatasetActor,
        lazy="joined",
        cascade="save-update, merge, delete, delete-orphan",
        backref=DB.backref("actor_dataset", lazy="select"),
    )

    @hybrid_property
    def user_actors(self):
        return [actor.role for actor in self.cor_dataset_actor if actor.role is not None]

    @hybrid_property
    def organism_actors(self):
        return [actor.organism for actor in self.cor_dataset_actor if actor.organism is not None]

    def is_deletable(self):
        return not DB.session.query(self.synthese_records.exists()).scalar()

    def has_instance_permission(self, scope, _through_af=True):
        """
        _through_af prevent infinite recursion
        """
        if scope == 0:
            return False
        elif scope in (1, 2):
            if g.current_user.id_role == self.id_digitizer or g.current_user in self.user_actors:
                return True
            if scope == 2 and g.current_user.organisme in self.organism_actors:
                return True
            return _through_af and self.acquisition_framework.has_instance_permission(
                scope, _through_ds=False
            )
        elif scope == 3:
            return True

    def __str__(self):
        return self.dataset_name

    @staticmethod
    def get_id(uuid_dataset):
        return (
            DB.session.query(TDatasets.id_dataset)
            .filter(TDatasets.unique_dataset_id == uuid_dataset)
            .scalar()
        )

    @staticmethod
    def get_uuid(id_dataset):
        return (
            DB.session.query(TDatasets.unique_dataset_id)
            .filter(TDatasets.id_dataset == id_dataset)
            .scalar()
        )


class TAcquisitionFrameworkQuery(Query):
    def _get_read_scope(self, user=None):
        if user is None:
            user = g.current_user
        cruved = get_scopes_by_action(id_role=user.id_role, module_code="METADATA")
        return cruved["R"]

    def filter_by_scope(self, scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            self = self.filter(sa.false())
        elif scope in (1, 2):
            ors = [
                TAcquisitionFramework.id_digitizer == user.id_role,
                TAcquisitionFramework.cor_af_actor.any(id_role=user.id_role),
                TAcquisitionFramework.t_datasets.any(id_digitizer=user.id_role),
                TAcquisitionFramework.t_datasets.any(
                    TDatasets.cor_dataset_actor.any(id_role=user.id_role)
                ),  # TODO test coverage
            ]
            # if organism is None => do not filter on id_organism even if level = 2
            if scope == 2 and user.id_organisme is not None:
                ors += [
                    TAcquisitionFramework.cor_af_actor.any(id_organism=user.id_organisme),
                    TAcquisitionFramework.t_datasets.any(
                        TDatasets.cor_dataset_actor.any(id_organism=user.id_organisme)
                    ),  # TODO test coverage
                ]
            self = self.filter(or_(*ors))
        return self

    def filter_by_readable(self):
        """
        Return the afs where the user has autorization via its CRUVED
        """
        return self.filter_by_scope(self._get_read_scope())

    def filter_by_areas(self, areas):
        """
        Filter meta by areas
        """
        return self.filter(
            TAcquisitionFramework.t_datasets.any(
                TDatasets.query.filter_by_areas(areas).whereclause,
            ),
        )

    def filter_by_params(self, params={}, _ds_search=True):
        # XXX frontend retro-compatibility
        if params.get("selector") == "ds":
            ds_params = params
            params = {"datasets": ds_params}
            if "search" in ds_params:
                params["search"] = ds_params.pop("search")
        ds_params = params.get("datasets")
        if ds_params:
            ds_filter = TDatasets.query.filter_by_params(ds_params).whereclause
            if ds_filter is not None:  # do not exclude AF without any DS
                self = self.filter(TAcquisitionFramework.datasets.any(ds_filter))

        params = MetadataFilterSchema().load(params)

        uuid = params.get("uuid")
        if uuid:
            self = self.filter(TAcquisitionFramework.unique_acquisition_framework_id == uuid)

        name = params.get("name")
        if name:
            self = self.filter(TAcquisitionFramework.acquisition_framework_name.ilike(f"%{name}%"))

        date = params.get("date")
        if date:
            self = self.filter(TAcquisitionFramework.acquisition_framework_start_date == date)

        actors = []
        person = params.get("person")
        if person:
            actors.append(
                TAcquisitionFramework.cor_af_actor.any(
                    CorAcquisitionFrameworkActor.id_role == person
                )
            )
        organism = params.get("organism")
        if organism:
            actors.append(
                TAcquisitionFramework.cor_af_actor.any(
                    CorAcquisitionFrameworkActor.id_organism == organism
                )
            )
        if actors:
            self = self.filter(sa.or_(*actors))

        areas = params.get("areas")
        if areas:
            self = self.filter_by_areas(areas)

        search = params.get("search")
        if search:
            ors = [
                TAcquisitionFramework.acquisition_framework_name.ilike(f"%{search}%"),
                sa.cast(TAcquisitionFramework.id_acquisition_framework, sa.String) == search,
            ]
            # enable uuid search only with at least 5 characters
            if len(search) >= 5:
                ors.append(
                    sa.cast(TAcquisitionFramework.unique_acquisition_framework_id, sa.String).like(
                        f"{search}%"
                    )
                )
            try:
                date = datetime.datetime.strptime(search, "%d/%m/%Y").date()
            except ValueError:
                pass
            else:
                ors.append(TAcquisitionFramework.acquisition_framework_start_date == date)
            if _ds_search:
                ors.append(
                    TAcquisitionFramework.datasets.any(
                        TDatasets.query.filter_by_params(
                            {"search": search}, _af_search=False
                        ).whereclause
                    ),
                )
            self = self.filter(sa.or_(*ors))
        return self


@serializable(exclude=["user_actors", "organism_actors"])
class TAcquisitionFramework(db.Model):
    __tablename__ = "t_acquisition_frameworks"
    __table_args__ = {"schema": "gn_meta"}
    query_class = TAcquisitionFrameworkQuery

    id_acquisition_framework = DB.Column(DB.Integer, primary_key=True)
    unique_acquisition_framework_id = DB.Column(
        UUIDType(as_uuid=True), default=select(func.uuid_generate_v4())
    )
    acquisition_framework_name = DB.Column(DB.Unicode(255))
    acquisition_framework_desc = DB.Column(DB.Unicode)
    id_nomenclature_territorial_level = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("NIVEAU_TERRITORIAL"),
    )
    territory_desc = DB.Column(DB.Unicode)
    keywords = DB.Column(DB.Unicode)
    id_nomenclature_financing_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("TYPE_FINANCEMENT"),
    )
    target_description = DB.Column(DB.Unicode)
    ecologic_or_geologic_target = DB.Column(DB.Unicode)
    acquisition_framework_parent_id = DB.Column(DB.Integer)
    is_parent = DB.Column(DB.Boolean)
    opened = DB.Column(DB.Boolean, default=True)
    id_digitizer = DB.Column(DB.Integer, ForeignKey(User.id_role))

    acquisition_framework_start_date = DB.Column(DB.Date, default=datetime.datetime.utcnow)
    acquisition_framework_end_date = DB.Column(DB.Date)

    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    initial_closing_date = DB.Column(DB.DateTime)

    creator = DB.relationship(User, lazy="joined")  # = digitizer
    nomenclature_territorial_level = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_territorial_level),
    )
    nomenclature_financing_type = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_financing_type),
    )
    cor_af_actor = relationship(
        CorAcquisitionFrameworkActor,
        lazy="joined",
        # cascade="save-update, merge, delete, delete-orphan",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("actor_af", lazy="select"),
    )

    cor_objectifs = DB.relationship(
        TNomenclatures,
        lazy="select",
        secondary=CorAcquisitionFrameworkObjectif.__table__,
        primaryjoin=(
            CorAcquisitionFrameworkObjectif.id_acquisition_framework == id_acquisition_framework
        ),
        secondaryjoin=(
            CorAcquisitionFrameworkObjectif.id_nomenclature_objectif
            == TNomenclatures.id_nomenclature
        ),
        foreign_keys=[
            CorAcquisitionFrameworkObjectif.id_acquisition_framework,
            CorAcquisitionFrameworkObjectif.id_nomenclature_objectif,
        ],
        backref=DB.backref("objectif_af", lazy="select", overlaps="nomenclature_objectif"),
        overlaps="nomenclature_objectif",
    )

    cor_volets_sinp = DB.relationship(
        TNomenclatures,
        lazy="select",
        secondary=CorAcquisitionFrameworkVoletSINP.__table__,
        primaryjoin=(
            CorAcquisitionFrameworkVoletSINP.id_acquisition_framework == id_acquisition_framework
        ),
        secondaryjoin=(
            CorAcquisitionFrameworkVoletSINP.id_nomenclature_voletsinp
            == TNomenclatures.id_nomenclature
        ),
        foreign_keys=[
            CorAcquisitionFrameworkVoletSINP.id_acquisition_framework,
            CorAcquisitionFrameworkVoletSINP.id_nomenclature_voletsinp,
        ],
        backref=DB.backref("volet_sinp_af", lazy="select", overlaps="nomenclature_voletsinp",),
        overlaps="nomenclature_voletsinp",
    )

    cor_territories = DB.relationship(
        TNomenclatures,
        lazy="select",
        secondary=CorAcquisitionFrameworkTerritory.__table__,
        primaryjoin=(
            CorAcquisitionFrameworkTerritory.id_acquisition_framework == id_acquisition_framework
        ),
        secondaryjoin=(
            CorAcquisitionFrameworkTerritory.id_nomenclature_territory
            == TNomenclatures.id_nomenclature
        ),
        foreign_keys=[
            CorAcquisitionFrameworkTerritory.id_acquisition_framework,
            CorAcquisitionFrameworkTerritory.id_nomenclature_territory,
        ],
        backref=DB.backref("territory_af", lazy="select", overlaps="nomenclature_territory"),
        overlaps="nomenclature_territory"
    )

    bibliographical_references = DB.relationship(
        "TBibliographicReference",
        lazy="select",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("acquisition_framework", lazy="select"),
    )

    t_datasets = DB.relationship(
        "TDatasets",
        lazy="joined",  # DS required for permissions checks
        cascade="all,delete-orphan",
        uselist=True,
        overlaps="acquisition_framework",
    )
    datasets = synonym("t_datasets")

    @hybrid_property
    def user_actors(self):
        return [actor.role for actor in self.cor_af_actor if actor.role is not None]

    @hybrid_property
    def organism_actors(self):
        return [actor.organism for actor in self.cor_af_actor if actor.organism is not None]

    def is_deletable(self):
        return not db.session.query(
            TDatasets.query.filter_by(
                id_acquisition_framework=self.id_acquisition_framework
            ).exists()
        ).scalar()

    def has_instance_permission(self, scope, _through_ds=True):
        if scope == 0:
            return False
        elif scope in (1, 2):
            if g.current_user.id_role == self.id_digitizer or g.current_user in self.user_actors:
                return True
            if scope == 2 and g.current_user.organisme in self.organism_actors:
                return True
            # rights on DS give rights on AF!
            return _through_ds and any(
                map(
                    lambda ds: ds.has_instance_permission(scope, _through_af=False),
                    self.t_datasets,
                )
            )
        elif scope == 3:
            return True

    @staticmethod
    def get_id(uuid_af):
        """
        return the acquisition framework's id
        from its UUID if exist or None
        """
        return (
            DB.session.query(TAcquisitionFramework.id_acquisition_framework)
            .filter(TAcquisitionFramework.unique_acquisition_framework_id == uuid_af)
            .scalar()
        )

    @staticmethod
    def get_user_af(user, only_query=False, only_user=False):
        """get the af(s) where the user is actor (himself or with its organism - only himelsemf id only_use=True) or digitizer
        param:
          - user from TRole model
          - only_query: boolean (return the query not the id_datasets allowed if true)
          - only_user: boolean: return only the dataset where user himself is actor (not with its organoism)

        return: a list of id_dataset or a query"""
        q = DB.session.query(TAcquisitionFramework.id_acquisition_framework).outerjoin(
            CorAcquisitionFrameworkActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        )
        if user.id_organisme is None or only_user:
            q = q.filter(
                or_(
                    CorAcquisitionFrameworkActor.id_role == user.id_role,
                    TAcquisitionFramework.id_digitizer == user.id_role,
                )
            )
        else:
            q = q.filter(
                or_(
                    CorAcquisitionFrameworkActor.id_organism == user.id_organisme,
                    CorAcquisitionFrameworkActor.id_role == user.id_role,
                    TAcquisitionFramework.id_digitizer == user.id_role,
                )
            )
        if only_query:
            return q
        data = q.all()
        return list(set([d.id_acquisition_framework for d in data]))


@serializable
class TDatasetDetails(TDatasets):
    data_type = DB.relationship(
        TNomenclatures,
        foreign_keys=[TDatasets.id_nomenclature_data_type],
        overlaps="nomenclature_data_type",
    )
    dataset_objectif = DB.relationship(
        TNomenclatures,
        foreign_keys=[TDatasets.id_nomenclature_dataset_objectif],
        overlaps="nomenclature_dataset_objectif",
    )
    collecting_method = DB.relationship(
        TNomenclatures,
        foreign_keys=[TDatasets.id_nomenclature_collecting_method],
        overlaps="nomenclature_collecting_method",
    )
    data_origin = DB.relationship(
        TNomenclatures,
        foreign_keys=[TDatasets.id_nomenclature_data_origin],
        overlaps="nomenclature_data_origin",
    )
    source_status = DB.relationship(
        TNomenclatures,
        foreign_keys=[TDatasets.id_nomenclature_source_status],
        overlaps="nomenclature_source_status",
    )
    resource_type = DB.relationship(
        TNomenclatures,
        foreign_keys=[TDatasets.id_nomenclature_resource_type],
        overlaps="nomenclature_resource_type",
    )
    additional_fields = DB.relationship("TAdditionalFields", secondary=cor_field_dataset)


@serializable
class TAcquisitionFrameworkDetails(TAcquisitionFramework):
    """
    Class which extends TAcquisitionFramework with nomenclatures relationships
    """

    nomenclature_territorial_level = DB.relationship(
        TNomenclatures,
        foreign_keys=[TAcquisitionFramework.id_nomenclature_territorial_level],
    )

    nomenclature_financing_type = DB.relationship(
        TNomenclatures,
        foreign_keys=[TAcquisitionFramework.id_nomenclature_financing_type],
    )
