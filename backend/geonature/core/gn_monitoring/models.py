"""
    Modèles du schéma gn_monitoring
    Correspond a la centralisation des données de base
        relatifs aux protocoles de suivis
"""

from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import select, func
from sqlalchemy.schema import FetchedValue


from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from ref_geo.models import LAreas
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import TDatasets
from geonature.utils.env import DB


corVisitObserver = DB.Table(
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


corSiteModule = DB.Table(
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

corSiteArea = DB.Table(
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
    id_module = DB.Column(DB.Integer)

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
        secondary=corVisitObserver,
        primaryjoin=(corVisitObserver.c.id_base_visit == id_base_visit),
        secondaryjoin=(corVisitObserver.c.id_role == User.id_role),
        foreign_keys=[corVisitObserver.c.id_base_visit, corVisitObserver.c.id_role],
    )

    dataset = relationship(
        TDatasets,
        lazy="joined",
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
    id_nomenclature_type_site = DB.Column(DB.Integer)
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
        secondary=corSiteModule,
        primaryjoin=(corSiteModule.c.id_base_site == id_base_site),
        secondaryjoin=(corSiteModule.c.id_module == TModules.id_module),
        foreign_keys=[corSiteModule.c.id_base_site, corSiteModule.c.id_module],
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
class TIndividuals(DB.Model):
    __tablename__ = "t_individuals"
    __table_args__ = {"schema": "gn_monitoring"}
    id_individual = DB.Column(DB.Integer, primary_key=True)
    uuid_individual = DB.Column(UUID, nullable=False, server_default=DB.text("uuid_generate_v4()"))
    individual_name = DB.Column(DB.Unicode(255), nullable=False)
    cd_nom = DB.Column(DB.ForeignKey("taxonomie.taxref.cd_nom"), nullable=False)
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

    meta_create_date = DB.Column("meta_create_date", DB.DateTime(timezone=False))
    meta_update_date = DB.Column("meta_update_date", DB.DateTime(timezone=False))

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


@serializable
class TMarkingEvent(DB.Model):
    __tablename__ = "t_marking_events"
    __table_args__ = {"schema": "gn_monitoring"}

    id_marking = DB.Column(DB.Integer, primary_key=True, autoincrement=True)
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

    # meta_update_date and meta_create_date already present in TIndividuals
