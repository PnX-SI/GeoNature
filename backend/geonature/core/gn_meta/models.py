from sqlalchemy import ForeignKey, or_
from sqlalchemy.sql import select, func
from sqlalchemy.orm import relationship, exc
from sqlalchemy.dialects.postgresql import UUID
from werkzeug.exceptions import NotFound

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB
from geonature.core.users.models import BibOrganismes

from geonature.core.gn_commons.models import cor_module_dataset


class CorAcquisitionFrameworkObjectif(DB.Model):
    __tablename__ = "cor_acquisition_framework_objectif"
    __table_args__ = {"schema": "gn_meta"}
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    )
    id_nomenclature_objectif = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    )


class CorAcquisitionFrameworkVoletSINP(DB.Model):
    __tablename__ = "cor_acquisition_framework_voletsinp"
    __table_args__ = {"schema": "gn_meta"}
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    )
    id_nomenclature_voletsinp = DB.Column(
        "id_nomenclature_voletsinp",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )


@serializable
class CorAcquisitionFrameworkActor(DB.Model):
    __tablename__ = "cor_acquisition_framework_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cafa = DB.Column(DB.Integer, primary_key=True)
    id_acquisition_framework = DB.Column(
        DB.Integer, ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    id_role = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_organism = DB.Column(DB.Integer, ForeignKey("utilisateurs.bib_organismes.id_organisme"))
    id_nomenclature_actor_role = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("ROLE_ACTEUR"),
    )

    nomenclature_actor_role = DB.relationship(
        TNomenclatures, primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_actor_role),
    )

    role = DB.relationship(User, primaryjoin=(User.id_role == id_role), foreign_keys=[id_role])

    organism = relationship("BibOrganismes", foreign_keys=[id_organism])

    @staticmethod
    def get_actor(
        id_acquisition_framework, id_nomenclature_actor_role, id_role=None, id_organism=None,
    ):
        """
            Get CorAcquisitionFrameworkActor from id_dataset, id_actor, and id_role or id_organism.
            if no object return None
        """
        try:
            if id_role is None:
                return (
                    DB.session.query(CorAcquisitionFrameworkActor)
                    .filter_by(
                        id_acquisition_framework=id_acquisition_framework,
                        id_organism=id_organism,
                        id_nomenclature_actor_role=id_nomenclature_actor_role,
                    )
                    .one()
                )
            elif id_organism is None:
                return (
                    DB.session.query(CorAcquisitionFrameworkActor)
                    .filter_by(
                        id_acquisition_framework=id_acquisition_framework,
                        id_role=id_role,
                        id_nomenclature_actor_role=id_nomenclature_actor_role,
                    )
                    .one()
                )
        except exc.NoResultFound:
            return None


@serializable
class CorDatasetActor(DB.Model):
    __tablename__ = "cor_dataset_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cda = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_role = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))
    id_organism = DB.Column(DB.Integer, ForeignKey("utilisateurs.bib_organismes.id_organisme"))

    role = DB.relationship(User, primaryjoin=(User.id_role == id_role), foreign_keys=[id_role])
    organism = relationship("BibOrganismes", foreign_keys=[id_organism])

    id_nomenclature_actor_role = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("ROLE_ACTEUR"),
    )
    nomenclature_actor_role = DB.relationship(
        TNomenclatures, primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_actor_role),
    )

    @staticmethod
    def get_actor(id_dataset, id_nomenclature_actor_role, id_role=None, id_organism=None):
        """
            Get CorDatasetActor from id_dataset, id_actor, and id_role or id_organism.
            if no object return None
        """
        try:
            if id_role is None:
                return (
                    DB.session.query(CorDatasetActor)
                    .filter_by(
                        id_dataset=id_dataset,
                        id_organism=id_organism,
                        id_nomenclature_actor_role=id_nomenclature_actor_role,
                    )
                    .one()
                )
            elif id_organism is None:
                return (
                    DB.session.query(CorDatasetActor)
                    .filter_by(
                        id_dataset=id_dataset,
                        id_role=id_role,
                        id_nomenclature_actor_role=id_nomenclature_actor_role,
                    )
                    .one()
                )
        except exc.NoResultFound:
            return None


@serializable
class CorDatasetProtocol(DB.Model):
    __tablename__ = "cor_dataset_protocol"
    __table_args__ = {"schema": "gn_meta"}
    id_cdp = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_protocol = DB.Column(DB.Integer, ForeignKey("gn_meta.sinp_datatype_protocols.id_protocol"))


