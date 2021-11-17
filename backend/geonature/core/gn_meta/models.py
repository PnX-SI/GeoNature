from flask import g
from flask_sqlalchemy import BaseQuery
from geonature.utils.errors import GeonatureApiError
from sqlalchemy import ForeignKey, or_
from sqlalchemy.sql import select, func
from sqlalchemy.orm import relationship, exc
from sqlalchemy.dialects.postgresql import UUID
from utils_flask_sqla.generic import testDataType
from werkzeug.exceptions import BadRequest, NotFound

from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import User, Organisme
from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB
from geonature.core.gn_commons.models import cor_field_dataset, cor_module_dataset


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
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )

    nomenclature_objectif = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_objectif),
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

    nomenclature_voletsinp = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_voletsinp),
    )

class CorAcquisitionFrameworkTerritory(DB.Model):
    __tablename__ = "cor_acquisition_framework_territory"
    __table_args__ = {"schema": "gn_meta"}
    id_acquisition_framework = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
        primary_key=True,
    )
    id_nomenclature_territory = DB.Column(
        "id_nomenclature_territory",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )

    nomenclature_territory = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_territory),
    )


@serializable
class CorAcquisitionFrameworkActor(DB.Model):
    __tablename__ = "cor_acquisition_framework_actor"
    __table_args__ = {"schema": "gn_meta"}
    id_cafa = DB.Column(DB.Integer, primary_key=True)
    id_acquisition_framework = DB.Column(
        DB.Integer, ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role))
    id_organism = DB.Column(DB.Integer, ForeignKey(Organisme.id_organisme))
    id_nomenclature_actor_role = DB.Column(
        DB.Integer,
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
        primaryjoin=(User.id_role == id_role),
        foreign_keys=[id_role]
    )

    organism = relationship(
        Organisme,
        lazy="joined",
        foreign_keys=[id_organism]
    )

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
    id_role = DB.Column(DB.Integer, ForeignKey(User.id_role))
    id_organism = DB.Column(DB.Integer, ForeignKey(Organisme.id_organisme))

    id_nomenclature_actor_role = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("ROLE_ACTEUR"),
    )

    role = DB.relationship(User, lazy="joined")
    organism = relationship(Organisme, lazy="joined")

    nomenclature_actor_role = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_actor_role),
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
    id_dataset = DB.Column(
        DB.Integer,
        ForeignKey("gn_meta.t_datasets.id_dataset"),
        primary_key=True,
    )
    id_nomenclature_territory = DB.Column(
        "id_nomenclature_territory",
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        primary_key=True,
    )

    nomenclature_territory = DB.relationship(
        TNomenclatures,
        lazy="joined",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_territory),
    )


class CruvedHelper(DB.Model):
    """
    Classe abstraite permettant d'ajouter des méthodes de
    contrôle d'accès à la donnée des class TDatasets et TAcquisitionFramework
    """

    __abstract__ = True

    def user_is_allowed_to(
        self,
        object_actors: list,
        info_role: list,
        level: str,
    ):
        """
            Fonction permettant de dire si un utilisateur
            peu ou non agir sur une donnée

            Params:
                id_role: identifiant de la personne qui demande la route
                id_object_users_actor (list): identifiant des objects ou l'utilisateur est lui même acteur
                id_object_organism_actor (list): identifiants des objects ou l'utilisateur ou son organisme sont acteurs

            Return: boolean
        """
        # Si l'utilisateur n'a pas de droit d'accès aux données
        if level not in ("1", "2", "3"):
            return False

        # Si l'utilisateur à le droit d'accéder à toutes les données
        if level == "3":
            return True

        # Si l'utilisateur est createur de la données
        if self.id_digitizer == info_role.id_role:
            return True

        for actor in object_actors :
            # Si l'utilisateur est indiqué comme role dans la données
            if actor.id_role == info_role.id_role :
                return True
            # Si l'utilisateur appartient à un organisme
            # qui a un droit sur la données et
            # que son niveau d'accès est 2 ou 3
            if actor.id_organism == info_role.id_organisme and level == "2":
                return True

        return False



@serializable
class TBibliographicReference(CruvedHelper):
    __tablename__ = "t_bibliographical_references"
    __table_args__ = {"schema": "gn_meta"}
    id_bibliographic_reference = DB.Column(DB.Integer, primary_key=True)
    id_acquisition_framework = DB.Column(
        DB.Integer, ForeignKey("gn_meta.t_acquisition_frameworks.id_acquisition_framework"),
    )
    publication_url = DB.Column(DB.Unicode)
    publication_reference = DB.Column(DB.Unicode)



