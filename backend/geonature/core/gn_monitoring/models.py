"""
Modèles du schéma gn_monitoring
Correspond a la centralisation des données de base
    relatifs aux protocoles de suivis
"""

from typing import Optional, Any
from datetime import datetime

from flask import g

from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey, or_, false
from sqlalchemy.orm import relationship, Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import select, func
from sqlalchemy.schema import FetchedValue
from sqlalchemy.ext.hybrid import hybrid_property


from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from ref_geo.models import LAreas
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.core.gn_commons.models import TModules, TMedias
from geonature.core.gn_meta.models import TDatasets
from geonature.utils.env import DB

cor_visit_observer = DB.Table(
    "cor_visit_observer",
    DB.Column(
        "id_base_visit",
        DB.Integer,
        ForeignKey("gn_monitoring.t_base_visits.id_base_visit"),
        primary_key=True,
    ),
    DB.Column(
        "id_role",
        DB.Integer,
        ForeignKey("utilisateurs.t_roles.id_role"),
        primary_key=True,
    ),
    schema="gn_monitoring",
)


class CorVisitObserver(DB.Model):
    __table__ = cor_visit_observer


cor_site_module = DB.Table(
    "cor_site_module",
    DB.Column(
        "id_base_site",
        DB.Integer,
        ForeignKey("gn_monitoring.t_base_sites.id_base_site"),
        primary_key=True,
    ),
    DB.Column(
        "id_module",
        DB.Integer,
        ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
    ),
    schema="gn_monitoring",
)

cor_site_area = DB.Table(
    "cor_site_area",
    DB.Column(
        "id_base_site",
        DB.Integer,
        ForeignKey("gn_monitoring.t_base_sites.id_base_site"),
        primary_key=True,
    ),
    DB.Column("id_area", DB.Integer, ForeignKey(LAreas.id_area), primary_key=True),
    schema="gn_monitoring",
)

cor_module_type = DB.Table(
    "cor_module_type",
    DB.Column(
        "id_module",
        DB.Integer,
        DB.ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
    ),
    DB.Column(
        "id_type_site",
        DB.Integer,
        DB.ForeignKey("gn_monitoring.bib_type_site.id_nomenclature_type_site"),
        primary_key=True,
    ),
    schema="gn_monitoring",
)

cor_site_type = DB.Table(
    "cor_site_type",
    DB.Column(
        "id_base_site",
        DB.Integer,
        DB.ForeignKey("gn_monitoring.t_base_sites.id_base_site"),
        primary_key=True,
    ),
    DB.Column(
        "id_type_site",
        DB.Integer,
        DB.ForeignKey("gn_monitoring.bib_type_site.id_nomenclature_type_site"),
        primary_key=True,
    ),
    schema="gn_monitoring",
)


@serializable
class BibTypeSite(DB.Model):
    __tablename__ = "bib_type_site"
    __table_args__ = {"schema": "gn_monitoring"}

    id_nomenclature_type_site: Mapped[int] = mapped_column(
        DB.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )
    config: Mapped[Optional[Any]] = mapped_column(JSONB)
    nomenclature = DB.relationship(
        TNomenclatures, uselist=False, backref=DB.backref("bib_type_site", uselist=False)
    )

    sites = DB.relationship("TBaseSites", secondary=cor_site_type, lazy="noload")


@serializable
class TBaseVisits(DB.Model):
    """
    Table de centralisation des visites liées à un site
    """

    __tablename__ = "t_base_visits"
    __table_args__ = {"schema": "gn_monitoring"}
    id_base_visit: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    id_base_site: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey("gn_monitoring.t_base_sites.id_base_site"))
    id_digitiser: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_dataset: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    # Pour le moment non défini comme une clé étrangère
    #   pour les questions de perfs
    #   a voir en fonction des usage
    id_module: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey("gn_commons.t_modules.id_module"))

    visit_date_min: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    visit_date_max: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    id_nomenclature_tech_collect_campanule: Mapped[Optional[int]]
    id_nomenclature_grp_typ: Mapped[Optional[int]]
    comments: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    uuid_base_visit: Mapped[Optional[Any]] = mapped_column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))

    meta_create_date: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    meta_update_date: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)

    digitiser = relationship(
        User, primaryjoin=(User.id_role == id_digitiser), foreign_keys=[id_digitiser]
    )

    observers = DB.relationship(
        User,
        secondary=cor_visit_observer,
        primaryjoin=(cor_visit_observer.c.id_base_visit == id_base_visit),
        secondaryjoin=(cor_visit_observer.c.id_role == User.id_role),
        foreign_keys=[cor_visit_observer.c.id_base_visit, cor_visit_observer.c.id_role],
    )

    observers_txt: Mapped[Optional[str]] = mapped_column(DB.Unicode)

    dataset = relationship(
        TDatasets,
        primaryjoin=(TDatasets.id_dataset == id_dataset),
        foreign_keys=[id_dataset],
    )

    id_import: Mapped[Optional[int]]


