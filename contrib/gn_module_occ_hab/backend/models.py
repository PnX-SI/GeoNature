from flask import current_app
from sqlalchemy import ForeignKey
# import utiles pour déclarer les classes SQLAlchemy
from sqlalchemy.sql import select, func, and_
from sqlalchemy.dialects.postgresql import UUID

from geoalchemy2 import Geometry

# méthode de sérialisation
from geonature.utils.utilssqlalchemy import serializable, geoserializable

# instance de la BDD
from geonature.utils.env import DB

# ajoute la méthode as_dict() à la classe
@serializable
# ajoute la méthode as_geofeature() générant un geojson à la classe
@geoserializable
class MyModel(DB.Model):
    __tablename__ = "my_table"
    __table_args__ = {"schema": "my_schema"}
    my_pk = DB.Column(DB.Integer, primary_key=True)
    my_field = DB.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()])
    )
    geom_local = DB.Column(
        Geometry("GEOMETRY", current_app.config["LOCAL_SRID"]))
