import datetime
from sqlalchemy.orm import relationship, mapped_column, Mapped
from sqlalchemy import ForeignKey
from sqlalchemy.ext.hybrid import hybrid_property
from typing import Optional
import marshmallow as ma


from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User, Organisme
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB, db


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

    @ma.post_load(pass_many=False)
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


cor_acquisition_framework_objectif = db.Table(
    "cor_acquisition_framework_objectif",
    db.Column(
        "id_acquisition_framework",
        db.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    ),
    db.Column(
        "id_nomenclature_objectif",
        db.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


cor_acquisition_framework_voletsinp = db.Table(
    "cor_acquisition_framework_voletsinp",
    db.Column(
        "id_acquisition_framework",
        db.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    ),
    db.Column(
        "id_nomenclature_voletsinp",
        db.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


cor_acquisition_framework_territory = db.Table(
    "cor_acquisition_framework_territory",
    db.Column(
        "id_acquisition_framework",
        db.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    ),
    db.Column(
        "id_nomenclature_territory",
        db.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


@serializable
class CorAcquisitionFrameworkActor(DB.Model):
    __tablename__ = "cor_acquisition_framework_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cafa: Mapped[int] = mapped_column(primary_key=True)
    id_acquisition_framework: Mapped[Optional[int]] = mapped_column(
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    id_role: Mapped[Optional[int]] = mapped_column(ForeignKey(User.id_role))
    id_organism: Mapped[Optional[int]] = mapped_column(ForeignKey(Organisme.id_organisme))
    id_nomenclature_actor_role: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("ROLE_ACTEUR"),
    )

    nomenclature_actor_role: Mapped[Optional[TNomenclatures]] = DB.relationship(
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_actor_role),
    )

    role: Mapped[Optional[User]] = DB.relationship(
        lazy="joined",
    )

    organism: Mapped[Optional[Organisme]] = relationship(
        lazy="joined",
    )


@serializable(exclude=["actor"])
class CorDatasetActor(DB.Model):
    __tablename__ = "cor_dataset_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cda: Mapped[int] = mapped_column(primary_key=True)
    id_dataset: Mapped[Optional[int]] = mapped_column(ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_role: Mapped[Optional[int]] = mapped_column(ForeignKey(User.id_role))
    id_organism: Mapped[Optional[int]] = mapped_column(ForeignKey(Organisme.id_organisme))

    id_nomenclature_actor_role: Mapped[Optional[int]] = mapped_column(
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("ROLE_ACTEUR"),
    )
    nomenclature_actor_role: Mapped[Optional[TNomenclatures]] = DB.relationship(
        lazy="joined",
        foreign_keys=[id_nomenclature_actor_role],
    )

    role: Mapped[Optional[User]] = DB.relationship(lazy="joined")
    organism: Mapped[Optional[Organisme]] = DB.relationship(lazy="joined")

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
    id_cdp: Mapped[int] = mapped_column(primary_key=True)
    id_dataset: Mapped[Optional[int]] = mapped_column(ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_protocol: Mapped[Optional[int]] = mapped_column(ForeignKey("gn_meta.sinp_datatype_protocols.id_protocol"))


cor_dataset_territory = db.Table(
    "cor_dataset_territory",
    db.Column(
        "id_dataset",
        db.Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    ),
    db.Column(
        "id_nomenclature_territory",
        db.Integer,
        ForeignKey(TNomenclatures.id_nomenclature),
        primary_key=True,
    ),
    schema="gn_meta",
)


@serializable
class TBibliographicReference(db.Model):
    __tablename__ = "t_bibliographical_references"
    __table_args__ = {"schema": "gn_meta"}
    id_bibliographic_reference: Mapped[int] = mapped_column(primary_key=True)
    id_acquisition_framework: Mapped[Optional[int]] = mapped_column(
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    publication_url: Mapped[Optional[str]] = mapped_column(DB.Unicode)
    publication_reference: Mapped[Optional[str]] = mapped_column(DB.Unicode)