@serializable
class CorDatasetTerritory(DB.Model):
    __tablename__ = "cor_dataset_territory"
    __table_args__ = {"schema": "gn_meta"}
    id_cdt = DB.Column(DB.Integer, primary_key=True)
    id_dataset = DB.Column(DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"))
    id_protocol = DB.Column(
        DB.Integer, ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature")
    )


@serializable
class CorModuleDataset(DB.Model):
    __tablename__ = "cor_module_dataset"
    __table_args__ = {"schema": "gn_commons", "extend_existing": True}
    id_module = DB.Column(
        DB.Integer, ForeignKey("gn_commons.t_modules.id_module"), primary_key=True
    )
    id_dataset = DB.Column(
        DB.Integer, ForeignKey("gn_meta.t_datasets.id_dataset"), primary_key=True
    )


class CruvedHelper(DB.Model):
    """
    Classe abstraite permettant d'ajouter des méthodes de
    contrôle d'accès à la donnée des class TDatasets et TAcquisitionFramework
    """

    __abstract__ = True

    def user_is_allowed_to(
        self,
        id_object: int,
        id_object_users_actor: list,
        id_object_organism_actor: list,
        level: str,
    ):
        """
            Fonction permettant de dire si un utilisateur
            peu ou non agir sur une donnée

            Params:
                id_object: identifiant de l'objet duquel on contrôle l'accès à la donnée (id_dataset, id_ca)
                id_role: identifiant de la personne qui demande la route
                id_object_users_actor (list): identifiant des objects ou l'utilisateur est lui même acteur
                id_object_organism_actor (list): identifiants des objects ou l'utilisateur ou son organisme sont acteurs

            Return: boolean
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données
        if level == "0" or level not in ("1", "2", "3"):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if level == "3":
            return True

        # Si l'utilisateur est propriétaire de la données
        if id_object in id_object_users_actor:
            return True

        # Si l'utilisateur appartient à un organisme
        # qui a un droit sur la données et
        # que son niveau d'accès est 2 ou 3
        if id_object in id_object_organism_actor and level == "2":
            return True
        return False

    def get_object_cruved(
        self, user_cruved, id_object: int, ids_object_user: list, ids_object_organism: list,
    ):
        """
        Return the user's cruved for a Model instance.
        Use in the map-list interface to allow or not an action
        params:
            - user_cruved: object retourner by cruved_for_user_in_app(user) {'C': '2', 'R':'3' etc...}
            - id_object (int): id de l'objet sur lqurqul on veut vérifier le CRUVED (self.id_dataset/ self.id_ca)
            - id_role: identifiant de la personne qui demande la route
            - id_object_users_actor (list): identifiant des objects ou l'utilisateur est lui même acteur
            - id_object_organism_actor (list): identifiants des objects ou l'utilisateur ou son organisme sont acteurs    

        Return: dict {'C': True, 'R': False ...}
        """
        return {
            action: self.user_is_allowed_to(id_object, ids_object_user, ids_object_organism, level)
            for action, level in user_cruved.items()
        }


@serializable
class TDatasets(CruvedHelper):
    __tablename__ = "t_datasets"
    __table_args__ = {"schema": "gn_meta"}
    id_dataset = DB.Column(DB.Integer, primary_key=True)
    unique_dataset_id = DB.Column(UUID(as_uuid=True), default=select([func.uuid_generate_v4()]))
    id_acquisition_framework = DB.Column(
        DB.Integer, ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    dataset_name = DB.Column(DB.Unicode)
    dataset_shortname = DB.Column(DB.Unicode)
    dataset_desc = DB.Column(DB.Unicode)
    id_nomenclature_data_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("DATA_TYP"),
    )
    keywords = DB.Column(DB.Unicode)
    marine_domain = DB.Column(DB.Boolean)
    terrestrial_domain = DB.Column(DB.Boolean)
    id_nomenclature_dataset_objectif = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("JDD_OBJECTIFS"),
    )
    bbox_west = DB.Column(DB.Float)
    bbox_east = DB.Column(DB.Float)
    bbox_south = DB.Column(DB.Float)
    bbox_north = DB.Column(DB.Float)
    id_nomenclature_collecting_method = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("METHO_RECUEIL"),
    )
    id_nomenclature_data_origin = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("DS_PUBLIQUE"),
    )
    id_nomenclature_source_status = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("STATUT_SOURCE"),
    )
    id_nomenclature_resource_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("RESOURCE_TYP"),
    )
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    active = DB.Column(DB.Boolean, default=True)
    validable = DB.Column(DB.Boolean)
    id_digitizer = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))

    creator = DB.relationship("User", lazy="select")
    modules = DB.relationship("TModules", secondary=cor_module_dataset, lazy="select")

    # HACK: the relationship is not well defined for many to many relationship
    # because CorDatasetActor could be an User or an Organisme object...
    cor_dataset_actor = relationship(
        CorDatasetActor, lazy="select", cascade="save-update, merge, delete, delete-orphan",
    )

    @staticmethod
    def get_id(uuid_dataset):
        id_dataset = (
            DB.session.query(TDatasets.id_dataset)
            .filter(TDatasets.unique_dataset_id == uuid_dataset)
            .first()
        )
        if id_dataset:
            return id_dataset[0]
        return id_dataset

    @staticmethod
    def get_uuid(id_dataset):
        uuid_dataset = (
            DB.session.query(TDatasets.unique_dataset_id)
            .filter(TDatasets.id_dataset == id_dataset)
            .first()
        )
        if uuid_dataset:
            return uuid_dataset[0]
        return uuid_dataset

    @staticmethod
    def get_user_datasets(user, only_query=False, only_user=False):
        """get the dataset(s) where the user is actor (himself or with its organism - only himelsemf id only_use=True) or digitizer
            param: 
              - user from TRole model
              - only_query: boolean (return the query not the id_datasets allowed if true)
              - only_user: boolean: return only the dataset where user himself is actor (not with its organoism)

            return: a list of id_dataset or a query"""
        q = DB.session.query(TDatasets).outerjoin(
            CorDatasetActor, CorDatasetActor.id_dataset == TDatasets.id_dataset
        )
        if user.id_organisme is None or only_user:
            q = q.filter(
                or_(
                    CorDatasetActor.id_role == user.id_role,
                    TDatasets.id_digitizer == user.id_role,
                )
            )
        else:
            q = q.filter(
                or_(
                    CorDatasetActor.id_organism == user.id_organisme,
                    CorDatasetActor.id_role == user.id_role,
                    TDatasets.id_digitizer == user.id_role,
                )
            )
        if only_query:
            return q
        return list(set([d.id_dataset for d in q.all()]))


@serializable
class TAcquisitionFramework(CruvedHelper):
    __tablename__ = "t_acquisition_frameworks"
    __table_args__ = {"schema": "gn_meta"}
    id_acquisition_framework = DB.Column(DB.Integer, primary_key=True)
    unique_acquisition_framework_id = DB.Column(
        UUID(as_uuid=True), default=select([func.uuid_generate_v4()])
    )
    acquisition_framework_name = DB.Column(DB.Unicode)
    acquisition_framework_desc = DB.Column(DB.Unicode)
    id_nomenclature_territorial_level = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("NIVEAU_TERRITORIAL"),
    )
    territory_desc = DB.Column(DB.Unicode)
    keywords = DB.Column(DB.Unicode)
    id_nomenclature_financing_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=TNomenclatures.get_default_nomenclature("TYPE_FINANCEMENT"),
    )
    target_description = DB.Column(DB.Unicode)
    ecologic_or_geologic_target = DB.Column(DB.Unicode)
    acquisition_framework_parent_id = DB.Column(DB.Integer)
    is_parent = DB.Column(DB.Boolean)
    id_digitizer = DB.Column(DB.Integer, ForeignKey("utilisateurs.t_roles.id_role"))

    acquisition_framework_start_date = DB.Column(DB.DateTime)
    acquisition_framework_end_date = DB.Column(DB.DateTime)

    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)

    creator = DB.relationship("User", lazy="select")
    cor_af_actor = relationship(
        CorAcquisitionFrameworkActor,
        lazy="select",
        cascade="save-update, merge, delete, delete-orphan",
    )

    cor_objectifs = DB.relationship(
        TNomenclatures,
        secondary=CorAcquisitionFrameworkObjectif.__table__,
        primaryjoin=(
            CorAcquisitionFrameworkObjectif.id_acquisition_framework == id_acquisition_framework
        ),
        secondaryjoin=(
            CorAcquisitionFrameworkObjectif.id_nomenclature_objectif
            == TNomenclatures.id_nomenclature
        ),
        foreign_keys=[
            CorAcquisitionFrameworkObjectif.id_acquisition_framework,
            CorAcquisitionFrameworkObjectif.id_nomenclature_objectif,
        ],
        lazy="select",
    )

    cor_volets_sinp = DB.relationship(
        TNomenclatures,
        secondary=CorAcquisitionFrameworkVoletSINP.__table__,
        primaryjoin=(
            CorAcquisitionFrameworkVoletSINP.id_acquisition_framework == id_acquisition_framework
        ),
        secondaryjoin=(
            CorAcquisitionFrameworkVoletSINP.id_nomenclature_voletsinp
            == TNomenclatures.id_nomenclature
        ),
        foreign_keys=[
            CorAcquisitionFrameworkVoletSINP.id_acquisition_framework,
            CorAcquisitionFrameworkVoletSINP.id_nomenclature_voletsinp,
        ],
        lazy="select",
    )

    @staticmethod
    def get_id(uuid_af):
        """
            return the acquisition framework's id
            from its UUID if exist or None
        """
        a_f = (
            DB.session.query(TAcquisitionFramework.id_acquisition_framework)
            .filter(TAcquisitionFramework.unique_acquisition_framework_id == uuid_af)
            .first()
        )
        if a_f:
            return a_f[0]
        return a_f

    @staticmethod
    def get_user_af(user, only_query=False, only_user=False):
        """get the af(s) where the user is actor (himself or with its organism - only himelsemf id only_use=True) or digitizer
            param: 
              - user from TRole model
              - only_query: boolean (return the query not the id_datasets allowed if true)
              - only_user: boolean: return only the dataset where user himself is actor (not with its organoism)

            return: a list of id_dataset or a query"""
        q = DB.session.query(TAcquisitionFramework).outerjoin(
            CorAcquisitionFrameworkActor,
            CorAcquisitionFrameworkActor.id_acquisition_framework
            == TAcquisitionFramework.id_acquisition_framework,
        )
        if user.id_organisme is None or only_user:
            q = q.filter(
                or_(
                    CorAcquisitionFrameworkActor.id_role == user.id_role,
                    TAcquisitionFramework.id_digitizer == user.id_role,
                )
            )
        else:
            q = q.filter(
                or_(
                    CorAcquisitionFrameworkActor.id_organism == user.id_organisme,
                    CorAcquisitionFrameworkActor.id_role == user.id_role,
                    TAcquisitionFramework.id_digitizer == user.id_role,
                )
            )
        if only_query:
            return q
        return list(set([d.id_acquisition_framework for d in q.all()]))


@serializable
class TDatasetDetails(TDatasets):
    """
    Class which extends TDatasets with nomenclatures relationships
    """

    data_type = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature == TDatasets.id_nomenclature_data_type),
    )
    dataset_objectif = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature == TDatasets.id_nomenclature_dataset_objectif),
    )
    collecting_method = DB.relationship(
        TNomenclatures,
        primaryjoin=(
            TNomenclatures.id_nomenclature == TDatasets.id_nomenclature_collecting_method
        ),
    )
    data_origin = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature == TDatasets.id_nomenclature_data_origin),
    )
    source_status = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature == TDatasets.id_nomenclature_source_status),
    )
    resource_type = DB.relationship(
        TNomenclatures,
        primaryjoin=(TNomenclatures.id_nomenclature == TDatasets.id_nomenclature_resource_type),
    )
    acquisition_framework = DB.relationship(
        TAcquisitionFramework,
        primaryjoin=(
            TAcquisitionFramework.id_acquisition_framework == TDatasets.id_acquisition_framework
        ),
    )


@serializable
class TAcquisitionFrameworkDetails(TAcquisitionFramework):
    """
    Class which extends TAcquisitionFramework with nomenclatures relationships
    """

    datasets = DB.relationship(TDatasetDetails, lazy="joined")
    nomenclature_territorial_level = DB.relationship(
        TNomenclatures,
        primaryjoin=(
            TNomenclatures.id_nomenclature
            == TAcquisitionFramework.id_nomenclature_territorial_level
        ),
    )

    nomenclature_financing_type = DB.relationship(
        TNomenclatures,
        primaryjoin=(
            TNomenclatures.id_nomenclature == TAcquisitionFramework.id_nomenclature_financing_type
        ),
    )
