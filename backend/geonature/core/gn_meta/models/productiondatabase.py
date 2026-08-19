import datetime
from typing import Optional

from sqlalchemy import UUID, Boolean, DateTime, ForeignKey, Integer, Unicode, false
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.schema import FetchedValue
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB
from pypnusershub.db.models import User


@serializable
class TProductionDatabase(DB.Model):
    """
    Represents a production database used for data production.
    Links a dataset to the source database it was produced from.
    """

    __tablename__ = "production_database"
    __table_args__ = (
        DB.UniqueConstraint("name", name="uk_production_database_name"),
        {"schema": "gn_meta"},
    )

    id_production_database: Mapped[int] = mapped_column(Integer, primary_key=True)
    uuid_production_database: Mapped[UUID] = mapped_column(UUID, nullable=True)
    name: Mapped[str] = mapped_column(Unicode, unique=True)
    id_contact: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey(User.id_role), nullable=True
    )
    meta_create_date: Mapped[Optional[datetime.datetime]] = mapped_column(
        DateTime, server_default=FetchedValue()
    )
    meta_update_date: Mapped[Optional[datetime.datetime]] = mapped_column(
        DateTime, server_default=FetchedValue()
    )

    is_default: Mapped[bool] = mapped_column(Boolean, server_default=false())

    contact = DB.relationship(User, lazy="joined", foreign_keys=[id_contact])

    def __repr__(self):
        return f"ProductionDatabase<{self.name}>"
