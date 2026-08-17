import datetime
from typing import Optional

from sqlalchemy.orm import relationship, Mapped, mapped_column
from sqlalchemy import Column, ForeignKey, Integer, Table, Unicode
from sqlalchemy.ext.hybrid import hybrid_property
import marshmallow as ma


from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User, Organisme
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB, db

MIN_LENGTH_UUID_OR_DATE_SEARCH_STRING = 5


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
    is_parent = ma.fields.Boolean(allow_none=True)
    opened = ma.fields.Boolean(allow_none=True)

    @ma.post_load(pass_collection=False)
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


cor_acquisition_framework_objectif = Table(
    "cor_acquisition_framework_objectif",
    DB.metadata,
    Column(
        "id_acquisition_framework",
        Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    ),
    Column(
        "id_nomenclature_objectif",
        Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


cor_acquisition_framework_voletsinp = Table(
    "cor_acquisition_framework_voletsinp",
    DB.metadata,
    Column(
        "id_acquisition_framework",
        Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    ),
    Column(
        "id_nomenclature_voletsinp",
        Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


cor_acquisition_framework_territory = Table(
    "cor_acquisition_framework_territory",
    DB.metadata,
    Column(
        "id_acquisition_framework",
        Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    ),
    Column(
        "id_nomenclature_territory",
        Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


@serializable
class CorAcquisitionFrameworkActor(DB.Model):
    __tablename__ = "cor_acquisition_framework_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cafa: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_acquisition_framework: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    id_role: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey(User.id_role))
    id_organism: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey(Organisme.id_organisme))
    id_nomenclature_actor_role: Mapped[int] = mapped_column(
        Integer,
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
    id_cda: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_dataset: Mapped[int] = mapped_column(
        Integer, ForeignKey("gn_meta.t_datasets.id_dataset")
    )
    id_role: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey(User.id_role))
    id_organism: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey(Organisme.id_organisme))

    id_nomenclature_actor_role: Mapped[int] = mapped_column(
        Integer,
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
    # TODO: replace with table used as secondary in relationships
    __tablename__ = "cor_dataset_protocol"
    __table_args__ = {"schema": "gn_meta"}
    id_dataset: Mapped[int] = mapped_column(
        Integer, ForeignKey("gn_meta.t_datasets.id_dataset"), primary_key=True
    )
    id_protocol: Mapped[int] = mapped_column(
        Integer, ForeignKey("gn_meta.sinp_datatype_protocols.id_protocol"), primary_key=True
    )


cor_dataset_objectif = Table(
    "cor_dataset_objectif",
    DB.metadata,
    Column(
        "id_dataset",
        Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    ),
    Column(
        "id_nomenclature_objectif",
        Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


cor_dataset_territory = Table(
    "cor_dataset_territory",
    DB.metadata,
    Column(
        "id_dataset",
        Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    ),
    Column(
        "id_nomenclature_territory",
        Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


@serializable
class TBibliographicReference(db.Model):
    __tablename__ = "t_bibliographical_references"
    __table_args__ = {"schema": "gn_meta"}
    id_bibliographic_reference: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_acquisition_framework: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    publication_url: Mapped[Optional[str]] = mapped_column(Unicode)
    publication_reference: Mapped[str] = mapped_column(Unicode)
