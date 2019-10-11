from flask import current_app
from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import select, func, and_
from sqlalchemy.dialects.postgresql import UUID

from geonature.utils.env import DB
from geonature.utils.utilssqlalchemy import serializable, geoserializable
from pypnusershub.db.models import User
from pypnnomenclature.models import TNomenclatures


class CorStationObserverOccHab(DB.Model):
    __tablename__ = "cor_station_observer"
    __table_args__ = {"schema": "pr_occhab"}
    id_cor_station_observer = DB.Column(DB.Integer, primary_key=True)
    id_station = DB.Column(
        "id_station", DB.Integer, ForeignKey("pr_occhab.t_stations.id_station")
    )
    id_role = DB.Column(
        "id_role", DB.Integer, ForeignKey("utilisateurs.t_roles.id_role")
    )


@serializable
class THabitatsOcchab(DB.Model):
    __tablename__ = "t_habitats"
    __table_args__ = {"schema": "pr_occhab"}
    id_habitat = DB.Column(DB.Integer, primary_key=True)
    id_station = DB.Column(DB.Integer, ForeignKey(
        "pr_occhab.t_stations.id_station"))
    unique_id_sinp_hab = DB.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()])
    )
    cd_hab = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    id_nomenclature_determination_type = DB.Column(
        DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    determiner = DB.Column(DB.Unicode)
    id_nomenclature_collection_technique = DB.Column(
        DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    recovery_percentage = DB.Column(DB.Float)
    id_nomenclature_abundance = DB.Column(
        DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    technical_precision = DB.Column(DB.Unicode)
    id_nomenclature_sensitvity = DB.Column(DB.Integer)


@serializable
@geoserializable
class TStationsOcchab(DB.Model):
    __tablename__ = "t_stations"
    __table_args__ = {"schema": "pr_occhab"}
    id_station = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp_station = DB.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()])
    )
    id_dataset = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    observers_txt = DB.Column(DB.Unicode)
    station_name = DB.Column(DB.Unicode)
    is_habitat_complex = DB.Column(DB.Boolean)
    id_nomenclature_exposure = DB.Column(
        DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    depth_min = DB.Column(DB.Integer)
    depth_max = DB.Column(DB.Integer)
    area = DB.Column(DB.Float)
    id_nomenclature_area_surface_calculation = DB.Column(
        DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    id_nomenclature_geographic_object = DB.Column(
        DB.Integer, ForeignKey(TNomenclatures.id_nomenclature))
    comment = DB.Column(DB.Integer)
    geom_4326 = DB.Column(Geometry("GEOMETRY", 4626))

    t_habitats = relationship("THabitatsOcchab", lazy="select")
    observers = DB.relationship(
        User,
        secondary=CorStationObserverOccHab.__table__,
        primaryjoin=(CorStationObserverOccHab.id_station == id_station),
        secondaryjoin=(CorStationObserverOccHab.id_role == User.id_role),
        foreign_keys=[
            CorStationObserverOccHab.id_station,
            CorStationObserverOccHab.id_role,
        ],
    )

    def get_geofeature(self, recursif=True):
        return self.as_geofeature("geom_4326", "id_station", recursif)


@serializable
class OneHabitat(THabitatsOcchab):
    """
    Class which extend THabitatsOcchab with nomenclatures relationships
    use for get ONE habitat and station
    """
    determination_method = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature ==
                     THabitatsOcchab.id_nomenclature_determination_type),
    )

    collection_technique = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature ==
                     THabitatsOcchab.id_nomenclature_collection_technique),
    )
    abundance = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature ==
                     THabitatsOcchab.id_nomenclature_abundance),
    )

    # def as_dict_rel(self, recursif=False, columns=()):
    #     '''
    #         Overrigth as_dict method to set nomenclature object to the id_nomenclature... attributes
    #     '''
    #     hab_dict = self.as_dict()
    #     hab_dict['determination_method'] = dict(self.determination_method)
    #     return hab_dict


@serializable
@geoserializable
class OneStation(TStationsOcchab):
    exposure = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature ==
                     TStationsOcchab.id_nomenclature_exposure),
    )
    area_surface_calculation = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature ==
                     TStationsOcchab.id_nomenclature_area_surface_calculation),
    )
    geographic_object = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature ==
                     TStationsOcchab.id_nomenclature_geographic_object),
    )
