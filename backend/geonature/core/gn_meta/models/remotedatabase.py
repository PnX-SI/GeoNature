from sqlalchemy import ForeignKey
from sqlalchemy.schema import FetchedValue
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB
from pypnusershub.db.models import User


@serializable
class TRemoteDatabase(DB.Model):
    """
    Represents a remote database used for data production.
    Links a dataset to the source database it was produced from.
    """

    __tablename__ = "remote_database"
    __table_args__ = (
        DB.UniqueConstraint("name", name="uk_remote_database_name"),
        {"schema": "gn_meta"},
    )

    id_remote_database = DB.Column(DB.Integer, primary_key=True)
    name = DB.Column(DB.Unicode, nullable=False, unique=True)
    id_contact = DB.Column(DB.Integer, ForeignKey(User.id_role), nullable=True)
    meta_create_date = DB.Column(DB.DateTime, server_default=FetchedValue())
    meta_update_date = DB.Column(DB.DateTime, server_default=FetchedValue())

    contact = DB.relationship(User, lazy="joined", foreign_keys=[id_contact])

    def __str__(self):
        return self.name