class TDatasetsQuery(BaseQuery):

    def _filter_by_scope(self, scope):
        if scope in (1, 2):
            ors = [
                "id_digitizer" == g.user.id_role,
                TDatasets.cor_dataset_actor.any(id_role=g.user.id_role)
            ]
            # if organism is None => do not filter on id_organism even if level = 2
            if g.user.value_filter == 2 and g.user.id_organisme is not None:
                ors.append(CorDatasetActor.id_organism == g.user.id_organisme)
            self = self.filter(or_(*ors))
        return self
    
    def _filter_other_params(self, params={}):
        if "active" in params:
            self = self.filter(TDatasets.active == bool(params["active"]))
            params.pop("active")
        if "id_acquisition_framework" in params:
            if type(params["id_acquisition_framework"]) is list:
                self = self.filter(
                    TDatasets.id_acquisition_framework.in_(
                        [int(id_af) for id_af in params["id_acquisition_framework"]]
                    )
                )
            else:
                self = self.filter(
                    TDatasets.id_acquisition_framework == int(params["id_acquisition_framework"])
                )
            table_columns = TDatasets.__table__.columns
            # Generic Filters
            for param in params:
                if param in table_columns:
                    col = getattr(table_columns, param)
                    testT = testDataType(params[param], col.type, param)
                    if testT:
                        raise GeonatureApiError(message=testT)
                    q = q.filter(col == params[param])
            if "orderby" in params:
                try:
                    orderCol = getattr(TDatasets.__table__.columns, params["orderby"])
                    q = q.order_by(orderCol)
                except AttributeError:
                    raise BadRequest("the attribute to order on does not exist")

    def read_allowed(self, scope, params={}):
        """
            Return the datasets where the user has autorization via its CRUVED
        """
        self = self._filter_other_params(params)
        return self._filter_by_scope(scope).all()

    def create_allowed(self, module_code, read_scope, create_scope, params={}):
        """
        Return all dataset where user have read rights minus those who user to not have
        create rigth
        """
        self = self._filter_other_params(params)
        self = self._filter_by_scope(read_scope)
        self = self.filter(TDatasets.modules.any(module_code=module_code))
        if create_scope < read_scope:
            self = self._filter_by_scope(create_scope)
        print(self)
        return self.all()
    

