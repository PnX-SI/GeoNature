from collections import OrderedDict

from flask import current_app
from sqlalchemy import ForeignKey, or_, Sequence
from sqlalchemy.orm import relationship
from sqlalchemy.sql import select, func
from sqlalchemy.dialects.postgresql import UUID
from geoalchemy2 import Geometry
from geoalchemy2.shape import to_shape
from geojson import Feature

from werkzeug.exceptions import NotFound

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable

from geonature.utils.utilssqlalchemy import geoserializable, SERIALIZERS
from geonature.utils.utilsgeometry import shapeserializable
from geonature.utils.env import DB
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework
from geonature.core.ref_geo.models import LAreas
from geonature.core.ref_geo.models import LiMunicipalities
from geonature.core.gn_commons.models import THistoryActions, TValidations
from pypnusershub.db.tools import InsufficientRightsError


class SyntheseCruved(DB.Model):
    """
        Abstract class to add method
        to control the data access according
        to the user rights

        Currently not used, the cruved on data is managed
        by the module himself when the user is redirect to the source module
    """

    __abstract__ = True

    def user_is_observer(self, user):
        # faire la vérification sur le champs observateur ?
        cor_observers = [d.id_role for d in self.cor_observers]
        # return user.id_role == self.id_digitiser or user.id_role in observers
        return user.id_role in cor_observers

    def user_is_in_dataset_actor(self, user_datasets):
        return self.id_dataset in user_datasets

    def user_is_allowed_to(self, user, level, user_datasets):
        """
            Function to know if a user can do action
            on a data
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données

        if level not in ("1", "2", "3"):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if level == "3":
            return True

        # Si l'utilisateur est propriétaire de la données
        if self.user_is_observer(user):
            return True

        # Si l'utilisateur appartient à un organisme
        # qui a un droit sur la données et
        # que son niveau d'accès est 2 ou 3
        if self.user_is_in_dataset_actor(user_datasets) and level in ("2", "3"):
            return True
        return False

    def get_observation_if_allowed(self, user, user_datasets):
        """
            Return the observation if the user is allowed
            params:
                user: object from TRole
        """
        if self.user_is_allowed_to(user, user.value_filter, user_datasets):
            return self

        raise InsufficientRightsError(
            ('User "{}" cannot "{}" this current releve').format(
                user.id_role, user.code_action
            ),
            403,
        )

    def get_synthese_cruved(self, user, user_cruved, users_datasets):
        """
        Return the user's cruved for a Synthese instance.
        Use in the map-list interface to allow or not an action
        params:
            - user : a TRole object
            - user_cruved: object return by cruved_for_user_in_app(user)
            - users_dataset: array of dataset ids where the users have rights
        """
        return {
            action: self.user_is_allowed_to(user, level, users_datasets)
            for action, level in user_cruved.items()
        }


@serializable
class TSources(DB.Model):
    __tablename__ = "t_sources"
    __table_args__ = {"schema": "gn_synthese"}
    id_source = DB.Column(DB.Integer, primary_key=True)
    name_source = DB.Column(DB.Unicode)
    desc_source = DB.Column(DB.Unicode)
    entity_source_pk_field = DB.Column(DB.Unicode)
    url_source = DB.Column(DB.Unicode)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)


@serializable
class CorObserverSynthese(DB.Model):
    __tablename__ = "cor_observer_synthese"
    __table_args__ = {"schema": "gn_synthese"}
    id_synthese = DB.Column(
        DB.Integer, ForeignKey("gn_synthese.synthese.id_synthese"), primary_key=True
    )
    id_role = DB.Column(
        DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"), primary_key=True
    )


corAreaSynthese = DB.Table(
    "cor_area_synthese",
    DB.MetaData(schema="gn_synthese"),
    DB.Column(
        "id_synthese",
        DB.Integer,
        ForeignKey("gn_synthese.cor_area_synthese.id_synthese"),
        primary_key=True,
    ),
    DB.Column(
        "id_area", DB.Integer, ForeignKey("ref_geo.t_areas.id_area"), primary_key=True
    ),
)


@serializable
class VSyntheseDecodeNomenclatures(DB.Model):
    __tablename__ = "v_synthese_decode_nomenclatures"
    __table_args__ = {"schema": "gn_synthese"}
    id_synthese = DB.Column(DB.Integer, primary_key=True)
    nat_obj_geo = DB.Column(DB.Unicode)
    grp_typ = DB.Column(DB.Unicode)
    obs_method = DB.Column(DB.Unicode)
    obs_technique = DB.Column(DB.Unicode)
    bio_status = DB.Column(DB.Unicode)
    bio_condition = DB.Column(DB.Unicode)
    naturalness = DB.Column(DB.Unicode)
    exist_proof = DB.Column(DB.Unicode)
    valid_status = DB.Column(DB.Unicode)
    diffusion_level = DB.Column(DB.Unicode)
    life_stage = DB.Column(DB.Unicode)
    sex = DB.Column(DB.Unicode)
    obj_count = DB.Column(DB.Unicode)
    type_count = DB.Column(DB.Unicode)
    sensitivity = DB.Column(DB.Unicode)
    observation_status = DB.Column(DB.Unicode)
    blurring = DB.Column(DB.Unicode)
    source_status = DB.Column(DB.Unicode)


@serializable
@geoserializable
@shapeserializable
class Synthese(DB.Model):
    __tablename__ = "synthese"
    __table_args__ = {"schema": "gn_synthese"}
    id_synthese = DB.Column(DB.Integer, primary_key=True)
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer)
    entity_source_pk_value = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    id_nomenclature_geo_object_nature = DB.Column(DB.Integer)
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    id_nomenclature_obs_meth = DB.Column(DB.Integer)
    id_nomenclature_obs_technique = DB.Column(DB.Integer)
    id_nomenclature_bio_status = DB.Column(DB.Integer)
    id_nomenclature_bio_condition = DB.Column(DB.Integer)
    id_nomenclature_naturalness = DB.Column(DB.Integer)
    id_nomenclature_exist_proof = DB.Column(DB.Integer)
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    id_nomenclature_diffusion_level = DB.Column(DB.Integer)
    id_nomenclature_life_stage = DB.Column(DB.Integer)
    id_nomenclature_sex = DB.Column(DB.Integer)
    id_nomenclature_obj_count = DB.Column(DB.Integer)
    id_nomenclature_type_count = DB.Column(DB.Integer)
    id_nomenclature_sensitivity = DB.Column(DB.Integer)
    id_nomenclature_observation_status = DB.Column(DB.Integer)
    id_nomenclature_blurring = DB.Column(DB.Integer)
    id_nomenclature_source_status = DB.Column(DB.Integer)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    nom_cite = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(DB.Unicode)
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    altitude_min = DB.Column(DB.Unicode)
    altitude_max = DB.Column(DB.Unicode)
    the_geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    the_geom_point = DB.Column(Geometry("GEOMETRY", 4326))
    the_geom_local = DB.Column(Geometry("GEOMETRY", current_app.config["LOCAL_SRID"]))
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    validator = DB.Column(DB.Unicode)
    validation_comment = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode)
    determiner = DB.Column(DB.Unicode)
    id_digitiser = DB.Column(DB.Integer)
    id_nomenclature_determination_method = DB.Column(DB.Integer)
    comment_context = DB.Column(DB.Unicode)
    comment_description = DB.Column(DB.Unicode)
    meta_validation_date = DB.Column(DB.DateTime)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    last_action = DB.Column(DB.Unicode)

    def get_geofeature(self, recursif=True, columns=None):
        return self.as_geofeature(
            "the_geom_4326", "id_synthese", recursif, columns=columns
        )


@serializable
class CorAreaSynthese(DB.Model):
    __tablename__ = "cor_area_synthese"
    __table_args__ = {"schema": "gn_synthese"}
    id_synthese = DB.Column(DB.Integer, primary_key=True)
    id_area = DB.Column(DB.Integer)


@serializable
class DefaultsNomenclaturesValue(DB.Model):
    __tablename__ = "defaults_nomenclatures_value"
    __table_args__ = {"schema": "gn_synthese"}
    mnemonique_type = DB.Column(DB.Integer, primary_key=True)
    id_organism = DB.Column(DB.Integer, primary_key=True)
    regne = DB.Column(DB.Unicode, primary_key=True)
    group2_inpn = DB.Column(DB.Unicode, primary_key=True)
    id_nomenclature = DB.Column(DB.Integer)


@serializable
class VMTaxonsSyntheseAutocomplete(DB.Model):
    __tablename__ = "taxons_synthese_autocomplete"
    __table_args__ = {"schema": "gn_synthese"}
    cd_nom = DB.Column(DB.Integer, primary_key=True)
    search_name = DB.Column(DB.Unicode, primary_key=True)
    cd_ref = DB.Column(DB.Integer)
    nom_valide = DB.Column(DB.Unicode)
    lb_nom = DB.Column(DB.Unicode)
    regne = DB.Column(DB.Unicode)
    group2_inpn = DB.Column(DB.Unicode)

    def __repr__(self):
        return "<VMTaxonsSyntheseAutocomplete  %r>" % self.search_name


@serializable
@geoserializable
class VSyntheseForWebApp(DB.Model):
    __tablename__ = "v_synthese_for_web_app"
    __table_args__ = {"schema": "gn_synthese"}

    id_synthese = DB.Column(
        DB.Integer,
        ForeignKey("gn_synthese.v_synthese_decode_nomenclatures.id_synthese"),
        primary_key=True,
    )
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    unique_id_sinp_grp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer)
    entity_source_pk_value = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    dataset_name = DB.Column(DB.Integer)
    id_acquisition_framework = DB.Column(DB.Integer)
    count_min = DB.Column(DB.Integer)
    count_max = DB.Column(DB.Integer)
    cd_nom = DB.Column(DB.Integer)
    cd_ref = DB.Column(DB.Unicode)
    nom_cite = DB.Column(DB.Unicode)
    nom_valide = DB.Column(DB.Unicode)
    nom_vern = DB.Column(DB.Unicode)
    lb_nom = DB.Column(DB.Unicode)
    meta_v_taxref = DB.Column(DB.Unicode)
    sample_number_proof = DB.Column(DB.Unicode)
    digital_proof = DB.Column(DB.Unicode)
    non_digital_proof = DB.Column(DB.Unicode)
    altitude_min = DB.Column(DB.Unicode)
    altitude_max = DB.Column(DB.Unicode)
    the_geom_4326 = DB.Column(Geometry("GEOMETRY", 4326))
    date_min = DB.Column(DB.DateTime)
    date_max = DB.Column(DB.DateTime)
    validator = DB.Column(DB.Unicode)
    validation_comment = DB.Column(DB.Unicode)
    observers = DB.Column(DB.Unicode)
    determiner = DB.Column(DB.Unicode)
    id_digitiser = DB.Column(DB.Integer)
    comment_context = DB.Column(DB.Unicode)
    comment_description = DB.Column(DB.Unicode)
    meta_validation_date = DB.Column(DB.DateTime)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    last_action = DB.Column(DB.Unicode)
    id_nomenclature_geo_object_nature = DB.Column(DB.Integer)
    id_nomenclature_info_geo_type = DB.Column(DB.Integer)
    id_nomenclature_grp_typ = DB.Column(DB.Integer)
    id_nomenclature_obs_meth = DB.Column(DB.Integer)
    id_nomenclature_obs_technique = DB.Column(DB.Integer)
    id_nomenclature_bio_status = DB.Column(DB.Integer)
    id_nomenclature_bio_condition = DB.Column(DB.Integer)
    id_nomenclature_naturalness = DB.Column(DB.Integer)
    id_nomenclature_exist_proof = DB.Column(DB.Integer)
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    id_nomenclature_diffusion_level = DB.Column(DB.Integer)
    id_nomenclature_life_stage = DB.Column(DB.Integer)
    id_nomenclature_sex = DB.Column(DB.Integer)
    id_nomenclature_obj_count = DB.Column(DB.Integer)
    id_nomenclature_type_count = DB.Column(DB.Integer)
    id_nomenclature_sensitivity = DB.Column(DB.Integer)
    id_nomenclature_observation_status = DB.Column(DB.Integer)
    id_nomenclature_blurring = DB.Column(DB.Integer)
    id_nomenclature_source_status = DB.Column(DB.Integer)
    id_nomenclature_valid_status = DB.Column(DB.Integer)
    name_source = DB.Column(DB.Unicode)
    url_source = DB.Column(DB.Unicode)
    st_asgeojson = DB.Column(DB.Unicode)

    def get_geofeature(self, recursif=False, columns=()):
        return self.as_geofeature(
            "the_geom_4326", "id_synthese", recursif, columns=columns
        )


# Non utilisé - laissé pour exemple d'une sérialisation ordonnée
def synthese_export_serialization(cls):
    """
    Décorateur qui definit une serialisation particuliere pour la vue v_synthese_for_export
    Il rajoute la fonction as_dict_ordered qui conserve l'ordre des attributs tel que definit dans le model
    (fonctions utilisees pour les exports) et qui redefinit le nom des colonnes tel qu'ils sont nommes en configuration
    """
    EXPORT_COLUMNS = current_app.config["SYNTHESE"]["EXPORT_COLUMNS"]
    # tab of cls attributes from EXPORT COLUMNS
    formated_default_columns = [key for key, value in EXPORT_COLUMNS.items()]

    # list of tuple (class attribute, serializer)
    cls_db_cols_and_serializer = []
    # list of attributes of the class which are in the synthese export cnfig
    # use for generate shapefiles
    cls.db_cols = []
    for key in formated_default_columns:
        # get the cls attribut:
        try:
            # get the class atribut from the syntese export config
            cls_attri = getattr(cls, key)
            # add in serialiser list
            if not cls_attri.type.__class__.__name__ == "Geometry":
                cls_db_cols_and_serializer.append(
                    (
                        cls_attri.key,
                        SERIALIZERS.get(
                            cls_attri.type.__class__.__name__.lower(), lambda x: x
                        ),
                    )
                )
            # add in cls.db_cols
            cls.db_cols.append(cls_attri)
        # execpt if the attribute does not exist
        except AttributeError:
            pass

    def serialize_order_fn(self):
        order_dict = OrderedDict()
        for item, _serializer in cls_db_cols_and_serializer:
            order_dict.update(
                {EXPORT_COLUMNS.get(item): _serializer(getattr(self, item))}
            )
        return order_dict

    def serialize_geofn(self, geoCol, idCol):
        if not getattr(self, geoCol) is None:
            geometry = to_shape(getattr(self, geoCol))
        else:
            geometry = {"type": "Point", "coordinates": [0, 0]}

        feature = Feature(
            id=str(getattr(self, idCol)),
            geometry=geometry,
            properties=self.as_dict_ordered(),
        )
        return feature

    cls.as_dict_ordered = serialize_order_fn
    cls.as_geofeature_ordered = serialize_geofn

    return cls


@serializable
@geoserializable
class SyntheseOneRecord(VSyntheseDecodeNomenclatures):
    """
    Model for display details information about one synthese observation
    Herited from VSyntheseDecodeNomenclatures model for all decoded nomenclatures
    """

    __tablename__ = "synthese"
    __table_args__ = {"schema": "gn_synthese", "extend_existing": True}
    id_synthese = DB.Column(
        DB.Integer,
        ForeignKey("gn_synthese.v_synthese_decode_nomenclatures.id_synthese"),
        primary_key=True,
    )
    unique_id_sinp = DB.Column(UUID(as_uuid=True))
    id_source = DB.Column(DB.Integer)
    id_dataset = DB.Column(DB.Integer)
    source = DB.relationship(
        "TSources",
        primaryjoin=(TSources.id_source == id_source),
        foreign_keys=[id_source],
    )
    areas = DB.relationship(
        "LAreas",
        secondary=corAreaSynthese,
        primaryjoin=(corAreaSynthese.c.id_synthese == id_synthese),
        secondaryjoin=(corAreaSynthese.c.id_area == LAreas.id_area),
        foreign_keys=[corAreaSynthese.c.id_synthese, corAreaSynthese.c.id_area],
    )
    datasets = DB.relationship(
        "TDatasets",
        primaryjoin=(TDatasets.id_dataset == id_dataset),
        foreign_keys=[id_dataset],
    )
    acquisition_framework = DB.relationship(
        "TAcquisitionFramework",
        uselist=False,
        secondary=TDatasets.__table__,
        primaryjoin=(TDatasets.id_dataset == id_dataset),
        secondaryjoin=(
            TDatasets.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework
        ),
    )

    cor_observers = DB.relationship(
        "User",
        uselist=True,
        secondary=CorObserverSynthese.__table__,
        primaryjoin=(CorObserverSynthese.id_synthese == id_synthese),
        secondaryjoin=(User.id_role == CorObserverSynthese.id_role),
    )
    validations = DB.relationship(
        "TValidations",
        primaryjoin=(TValidations.uuid_attached_row == unique_id_sinp),
        foreign_keys=[unique_id_sinp],
        uselist=True,
    )


@serializable
class VColorAreaTaxon(DB.Model):
    __tablename__ = "v_color_taxon_area"
    __table_args__ = {"schema": "gn_synthese"}
    cd_nom = DB.Column(
        DB.Integer(), ForeignKey("taxonomie.taxref.cd_nom"), primary_key=True
    )
    id_area = DB.Column(
        DB.Integer(), ForeignKey("ref_geo.l_area.id_area"), primary_key=True
    )
    nb_obs = DB.Column(DB.Integer())
    last_date = DB.Column(DB.DateTime())
    color = DB.Column(DB.Unicode())