@serializable
@geoserializable(geoCol="geom", idCol="id_base_site")
class TBaseSites(DB.Model):
    """
    Table centralisant les données élémentaire des sites
    """

    __tablename__ = "t_base_sites"
    __table_args__ = {"schema": "gn_monitoring"}
    id_base_site: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    id_inventor: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_digitiser: Mapped[Optional[int]] = mapped_column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    base_site_name: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    base_site_description: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    base_site_code: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    first_use_date: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    geom: Mapped[Optional[Any]] = mapped_column(Geometry("GEOMETRY", 4326))
    geom_local: Mapped[Optional[Any]] = mapped_column(Geometry("GEOMETRY"))
    uuid_base_site: Mapped[Optional[Any]] = mapped_column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))

    meta_create_date: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    meta_update_date: Mapped[Optional[datetime]] = mapped_column(DB.DateTime)
    altitude_min: Mapped[Optional[int]]
    altitude_max: Mapped[Optional[int]]
    digitiser = relationship(
        User, primaryjoin=(User.id_role == id_digitiser), foreign_keys=[id_digitiser]
    )
    inventor = relationship(
        User, primaryjoin=(User.id_role == id_inventor), foreign_keys=[id_inventor]
    )

    t_base_visits = relationship("TBaseVisits", lazy="select", cascade="all,delete-orphan")

    modules = DB.relationship(
        "TModules",
        lazy="select",
        enable_typechecks=False,
        secondary=cor_site_module,
        primaryjoin=(cor_site_module.c.id_base_site == id_base_site),
        secondaryjoin=(cor_site_module.c.id_module == TModules.id_module),
        foreign_keys=[cor_site_module.c.id_base_site, cor_site_module.c.id_module],
    )

    id_import: Mapped[Optional[int]]


corIndividualModule = DB.Table(
    "cor_individual_module",
    DB.Column(
        "id_individual",
        DB.Integer,
        DB.ForeignKey("gn_monitoring.t_individuals.id_individual", ondelete="CASCADE"),
        primary_key=True,
    ),
    DB.Column(
        "id_module",
        DB.Integer,
        DB.ForeignKey("gn_commons.t_modules.id_module", ondelete="CASCADE"),
        primary_key=True,
    ),
    schema="gn_monitoring",
)


@serializable
class TObservations(DB.Model):
    __tablename__ = "t_observations"
    __table_args__ = {"schema": "gn_monitoring"}
    id_observation: Mapped[int] = mapped_column(DB.Integer, primary_key=True, unique=True)
    id_base_visit: Mapped[Optional[int]] = mapped_column(DB.ForeignKey("gn_monitoring.t_base_visits.id_base_visit"))
    id_digitiser: Mapped[Optional[int]] = mapped_column(DB.Integer, DB.ForeignKey("utilisateurs.t_roles.id_role"))
    digitiser = DB.relationship(
        User, primaryjoin=(User.id_role == id_digitiser), foreign_keys=[id_digitiser]
    )
    cd_nom: Mapped[int] = mapped_column(DB.Integer, DB.ForeignKey("taxonomie.taxref.cd_nom"))
    comments: Mapped[Optional[str]] = mapped_column(DB.String)
    uuid_observation: Mapped[Optional[Any]] = mapped_column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))
    id_import: Mapped[Optional[int]]
    id_individual: Mapped[Optional[int]] = mapped_column(DB.ForeignKey("gn_monitoring.t_individuals.id_individual"))


