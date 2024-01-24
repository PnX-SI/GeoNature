import datetime

import sqlalchemy as sa
from flask import g
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.utils.env import DB, db
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from sqlalchemy import ForeignKey, or_
from sqlalchemy.dialects.postgresql import UUID as UUIDType
from sqlalchemy.ext.hybrid import hybrid_property
from sqlalchemy.orm import relationship
from sqlalchemy import func, select, exists
from utils_flask_sqla.models import qfilter
from utils_flask_sqla.serializers import serializable

from .commons import *
from .datasets import TDatasets


@serializable(exclude=["user_actors", "organism_actors"])
class TAcquisitionFramework(db.Model):
    __tablename__ = "t_acquisition_frameworks"
    __table_args__ = {"schema": "gn_meta"}

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
        foreign_keys=[id_nomenclature_territorial_level],
    )
    nomenclature_financing_type = DB.relationship(
        TNomenclatures,
        foreign_keys=[id_nomenclature_financing_type],
    )
    cor_af_actor = relationship(
        CorAcquisitionFrameworkActor,
        lazy="joined",
        # cascade="save-update, merge, delete, delete-orphan",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("actor_af"),
    )

    cor_objectifs = DB.relationship(
        TNomenclatures,
        secondary=cor_acquisition_framework_objectif,
        backref=DB.backref("objectif_af"),
    )

    cor_volets_sinp = DB.relationship(
        TNomenclatures,
        secondary=cor_acquisition_framework_voletsinp,
        backref=DB.backref("volet_sinp_af"),
    )

    cor_territories = DB.relationship(
        TNomenclatures,
        secondary=cor_acquisition_framework_territory,
        backref=DB.backref("territory_af"),
    )

    bibliographical_references = DB.relationship(
        "TBibliographicReference",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("acquisition_framework"),
    )

    # FIXME: remove and use datasets instead
    t_datasets = DB.relationship(
        "TDatasets",
        lazy="joined",  # DS required for permissions checks
        cascade="all,delete-orphan",
        uselist=True,
        back_populates="acquisition_framework",
    )
    datasets = DB.relationship(
        "TDatasets",
        cascade="all,delete-orphan",
        uselist=True,
        overlaps="t_datasets",  # overlaps expected
    )

    @hybrid_property
    def user_actors(self):
        return [actor.role for actor in self.cor_af_actor if actor.role]

    @hybrid_property
    def organism_actors(self):
        return [actor.organism for actor in self.cor_af_actor if actor.organism]

    def is_deletable(self):
        return not (
            db.session.scalar(
                exists()
                .select_from()
                .where(TDatasets.id_acquisition_framework == self.id_acquisition_framework)
                .select()
            )
        )

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
                    self.datasets,
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
        return DB.session.scalars(
            select(TAcquisitionFramework.id_acquisition_framework)
            .where(TAcquisitionFramework.unique_acquisition_framework_id == uuid_af)
            .limit(1)
        ).first()

    @staticmethod
    def get_user_af(user, only_query=False, only_user=False):
        """get the af(s) where the user is actor (himself or with its organism - only himelsemf id only_use=True) or digitizer
        param:
          - user from TRole model
          - only_query: boolean (return the query not the id_datasets allowed if true)
          - only_user: boolean: return only the dataset where user himself is actor (not with its organoism)

        return: a list of id_dataset or a query"""
        query = select(TAcquisitionFramework.id_acquisition_framework).outerjoin(
            CorAcquisitionFrameworkActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        )
        if user.id_organisme is None or only_user:
            query = query.where(
                or_(
                    CorAcquisitionFrameworkActor.id_role == user.id_role,
                    TAcquisitionFramework.id_digitizer == user.id_role,
                )
            )
        else:
            query = query.where(
                or_(
                    CorAcquisitionFrameworkActor.id_organism == user.id_organisme,
                    CorAcquisitionFrameworkActor.id_role == user.id_role,
                    TAcquisitionFramework.id_digitizer == user.id_role,
                )
            )
        if only_query:
            return query

        query = query.distinct()
        data = db.session.scalars(query).all()
        return data

    @classmethod
    def _get_read_scope(cls, user=None):
        if user is None:
            user = g.current_user
        cruved = get_scopes_by_action(id_role=user.id_role, module_code="METADATA")
        return cruved["R"]

    @qfilter(query=True)
    def filter_by_scope(cls, scope, *, query, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            query = query.where(sa.false())
        elif scope in (1, 2):
            ors = [
                TAcquisitionFramework.id_digitizer == user.id_role,
                TAcquisitionFramework.cor_af_actor.any(id_role=user.id_role),
                TAcquisitionFramework.datasets.any(id_digitizer=user.id_role),
                TAcquisitionFramework.datasets.any(
                    TDatasets.cor_dataset_actor.any(id_role=user.id_role)
                ),  # TODO test coverage
            ]
            # if organism is None => do not filter on id_organism even if level = 2
            if scope == 2 and user.id_organisme is not None:
                ors += [
                    TAcquisitionFramework.cor_af_actor.any(id_organism=user.id_organisme),
                    TAcquisitionFramework.datasets.any(
                        TDatasets.cor_dataset_actor.any(id_organism=user.id_organisme)
                    ),  # TODO test coverage
                ]
            query = query.where(or_(*ors))
        return query

    @qfilter(query=True)
    def filter_by_readable(cls, *, query, user=None):
        """
        Return the afs where the user has autorization via its CRUVED
        """
        return cls.filter_by_scope(TDatasets._get_read_scope(user=user), user=user, query=query)

    @qfilter(query=True)
    def filter_by_areas(cls, areas, *, query):
        """
        Filter meta by areas
        """
        return query.where(
            TAcquisitionFramework.datasets.any(
                TDatasets.filter_by_areas(areas).whereclause,
            ),
        )

    @qfilter(query=True)
    def filter_by_params(cls, params={}, *, _ds_search=True, query=None):
        # XXX frontend retro-compatibility
        if params.get("selector") == "ds":
            ds_params = params
            params = {"datasets": ds_params}
            if "search" in ds_params:
                params["search"] = ds_params.pop("search")
        ds_params = params.get("datasets")
        if ds_params:
            ds_filter = TDatasets.filter_by_params(ds_params).whereclause
            if ds_filter is not None:  # do not exclude AF without any DS
                query = query.where(TAcquisitionFramework.datasets.any(ds_filter))

        params = MetadataFilterSchema().load(params)

        uuid = params.get("uuid")
        name = params.get("name")
        date = params.get("date")
        query = (
            query.where(
                TAcquisitionFramework.unique_acquisition_framework_id == uuid if uuid else True
            )
            .where(
                TAcquisitionFramework.acquisition_framework_name.ilike(f"%{name}%")
                if name
                else True
            )
            .where(TAcquisitionFramework.acquisition_framework_start_date == date if date else True)
        )

        actors = []
        person = params.get("person")
        organism = params.get("organism")
        if person:
            actors.append(
                TAcquisitionFramework.cor_af_actor.any(
                    CorAcquisitionFrameworkActor.id_role == person
                )
            )

        if organism:
            actors.append(
                TAcquisitionFramework.cor_af_actor.any(
                    CorAcquisitionFrameworkActor.id_organism == organism
                )
            )
        if actors:
            query = query.where(sa.or_(*actors))

        areas = params.get("areas")
        if areas:
            query = TAcquisitionFramework.filter_by_areas(areas, query=query)

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
                ors.append(TAcquisitionFramework.acquisition_framework_start_date == date)
            except ValueError:
                pass

            if _ds_search:
                ors.append(
                    TAcquisitionFramework.datasets.any(
                        TDatasets.filter_by_params({"search": search}, _af_search=False).whereclause
                    ),
                )
            query = query.where(sa.or_(*ors))
        return query
