"""
Modèles du schéma gn_monitoring
Correspond a la centralisation des données de base
    relatifs aux protocoles de suivis
"""

from flask import g
from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey, or_, false
from sqlalchemy.orm import relationship
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

    id_nomenclature_type_site = DB.Column(
        DB.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        nullable=False,
        primary_key=True,
    )
    config = DB.Column(JSONB)
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
    id_base_visit = DB.Column(DB.Integer, primary_key=True)
    id_base_site = DB.Column(DB.Integer, ForeignKey("gn_monitoring.t_base_sites.id_base_site"))
    id_digitiser = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_dataset = DB.Column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    # Pour le moment non défini comme une clé étrangère
    #   pour les questions de perfs
    #   a voir en fonction des usage
    id_module = DB.Column(DB.Integer, ForeignKey("gn_commons.t_modules.id_module"))

    visit_date_min = DB.Column(DB.DateTime)
    visit_date_max = DB.Column(DB.DateTime)
    id_nomenclature_tech_collect_campanule = DB.Column(DB.Integer)
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    comments = DB.Column(DB.Unicode)
    uuid_base_visit = DB.Column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))

    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)

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

    observers_txt = DB.Column(DB.Unicode)

    dataset = relationship(
        TDatasets,
        primaryjoin=(TDatasets.id_dataset == id_dataset),
        foreign_keys=[id_dataset],
    )


@serializable
@geoserializable(geoCol="geom", idCol="id_base_site")
class TBaseSites(DB.Model):
    """
    Table centralisant les données élémentaire des sites
    """

    __tablename__ = "t_base_sites"
    __table_args__ = {"schema": "gn_monitoring"}
    id_base_site = DB.Column(DB.Integer, primary_key=True)
    id_inventor = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_digitiser = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    base_site_name = DB.Column(DB.Unicode)
    base_site_description = DB.Column(DB.Unicode)
    base_site_code = DB.Column(DB.Unicode)
    first_use_date = DB.Column(DB.DateTime)
    geom = DB.Column(Geometry("GEOMETRY", 4326))
    uuid_base_site = DB.Column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))

    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
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
    id_observation = DB.Column(DB.Integer, primary_key=True, nullable=False, unique=True)
    id_base_visit = DB.Column(DB.ForeignKey("gn_monitoring.t_base_visits.id_base_visit"))
    id_digitiser = DB.Column(DB.Integer, DB.ForeignKey("utilisateurs.t_roles.id_role"))
    digitiser = DB.relationship(
        User, primaryjoin=(User.id_role == id_digitiser), foreign_keys=[id_digitiser]
    )
    cd_nom = DB.Column(DB.Integer, DB.ForeignKey("taxonomie.taxref.cd_nom"), nullable=False)
    comments = DB.Column(DB.String)
    uuid_observation = DB.Column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))

    id_individual = DB.Column(DB.ForeignKey("gn_monitoring.t_individuals.id_individual"))


@serializable
class TMarkingEvent(DB.Model):
    __tablename__ = "t_marking_events"
    __table_args__ = {"schema": "gn_monitoring"}

    id_marking = DB.Column(DB.Integer, primary_key=True, autoincrement=True)
    uuid_marking = DB.Column(UUID(as_uuid=True), default=select(func.uuid_generate_v4()))
    id_individual = DB.Column(
        DB.ForeignKey(f"gn_monitoring.t_individuals.id_individual", ondelete="CASCADE"),
        nullable=False,
    )
    id_module = DB.Column(
        DB.ForeignKey("gn_commons.t_modules.id_module"),
        primary_key=True,
        nullable=False,
        unique=True,
    )
    id_digitiser = DB.Column(
        DB.ForeignKey("utilisateurs.t_roles.id_role"),
        nullable=False,
    )
    marking_date = DB.Column(DB.DateTime(timezone=False), nullable=False)
    id_operator = DB.Column(DB.ForeignKey("utilisateurs.t_roles.id_role"), nullable=False)
    id_base_marking_site = DB.Column(DB.ForeignKey("gn_monitoring.t_base_sites.id_base_site"))
    id_nomenclature_marking_type = DB.Column(
        DB.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"), nullable=False
    )
    marking_location = DB.Column(DB.Unicode(255))
    marking_code = DB.Column(DB.Unicode(255))
    marking_details = DB.Column(DB.Text)
    data = DB.Column(JSONB)

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
    id_individual = DB.Column(DB.Integer, primary_key=True)
    uuid_individual = DB.Column(UUID, nullable=False, server_default=DB.text("uuid_generate_v4()"))
    individual_name = DB.Column(DB.Unicode(255), nullable=False)
    cd_nom = DB.Column(DB.Integer, DB.ForeignKey("taxonomie.taxref.cd_nom"), nullable=False)
    id_nomenclature_sex = DB.Column(
        DB.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        server_default=DB.text(
            "ref_nomenclatures.get_default_nomenclature_value('SEXE'::character varying)"
        ),
    )
    active = DB.Column(DB.Boolean, default=True)
    comment = DB.Column(DB.Text)
    id_digitiser = DB.Column(
        DB.ForeignKey("utilisateurs.t_roles.id_role"),
        nullable=False,
    )

    meta_create_date = DB.Column(
        "meta_create_date", DB.DateTime(timezone=False), server_default=FetchedValue()
    )
    meta_update_date = DB.Column(
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
    def filter_by_scope(cls, query, scope, user):
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
