import datetime

from flask import g
import sqlalchemy as sa
from sqlalchemy import ForeignKey, or_
from sqlalchemy.sql import select, func
<<<<<<< HEAD
from sqlalchemy.orm import relationship, mapped_column, Mapped
from sqlalchemy.dialects.postgresql import UUID as UUIDType
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.schema import FetchedValue
from typing import Optional, List
=======
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID as UUIDType
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.schema import FetchedValue
>>>>>>> 2b2788d7f (split files of gn_meta models + update utils-flask-sqla)
from utils_flask_sqla.models import qfilter
import marshmallow as ma

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB, db
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_commons.models import cor_field_dataset, cor_module_dataset

from ref_geo.models import LAreas
from .commons import *


@serializable(exclude=["user_actors", "organism_actors"])
class TDatasets(db.Model):
    __tablename__ = "t_datasets"
    __table_args__ = {"schema": "gn_meta"}

    id_dataset: Mapped[int] = mapped_column(primary_key=True)
    unique_dataset_id: Mapped[Optional[int]] = mapped_column(UUIDType(as_uuid=True), default=select(func.uuid_generate_v4()))
    id_acquisition_framework: Mapped[Optional[int]] = mapped_column(
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    acquisition_framework: Mapped[Optional["TAcquisitionFramework"]] = DB.relationship(
        back_populates="datasets", lazy="joined"
    )  # join AF as required for permissions checks
    dataset_name: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    dataset_shortname: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    dataset_desc: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    id_nomenclature_data_type: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("DATA_TYP"),
    )
    keywords: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    marine_domain: Mapped[Optional[bool]]
    terrestrial_domain: Mapped[Optional[bool]]
    id_nomenclature_dataset_objectif: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("JDD_OBJECTIFS"),
    )
    bbox_west: Mapped[Optional[float]]
    bbox_east: Mapped[Optional[float]]
    bbox_south: Mapped[Optional[float]]
    bbox_north: Mapped[Optional[float]]
    id_nomenclature_collecting_method: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("METHO_RECUEIL"),
    )
    id_nomenclature_data_origin: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("DS_PUBLIQUE"),
    )
    id_nomenclature_source_status: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("STATUT_SOURCE"),
    )
    id_nomenclature_resource_type: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("RESOURCE_TYP"),
    )
    meta_create_date: Mapped[Optional[datetime.datetime]] = mapped_column(server_default=FetchedValue())
    meta_update_date: Mapped[Optional[datetime.datetime]] = mapped_column(server_default=FetchedValue())
    active: Mapped[Optional[bool]] = mapped_column(default=True)
    validable: Mapped[Optional[bool]] = mapped_column(server_default=FetchedValue())
    id_digitizer: Mapped[Optional[int]] = mapped_column(ForeignKey(User.id_role))
    digitizer: Mapped[Optional[User]] = DB.relationship(lazy="joined")  # joined for permission check
    creator: Mapped[Optional[User]] = DB.relationship(
        User, lazy="joined", overlaps="digitizer"
    )  # overlaps as alias of digitizer
    id_taxa_list: Mapped[Optional[int]]
    modules: Mapped[Optional["TModules"]] = DB.relationship(secondary=cor_module_dataset, backref="datasets")

    nomenclature_data_type: Mapped[Optional[TNomenclatures]] = DB.relationship(
        foreign_keys=[id_nomenclature_data_type],
    )
    nomenclature_dataset_objectif: Mapped[Optional[TNomenclatures]] = DB.relationship(
        foreign_keys=[id_nomenclature_dataset_objectif],
    )
    nomenclature_collecting_method: Mapped[Optional[TNomenclatures]] = DB.relationship(
        foreign_keys=[id_nomenclature_collecting_method],
    )
    nomenclature_data_origin: Mapped[Optional[TNomenclatures]] = DB.relationship(
        foreign_keys=[id_nomenclature_data_origin],
    )
    nomenclature_source_status: Mapped[Optional[TNomenclatures]] = DB.relationship(
        foreign_keys=[id_nomenclature_source_status],
    )
    nomenclature_resource_type: Mapped[Optional[TNomenclatures]] = DB.relationship(
        foreign_keys=[id_nomenclature_resource_type],
    )

    cor_territories: Mapped[Optional[TNomenclatures]] = DB.relationship(
        secondary=cor_dataset_territory,
        backref=DB.backref("territory_dataset"),
    )

    # because CorDatasetActor could be an User or an Organisme object...
    cor_dataset_actor: Mapped[Optional[CorDatasetActor]] = relationship(
        lazy="joined",
        cascade="save-update, merge, delete, delete-orphan",
        backref=DB.backref("actor_dataset"),
    )
    additional_fields: Mapped[List["TAdditionalFields"]] = DB.relationship(
        secondary=cor_field_dataset, back_populates="datasets"
    )

    @hybrid_property
    def user_actors(self):
        return [actor.role for actor in self.cor_dataset_actor if actor.role is not None]

    @hybrid_property
    def organism_actors(self):
        return [actor.organism for actor in self.cor_dataset_actor if actor.organism is not None]

    def is_deletable(self):
        # FIXME: replace for sqlalchemy2 
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
        return DB.session.execute(
            select(TDatasets.id_dataset).filter(TDatasets.unique_dataset_id == uuid_dataset)
        ).scalar_one_or_none()

    @staticmethod
    def get_uuid(id_dataset):
        return DB.session.execute(
            select(TDatasets.unique_dataset_id).filter(TDatasets.id_dataset == id_dataset)
        ).scalar_one_or_none()

    @classmethod
    def _get_read_scope(cls, user=None):
        if user is None:
            user = g.current_user
        cruved = get_scopes_by_action(id_role=user.id_role, module_code="METADATA")
        return cruved["R"]

    @classmethod
    def _get_create_scope(cls, module_code, user=None, object_code=None):
        if user is None:
            user = g.current_user
        cruved = get_scopes_by_action(
            id_role=user.id_role, module_code=module_code, object_code=object_code
        )
        return cruved["C"]

    @qfilter(query=True)
    def filter_by_scope(cls, scope, user=None, **kwargs):
        from .aframework import TAcquisitionFramework

        query = kwargs["query"]
        whereclause = sa.true()
        if user is None:
            user = g.current_user
        if scope == 0:
            whereclause = sa.false()
        elif scope in (1, 2):
            ors = [
                cls.id_digitizer == user.id_role,
                cls.cor_dataset_actor.any(id_role=user.id_role),
                cls.acquisition_framework.has(id_digitizer=user.id_role),
                cls.acquisition_framework.has(
                    TAcquisitionFramework.cor_af_actor.any(id_role=user.id_role),
                ),
            ]
            # if organism is None => do not filter on id_organism even if level = 2
            if scope == 2 and user.id_organisme is not None:
                ors += [
                    cls.cor_dataset_actor.any(id_organism=user.id_organisme),
                    cls.acquisition_framework.has(
                        TAcquisitionFramework.cor_af_actor.any(id_organism=user.id_organisme),
                    ),
                ]
            whereclause = or_(*ors)
        return query.where(whereclause)

    @qfilter(query=True)
    def filter_by_params(cls, params={}, _af_search=True, **kwargs):
        from .aframework import TAcquisitionFramework

        query = kwargs.get("query")

        class DatasetFilterSchema(MetadataFilterSchema):
            active = ma.fields.Boolean()
            orderby = ma.fields.String()
            module_code = ma.fields.String()
            id_acquisition_frameworks = ma.fields.List(ma.fields.Integer(), allow_none=True)

        params = DatasetFilterSchema().load(params)

        active = params.get("active")
        if active is not None:
            query = query.where(cls.active == active)

        module_code = params.get("module_code")
        if module_code:
            query = query.where(cls.modules.any(module_code=module_code))

        af_ids = params.get("id_acquisition_frameworks")
        if af_ids:
            query = query.where(
                sa.or_(*[cls.id_acquisition_framework == af_id for af_id in af_ids])
            )

        uuid = params.get("uuid")
        if uuid:
            query = query.where(cls.unique_dataset_id == uuid)

        name = params.get("name")
        if name:
            query = query.where(cls.dataset_name.ilike(f"%{name}%"))

        date = params.get("date")
        if date:
            query = query.where(sa.cast(cls.meta_create_date, sa.DATE) == date)

        actors = []
        person = params.get("person")
        if person:
            actors.append(cls.cor_dataset_actor.any(CorDatasetActor.id_role == person))
        organism = params.get("organism")
        if organism:
            actors.append(cls.cor_dataset_actor.any(CorDatasetActor.id_organism == organism))
        if actors:
            query = query.where(sa.or_(*actors))

        areas = params.get("areas")
        if areas:
            query = query.where_by_areas(areas)

        search = params.get("search")
        if search:
            ors = [
                cls.dataset_name.ilike(f"%{search}%"),
                sa.cast(cls.id_dataset, sa.String) == search,
            ]
            # enable uuid search only with at least 5 characters
            if len(search) >= 5:
                ors.append(sa.cast(cls.unique_dataset_id, sa.String).like(f"{search}%"))
            try:
                date = datetime.datetime.strptime(search, "%d/%m/%Y").date()
            except ValueError:
                pass
            else:
                ors.append(sa.cast(cls.meta_create_date, sa.DATE) == date)
            if _af_search:
                ors.append(
                    cls.acquisition_framework.has(
                        TAcquisitionFramework.filter_by_params(
                            {"search": search},
                            _ds_search=False,
                        ).whereclause
                    )
                )
            query = query.where(or_(*ors))
        return query

    @qfilter(query=True)
    def filter_by_readable(cls, user=None, **kwargs):
        """
        Return the datasets where the user has autorization via its CRUVED
        """
        query = kwargs.get("query")
        whereclause = cls.filter_by_scope(cls._get_read_scope(user)).whereclause
        return query.where(whereclause)

    @qfilter(query=True)
    def filter_by_creatable(cls, module_code, user=None, object_code=None, **kwargs):
        """
        Return all dataset where user have read rights minus those who user to not have
        create rigth
        """
        query = kwargs["query"]
        query = query.where(cls.modules.any(module_code=module_code))
        scope = cls._get_read_scope(user)
        create_scope = cls._get_create_scope(module_code, user=user, object_code=object_code)
        if create_scope < scope:
            scope = create_scope
        return cls.filter_by_scope(scope)

    @qfilter(query=True)
    def filter_by_areas(cls, areas, **kwargs):
        from geonature.core.gn_synthese.models import Synthese

        query = kwargs["query"]
        areaFilter = []
        for id_area in areas:
            areaFilter.append(LAreas.id_area == id_area)
        return query.where(cls.synthese_records.any(Synthese.areas.any(sa.or_(*areaFilter))))
