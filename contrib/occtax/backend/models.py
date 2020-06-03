from flask import current_app
from geoalchemy2 import Geometry
from sqlalchemy import ForeignKey, not_
from sqlalchemy.sql import select, func, and_
from sqlalchemy.orm import relationship, backref
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.inspection import inspect

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.tools import InsufficientRightsError
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable
from utils_flask_sqla_geo.serializers import geoserializable
from utils_flask_sqla_geo.serializers import geoserializable

from geonature.core.taxonomie.models import Taxref
from geonature.core.gn_meta.models import TDatasets
from geonature.core.taxonomie.models import Taxref
from geonature.utils.env import DB


class OcctaxModel(DB.Model):
    """
        Classe abstraite permettant d'ajout des méthodes
        de controle d'accès à la donnée en fonction
        des droits associés à un utilisateur
    """
    __abstract__ = True

    def __init__(self, **kwargs):
        kwargs['_force'] = True
        self._set_columns(**kwargs)

    def _set_columns(self, **kwargs):
        force = kwargs.get('_force')

        readonly = []
        if hasattr(self, 'readonly_fields'):
            readonly = self.readonly_fields
        if hasattr(self, 'hidden_fields'):
            readonly += self.hidden_fields

        columns = self.__table__.columns.keys()
        relationships = self.__mapper__.relationships.keys()

        for key in columns:
            allowed = True if force or key not in readonly else False
            exists = True if key in kwargs else False
            if allowed and exists:
                val = getattr(self, key)
                if val != kwargs[key]:
                    setattr(self, key, kwargs[key])

        for rel in relationships:
            allowed = True if force or rel not in readonly else False
            exists = True if rel in kwargs else False
            if allowed and exists:
                is_list = self.__mapper__.relationships[rel].uselist
                if is_list:
                    valid_ids = []
                    cls = self.__mapper__.relationships[rel].argument()
                    pk = cls.__table__.primary_key.columns.keys()[0]
                    query = getattr(self, rel)
                    for item in kwargs[rel]:
                        if pk in item and item.get(pk) is not None and query.filter(getattr(cls, pk) == item.get(pk)).limit(1).count() == 1:
                            obj = cls.query.filter(getattr(cls, pk) == item.get(pk)).first()
                            obj.set_columns(**item)
                            valid_ids.append(str(item.get(pk)))
                        else:
                            col = cls()
                            col.set_columns(**item)
                            query.append(col)
                            DB.session.flush()
                            valid_ids.append(str(getattr(col, pk)))

                    # delete related rows that were not in kwargs[rel]
                    if inspect(self).identity is not None:
                        for item in query.filter(not_(getattr(cls, pk).in_(valid_ids))).all():
                            query.remove(item)
                else:
                    val = getattr(self, rel)
                    if self.__mapper__.relationships[rel].query_class is not None:
                        if val is not None:
                            val.set_columns(**kwargs[rel])
                    else:
                        if val != kwargs[rel]:
                            setattr(self, rel, kwargs[rel])
        return self

    def set_columns(self, **kwargs):
        self._set_columns(**kwargs)
        return self