@serializable
class TMarkingEvent(DB.Model):
    __tablename__ = "t_marking_events"
    __table_args__ = {"schema": "gn_monitoring"}

    id_marking: Mapped[int] = mapped_column(DB.Integer, primary_key=True, autoincrement=True)
    uuid_marking: Mapped[Optional[Any]] = mapped_column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))
    id_individual: Mapped[int] = mapped_column(
        DB.ForeignKey(f"gn_monitoring.t_individuals.id_individual", ondelete="CASCADE"),
    )
    id_module: Mapped[int] = mapped_column(
        DB.ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
        unique=True,
    )
    id_digitiser: Mapped[int] = mapped_column(
        DB.ForeignKey("utilisateurs.t_roles.id_role"),
    )
    marking_date: Mapped[datetime] = mapped_column(DB.DateTime(timezone=False))
    id_operator: Mapped[int] = mapped_column(DB.ForeignKey("utilisateurs.t_roles.id_role"))
    id_base_marking_site: Mapped[Optional[int]] = mapped_column(DB.ForeignKey("gn_monitoring.t_base_sites.id_base_site"))
    id_nomenclature_marking_type: Mapped[int] = mapped_column(
        DB.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature")
    )
    marking_location: Mapped[Optional[str]] = mapped_column(DB.Unicode(255))
    marking_code: Mapped[Optional[str]] = mapped_column(DB.Unicode(255))
    marking_details: Mapped[Optional[str]] = mapped_column(DB.Text)
    data: Mapped[Optional[Any]] = mapped_column(JSONB)

    operator = DB.relationship(User, lazy="joined", foreign_keys=[id_operator])

    digitiser = DB.relationship(User, lazy="joined", foreign_keys=[id_digitiser])

    medias = DB.relationship(
        TMedias,
        lazy="joined",
        primaryjoin=(TMedias.uuid_attached_row == uuid_marking),
        foreign_keys=[TMedias.uuid_attached_row],
        overlaps="medias,medias",
    )

    @hybrid_property
    def organism_actors(self):
        # return self.digitiser.id_organisme
        actors_organism_list = []
        if isinstance(self.digitiser, User):
            actors_organism_list.append(self.digitiser.id_organisme)
        if isinstance(self.operator, User):
            actors_organism_list.append(self.operator.id_organisme)
        return actors_organism_list

    def has_instance_permission(self, scope):
        if scope == 0:
            return False
        elif scope in (1, 2):
            if (
                g.current_user.id_role == self.id_digitiser
                or g.current_user.id_role == self.id_operator
            ):
                return True
            if scope == 2 and g.current_user.id_organisme in self.organism_actors:
                return True
        elif scope == 3:
            return True
        return False


@serializable
class TIndividuals(DB.Model):
    __tablename__ = "t_individuals"
    __table_args__ = {"schema": "gn_monitoring"}
    id_individual: Mapped[int] = mapped_column(DB.Integer, primary_key=True)
    uuid_individual: Mapped[Any] = mapped_column(UUID, server_default=DB.text("uuid_generate_v4()"))
    individual_name: Mapped[str] = mapped_column(DB.Unicode(255))
    cd_nom: Mapped[int] = mapped_column(DB.Integer, DB.ForeignKey("taxonomie.taxref.cd_nom"))
    id_nomenclature_sex: Mapped[Optional[int]] = mapped_column(
        DB.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        server_default=DB.text(
            "ref_nomenclatures.get_default_nomenclature_value('SEXE'::character varying)"
        ),
    )
    active: Mapped[Optional[bool]] = mapped_column(DB.Boolean, default=True)
    comment: Mapped[Optional[str]] = mapped_column(DB.Text)
    id_digitiser: Mapped[int] = mapped_column(
        DB.ForeignKey("utilisateurs.t_roles.id_role"),
    )

    meta_create_date: Mapped[Optional[datetime]] = mapped_column(
        "meta_create_date", DB.DateTime(timezone=False), server_default=FetchedValue()
    )
    meta_update_date: Mapped[Optional[datetime]] = mapped_column(
        "meta_update_date",
        DB.DateTime(timezone=False),
        server_default=FetchedValue(),
        onupdate=datetime.now,
    )

    digitiser = DB.relationship(
        User,
        lazy="joined",
    )

    nomenclature_sex = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_sex),
    )

    modules = DB.relationship(
        "TModules",
        lazy="joined",
        secondary=corIndividualModule,
        primaryjoin=(corIndividualModule.c.id_individual == id_individual),
        secondaryjoin=(corIndividualModule.c.id_module == TModules.id_module),
        foreign_keys=[corIndividualModule.c.id_individual, corIndividualModule.c.id_module],
    )

    markings = DB.relationship(
        TMarkingEvent,
        primaryjoin=(id_individual == TMarkingEvent.id_individual),
    )

    medias = DB.relationship(
        TMedias,
        lazy="joined",
        primaryjoin=(TMedias.uuid_attached_row == uuid_individual),
        foreign_keys=[TMedias.uuid_attached_row],
        overlaps="medias",
    )

    @classmethod
    def filter_by_scope(cls, query, scope, user=None):
        if user is None:
            user = g.current_user
        if scope == 0:
            query = query.where(false())
        elif scope in (1, 2):
            ors = [
                cls.id_digitiser == user.id_role,
            ]
            # if organism is None => do not filter on id_organism even if level = 2
            if scope == 2 and user.id_organisme is not None:
                ors.append(cls.digitiser.has(id_organisme=user.id_organisme))
            query = query.where(or_(*ors))
        return query

    @hybrid_property
    def organism_actors(self):
        # return self.digitiser.id_organisme
        actors_organism_list = []
        if isinstance(self.digitiser, User):
            actors_organism_list.append(self.digitiser.id_organisme)

        return actors_organism_list

    def has_instance_permission(self, scope):
        if scope == 0:
            return False
        elif scope in (1, 2):
            if g.current_user.id_role == self.id_digitiser:
                return True
            if scope == 2 and g.current_user.id_organisme in self.organism_actors:
                return True
        elif scope == 3:
            return True
        return False