@serializable
class TDatasets(CruvedHelper):
    __tablename__ = "t_datasets"
    __table_args__ = {"schema": "gn_meta"}
    query_class = TDatasetsQuery
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
        default=lambda: TNomenclatures.get_default_nomenclature("DATA_TYP"),
    )
    keywords = DB.Column(DB.Unicode)
    marine_domain = DB.Column(DB.Boolean)
    terrestrial_domain = DB.Column(DB.Boolean)
    id_nomenclature_dataset_objectif = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("JDD_OBJECTIFS"),
    )
    bbox_west = DB.Column(DB.Float)
    bbox_east = DB.Column(DB.Float)
    bbox_south = DB.Column(DB.Float)
    bbox_north = DB.Column(DB.Float)
    id_nomenclature_collecting_method = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("METHO_RECUEIL"),
    )
    id_nomenclature_data_origin = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("DS_PUBLIQUE"),
    )
    id_nomenclature_source_status = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("STATUT_SOURCE"),
    )
    id_nomenclature_resource_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("RESOURCE_TYP"),
    )
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    active = DB.Column(DB.Boolean, default=True)
    validable = DB.Column(DB.Boolean)
    id_digitizer = DB.Column(DB.Integer, ForeignKey(User.id_role))
    id_taxa_list = DB.Column(DB.Integer)
    modules = DB.relationship("TModules", secondary=cor_module_dataset, lazy="select")

    creator = DB.relationship(User, lazy="joined")  # = digitizer
    nomenclature_data_type = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_data_type),
    )
    nomenclature_dataset_objectif = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_dataset_objectif),
    )
    nomenclature_collecting_method = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(
            TNomenclatures.id_nomenclature == id_nomenclature_collecting_method
        ),
    )
    nomenclature_data_origin = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_data_origin),
    )
    nomenclature_source_status = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_source_status),
    )
    nomenclature_resource_type = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_resource_type),
    )

    cor_territories = DB.relationship(
        TNomenclatures,
        lazy="select",
        secondary=CorDatasetTerritory.__table__,
        primaryjoin=(CorDatasetTerritory.id_dataset == id_dataset),
        secondaryjoin=(CorDatasetTerritory.id_nomenclature_territory == TNomenclatures.id_nomenclature),
        foreign_keys=[
            CorDatasetTerritory.id_dataset,
            CorDatasetTerritory.id_nomenclature_territory,
        ],
        backref=DB.backref("territory_dataset", lazy="select")
    )

    # because CorDatasetActor could be an User or an Organisme object...
    cor_dataset_actor = relationship(
        CorDatasetActor,
        lazy="joined",
        cascade="save-update, merge, delete, delete-orphan",
        backref=DB.backref("actor_dataset", lazy="select")
    )

    def __str__(self):
        return self.dataset_name
        
    def get_object_cruved(
        self, info_role, user_cruved
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
            action: self.user_is_allowed_to(self.cor_dataset_actor, info_role, level)
            for action, level in user_cruved.items()
        }

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
              - only_user: boolean: return only the dataset where user himself is actor (not with its organism)

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
        default=lambda: TNomenclatures.get_default_nomenclature("NIVEAU_TERRITORIAL"),
    )
    territory_desc = DB.Column(DB.Unicode)
    keywords = DB.Column(DB.Unicode)
    id_nomenclature_financing_type = DB.Column(
        DB.Integer,
        ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
        default=lambda: TNomenclatures.get_default_nomenclature("TYPE_FINANCEMENT"),
    )
    target_description = DB.Column(DB.Unicode)
    ecologic_or_geologic_target = DB.Column(DB.Unicode)
    acquisition_framework_parent_id = DB.Column(DB.Integer)
    is_parent = DB.Column(DB.Boolean)
    opened = DB.Column(DB.Boolean, default=True)
    id_digitizer = DB.Column(DB.Integer, ForeignKey(User.id_role))

    acquisition_framework_start_date = DB.Column(DB.Date)
    acquisition_framework_end_date = DB.Column(DB.Date)

    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    initial_closing_date = DB.Column(DB.DateTime)

    creator = DB.relationship(User, lazy="joined")  # = digitizer
    nomenclature_territorial_level = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_territorial_level),
    )
    nomenclature_financing_type = DB.relationship(
        TNomenclatures,
        lazy="select",
        primaryjoin=(TNomenclatures.id_nomenclature == id_nomenclature_financing_type),
    )
    cor_af_actor = relationship(
        CorAcquisitionFrameworkActor,
        lazy="joined",
        #cascade="save-update, merge, delete, delete-orphan",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("actor_af", lazy="select")
    )

    cor_objectifs = DB.relationship(
        TNomenclatures,
        lazy="select",
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
        backref=DB.backref("objectif_af", lazy="select")
    )

    cor_volets_sinp = DB.relationship(
        TNomenclatures,
        lazy="select",
        secondary=CorAcquisitionFrameworkVoletSINP.__table__,
        primaryjoin=(CorAcquisitionFrameworkVoletSINP.id_acquisition_framework == id_acquisition_framework),
        secondaryjoin=(CorAcquisitionFrameworkVoletSINP.id_nomenclature_voletsinp == TNomenclatures.id_nomenclature),
        foreign_keys=[
            CorAcquisitionFrameworkVoletSINP.id_acquisition_framework,
            CorAcquisitionFrameworkVoletSINP.id_nomenclature_voletsinp,
        ],
        backref=DB.backref("volet_sinp_af", lazy="select")
    )

    cor_territories = DB.relationship(
        TNomenclatures,
        lazy="select",
        secondary=CorAcquisitionFrameworkTerritory.__table__,
        primaryjoin=(CorAcquisitionFrameworkTerritory.id_acquisition_framework == id_acquisition_framework),
        secondaryjoin=(CorAcquisitionFrameworkTerritory.id_nomenclature_territory == TNomenclatures.id_nomenclature),
        foreign_keys=[
            CorAcquisitionFrameworkTerritory.id_acquisition_framework,
            CorAcquisitionFrameworkTerritory.id_nomenclature_territory,
        ],
        backref=DB.backref("territory_af", lazy="select")
    )

    bibliographical_references = DB.relationship(
        "TBibliographicReference",
        lazy="select",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("acquisition_framework", lazy="select"),
    )

    t_datasets = DB.relationship(
        "TDatasets",
        lazy="select",
        cascade="all,delete-orphan",
        uselist=True,
        backref=DB.backref("acquisition_framework", lazy="select"),
    )

    def get_object_cruved(
        self, info_role, user_cruved
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
            action: self.user_is_allowed_to(self.cor_af_actor, info_role, level)
            for action, level in user_cruved.items()
        }

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
        q = DB.session.query(TAcquisitionFramework.id_acquisition_framework).outerjoin(
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
        data = q.all()
        return list(set([d.id_acquisition_framework for d in data]))

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
    # acquisition_framework = DB.relationship(
    #     TAcquisitionFramework,
    #     primaryjoin=(
    #         TAcquisitionFramework.id_acquisition_framework == TDatasets.id_acquisition_framework
    #     ),
    # )
    additional_fields = DB.relationship(
        "TAdditionalFields",
        secondary=cor_field_dataset
    )

        
 


@serializable
class TAcquisitionFrameworkDetails(TAcquisitionFramework):
    """
    Class which extends TAcquisitionFramework with nomenclatures relationships
    """

    #datasets = DB.relationship(TDatasetDetails, lazy="joined")
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