class ReleveModel(OcctaxModel):
    """
        Classe abstraite permettant d'ajout des méthodes
        de controle d'accès à la donnée en fonction
        des droits associés à un utilisateur
    """

    __abstract__ = True

    def user_is_observer_or_digitiser(self, user):
        observers = [d.id_role for d in self.observers]
        return user.id_role == self.id_digitiser or user.id_role in observers

    def user_is_in_dataset_actor(self, user):
        return self.id_dataset in TDatasets.get_user_datasets(user)

    def user_is_allowed_to(self, user, level):
        """
            Fonction permettant de dire si un utilisateur
            peu ou non agir sur une donnée
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données
        if level == "0" or level not in ("1", "2", "3"):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if level == "3":
            return True

        # Si l'utilisateur est propriétaire de la données
        if self.user_is_observer_or_digitiser(user):
            return True

        # Si l'utilisateur appartient à un organisme
        # qui a un droit sur la données et
        # que son niveau d'accès est 2 ou 3
        if self.user_is_in_dataset_actor(user) and level in ("2", "3"):
            return True
        return False

    def get_releve_if_allowed(self, user):
        """
            Return the releve if the user is allowed
            params:
                user: object from TRole
        """
        if self.user_is_allowed_to(user, user.value_filter):
            return self

        raise InsufficientRightsError(
            ('User "{}" cannot "{}" this current releve').format(
                user.id_role, user.code_action
            ),
            403,
        )

    def get_releve_cruved(self, user, user_cruved):
        """
        Return the user's cruved for a Releve instance.
        Use in the map-list interface to allow or not an action
        params:
            - user : a TRole object
            - user_cruved: object return by cruved_for_user_in_app(user)
        """
        return {
            action: self.user_is_allowed_to(user, level)
            for action, level in user_cruved.items()
        }


class corRoleRelevesOccurrence(OcctaxModel):
    __tablename__ = "cor_role_releves_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    unique_id_cor_role_releve = DB.Column(
        "unique_id_cor_role_releve",
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()]),
        primary_key=True,
    )
    id_releve_occtax = DB.Column(
        "id_releve_occtax",
        DB.Integer,
        ForeignKey("pr_occtax.t_releves_occtax.id_releve_occtax"),
        primary_key=False,
    )
    id_role = DB.Column(
        "id_role",
        DB.Integer,
        ForeignKey("utilisateurs.t_roles.id_role"),
        primary_key=False,
    )


@serializable
class CorCountingOccurrence(OcctaxModel):
    __tablename__ = "cor_counting_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_counting_occtax = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp_occtax = DB.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()])
    )
    id_occurrence_occtax = DB.Column(
        DB.Integer, ForeignKey(
            "pr_occtax.t_occurrences_occtax.id_occurrence_occtax")
    )
    id_nomenclature_life_stage = DB.Column(DB.Integer)
    id_nomenclature_sex = DB.Column(DB.Integer)
    id_nomenclature_obj_count = DB.Column(DB.Integer)
    id_nomenclature_type_count = DB.Column(DB.Integer)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)

    readonly_fields = [
        'id_counting_occtax',
        'unique_id_sinp_occtax',
        'id_occurrence_occtax'
    ]


@serializable
class TOccurrencesOccurrence(OcctaxModel):
    __tablename__ = "t_occurrences_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_occurrence_occtax = DB.Column(DB.Integer, primary_key=True)
    id_releve_occtax = DB.Column(
        DB.Integer, ForeignKey("pr_occtax.t_releves_occtax.id_releve_occtax")
    )
    id_nomenclature_obs_meth = DB.Column(DB.Integer)
    id_nomenclature_bio_condition = DB.Column(DB.Integer)
    id_nomenclature_bio_status = DB.Column(DB.Integer)
    id_nomenclature_naturalness = DB.Column(DB.Integer)
    id_nomenclature_exist_proof = DB.Column(DB.Integer)
    id_nomenclature_diffusion_level = DB.Column(DB.Integer)
    id_nomenclature_observation_status = DB.Column(DB.Integer)
    id_nomenclature_blurring = DB.Column(DB.Integer)
    id_nomenclature_source_status = DB.Column(DB.Integer)
    determiner = DB.Column(DB.Unicode)
    id_nomenclature_determination_method = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer, ForeignKey(Taxref.cd_nom))
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(
        DB.Unicode,
        default=select(
            [func.gn_commons.get_default_parameter("taxref_version")]),
    )
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)

    cor_counting_occtax = relationship(
        "CorCountingOccurrence",
        lazy="dynamic",
        cascade="all,delete-orphan",
        uselist=True,
    )

    taxref = relationship("Taxref", lazy="joined")

    readonly_fields = [
        'id_occurrence_occtax',
        'id_releve_occtax',
        'taxref'
    ]


@serializable
@geoserializable
class TRelevesOccurrence(ReleveModel):
    __tablename__ = "t_releves_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_releve_occtax = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer, ForeignKey(
        "gn_meta.t_datasets.id_dataset"))
    id_digitiser = DB.Column(DB.Integer, ForeignKey(
        "utilisateurs.t_roles.id_role"))
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    observers_txt = DB.Column(DB.Unicode)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    hour_min = DB.Column(DB.DateTime)
    hour_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    id_nomenclature_obs_technique = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    geom_local = DB.Column(
        Geometry("GEOMETRY", current_app.config["LOCAL_SRID"]))

    t_occurrences_occtax = relationship(
        "TOccurrencesOccurrence", lazy="joined", cascade="all, delete-orphan"
    )

    observers = DB.relationship(
        User,
        lazy="joined",
        secondary=corRoleRelevesOccurrence.__table__,
        primaryjoin=(corRoleRelevesOccurrence.id_releve_occtax ==
                     id_releve_occtax),
        secondaryjoin=(corRoleRelevesOccurrence.id_role == User.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.id_releve_occtax,
            corRoleRelevesOccurrence.id_role,
        ],
    )

    digitiser = relationship(
        User, lazy="joined", primaryjoin=(User.id_role == id_digitiser), foreign_keys=[id_digitiser]
    )

    dataset = relationship(
        TDatasets, lazy="joined", primaryjoin=(TDatasets.id_dataset == id_dataset), foreign_keys=[id_dataset]
    )

    readonly_fields = [
        'id_releve_occtax',
        't_occurrences_occtax',
        'observers'
    ]

    def get_geofeature(self, recursif=True):
        return self.as_geofeature("geom_4326", "id_releve_occtax", recursif)


@serializable
@geoserializable
class VReleveOccurrence(ReleveModel):
    __tablename__ = "v_releve_occtax"
    __table_args__ = {"schema": "pr_occtax"}
    id_releve_occtax = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    id_occurrence_occtax = DB.Column(DB.Integer, primary_key=True)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    lb_nom = DB.Column(DB.Unicode)
    nom_valide = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    leaflet_popup = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    observers = DB.relationship(
        User,
        secondary=corRoleRelevesOccurrence.__table__,
        primaryjoin=(corRoleRelevesOccurrence.id_releve_occtax ==
                     id_releve_occtax),
        secondaryjoin=(corRoleRelevesOccurrence.id_role == User.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.id_releve_occtax,
            corRoleRelevesOccurrence.id_role,
        ],
    )

    def get_geofeature(self, recursif=True):
        return self.as_geofeature("geom_4326", "id_occurrence_occtax", recursif)


@serializable
@geoserializable
class VReleveList(ReleveModel):
    __tablename__ = "v_releve_list"
    __table_args__ = {"schema": "pr_occtax"}
    id_releve_occtax = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer)
    id_digitiser = DB.Column(DB.Integer)
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    altitude_min = DB.Column(DB.Integer)
    altitude_max = DB.Column(DB.Integer)
    meta_device_entry = DB.Column(DB.Unicode)
    comment = DB.Column(DB.Unicode)
    geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    taxons = DB.Column(DB.Unicode)
    leaflet_popup = DB.Column(DB.Unicode)
    observateurs = DB.Column(DB.Unicode)
    dataset_name = DB.Column(DB.Unicode)
    observers_txt = DB.Column(DB.Unicode)
    nb_occ = DB.Column(DB.Integer)
    nb_observer = DB.Column(DB.Integer)
    observers = DB.relationship(
        User,
        secondary=corRoleRelevesOccurrence.__table__,
        primaryjoin=(corRoleRelevesOccurrence.id_releve_occtax ==
                     id_releve_occtax),
        secondaryjoin=(corRoleRelevesOccurrence.id_role == User.id_role),
        foreign_keys=[
            corRoleRelevesOccurrence.id_releve_occtax,
            corRoleRelevesOccurrence.id_role,
        ],
    )

    def get_geofeature(self, recursif=True):

        return self.as_geofeature("geom_4326", "id_releve_occtax", recursif)


@serializable
class DefaultNomenclaturesValue(DB.Model):
    __tablename__ = "defaults_nomenclatures_value"
    __table_args__ = {"schema": "pr_occtax"}
    mnemonique_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer, primary_key=True)
