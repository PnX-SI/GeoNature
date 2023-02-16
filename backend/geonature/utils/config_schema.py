"""
    Description des options de configuration
"""

import os

from pkg_resources import iter_entry_points, load_entry_point

from marshmallow import (
    Schema,
    fields,
    validates_schema,
    ValidationError,
    post_load,
)
from marshmallow.validate import OneOf, Regexp, Email, Length

from geonature.core.gn_synthese.synthese_config import (
    DEFAULT_EXPORT_COLUMNS,
    DEFAULT_LIST_COLUMN,
    DEFAULT_COLUMNS_API_SYNTHESE,
)
from geonature.utils.env import GEONATURE_VERSION, BACKEND_DIR, ROOT_DIR
from geonature.utils.module import get_module_config
from geonature.utils.utilsmails import clean_recipients
from geonature.utils.utilstoml import load_and_validate_toml


class EmailStrOrListOfEmailStrField(fields.Field):
    def _deserialize(self, value, attr, data, **kwargs):
        if isinstance(value, str):
            self._check_email(value)
            return value
        elif isinstance(value, list) and all(isinstance(x, str) for x in value):
            self._check_email(value)
            return value
        else:
            raise ValidationError("Field should be str or list of str")

    def _check_email(self, value):
        recipients = clean_recipients(value)
        for recipient in recipients:
            email = recipient[1] if isinstance(recipient, tuple) else recipient
            # Validate email with Marshmallow
            validator = Email()
            validator(email)


class CasUserSchemaConf(Schema):
    URL = fields.Url(load_default="https://inpn.mnhn.fr/authentication/information")
    BASE_URL = fields.Url(load_default="https://inpn.mnhn.fr/authentication/")
    ID = fields.String(load_default="mon_id")
    PASSWORD = fields.String(load_default="mon_pass")


class CasFrontend(Schema):
    CAS_AUTHENTIFICATION = fields.Boolean(load_default=False)
    CAS_URL_LOGIN = fields.Url(load_default="https://preprod-inpn.mnhn.fr/auth/login")
    CAS_URL_LOGOUT = fields.Url(load_default="https://preprod-inpn.mnhn.fr/auth/logout")


class CasSchemaConf(Schema):
    CAS_URL_VALIDATION = fields.String(
        load_default="https://preprod-inpn.mnhn.fr/auth/serviceValidate"
    )
    CAS_USER_WS = fields.Nested(CasUserSchemaConf, load_default=CasUserSchemaConf().load({}))
    USERS_CAN_SEE_ORGANISM_DATA = fields.Boolean(load_default=False)
    # Quel modules seront associés au JDD récupérés depuis MTD


class MTDSchemaConf(Schema):
    JDD_MODULE_CODE_ASSOCIATION = fields.List(fields.String, load_default=["OCCTAX", "OCCHAB"])
    ID_INSTANCE_FILTER = fields.Integer(load_default=None)


class BddConfig(Schema):
    ID_USER_SOCLE_1 = fields.Integer(load_default=8)
    ID_USER_SOCLE_2 = fields.Integer(load_default=6)


class RightsSchemaConf(Schema):
    NOTHING = fields.Integer(load_default=0)
    MY_DATA = fields.Integer(load_default=1)
    MY_ORGANISM_DATA = fields.Integer(load_default=2)
    ALL_DATA = fields.Integer(load_default=3)


class MailConfig(Schema):
    MAIL_SERVER = fields.String(required=False)
    MAIL_PORT = fields.Integer(required=False)
    MAIL_USE_TLS = fields.Boolean(required=False)
    MAIL_USE_SSL = fields.Boolean(required=False)
    MAIL_USERNAME = fields.String(required=False)
    MAIL_PASSWORD = fields.String(required=False)
    MAIL_DEFAULT_SENDER = fields.String(required=False)
    MAIL_MAX_EMAILS = fields.Integer(required=False)
    MAIL_SUPPRESS_SEND = fields.Boolean(required=False)
    MAIL_ASCII_ATTACHMENTS = fields.Boolean(required=False)
    ERROR_MAIL_TO = EmailStrOrListOfEmailStrField(load_default=None)


class CeleryConfig(Schema):
    broker_url = fields.String(load_default="redis://localhost:6379/0")
    result_backend = fields.String(load_default="redis://localhost:6379/0")


class AccountManagement(Schema):
    # Config for sign-up
    ENABLE_SIGN_UP = fields.Boolean(load_default=False)
    ENABLE_USER_MANAGEMENT = fields.Boolean(load_default=False)
    AUTO_ACCOUNT_CREATION = fields.Boolean(load_default=True)
    AUTO_DATASET_CREATION = fields.Boolean(load_default=True)
    VALIDATOR_EMAIL = EmailStrOrListOfEmailStrField(load_default=None)
    ACCOUNT_FORM = fields.List(fields.Dict(), load_default=[])
    ADDON_USER_EMAIL = fields.String(load_default="")
    DATASET_MODULES_ASSOCIATION = fields.List(fields.String(), load_default=["OCCTAX"])


class UsersHubConfig(Schema):
    ADMIN_APPLICATION_LOGIN = fields.String()
    ADMIN_APPLICATION_PASSWORD = fields.String()
    URL_USERSHUB = fields.Url()


class ServerConfig(Schema):
    LOG_LEVEL = fields.Integer(load_default=20)


class MediasConfig(Schema):
    MEDIAS_SIZE_MAX = fields.Integer(load_default=50000)
    THUMBNAIL_SIZES = fields.List(fields.Integer, load_default=[200, 50])


class AlembicConfig(Schema):
    VERSION_LOCATIONS = fields.String()


class AdditionalFields(Schema):
    IMPLEMENTED_MODULES = fields.List(fields.String(), load_default=["OCCTAX"])
    IMPLEMENTED_OBJECTS = fields.List(
        fields.String(), load_default=["OCCTAX_RELEVE", "OCCTAX_OCCURENCE", "OCCTAX_DENOMBREMENT"]
    )


class HomeConfig(Schema):
    TITLE = fields.String(load_default="Bienvenue dans GeoNature")
    INTRODUCTION = fields.String(load_default="")
    FOOTER = fields.String(load_default="")


class MetadataConfig(Schema):
    NB_AF_DISPLAYED = fields.Integer(load_default=50, validate=OneOf([10, 25, 50, 100]))
    ENABLE_CLOSE_AF = fields.Boolean(load_default=False)
    AF_SHEET_CLOSED_LINK_NAME = fields.String(load_default="Lien du certificat de dépôt")
    CLOSED_AF_TITLE = fields.String(load_default="")
    AF_PDF_TITLE = fields.String(load_default="Cadre d'acquisition: ")
    DS_PDF_TITLE = fields.String(load_default="")
    MAIL_SUBJECT_AF_CLOSED_BASE = fields.String(load_default="")
    MAIL_CONTENT_AF_CLOSED_ADDITION = fields.String(load_default="")
    MAIL_CONTENT_AF_CLOSED_PDF = fields.String(load_default="")
    MAIL_CONTENT_AF_CLOSED_URL = fields.String(load_default="")
    MAIL_CONTENT_AF_CLOSED_GREETINGS = fields.String(load_default="")
    CLOSED_MODAL_LABEL = fields.String(load_default="Fermer un cadre d'acquisition")
    CLOSED_MODAL_CONTENT = fields.String(
        load_default="""L'action de fermeture est irréversible. Il ne sera
    plus possible d'ajouter des jeux de données au cadre d'acquisition par la suite."""
    )
    CD_NOMENCLATURE_ROLE_TYPE_DS = fields.List(fields.Str(), load_default=[])
    CD_NOMENCLATURE_ROLE_TYPE_AF = fields.List(fields.Str(), load_default=[])
    METADATA_AREA_FILTERS = fields.List(
        fields.Dict,
        load_default=[
            {"label": "Communes", "type_code": "COM"},
            {"label": "Départements", "type_code": "DEP"},
            {"label": "Régions", "type_code": "REG"},
        ],
    )


# class a utiliser pour les paramètres que l'on ne veut pas passer au frontend


class GnPySchemaConf(Schema):
    SQLALCHEMY_DATABASE_URI = fields.String(
        required=True,
        validate=Regexp(
            "^postgresql:\/\/.*:.*@[^:]+:\w+\/\w+",
            error="Database uri is invalid ex: postgresql://monuser:monpass@server:port/db_name",
        ),
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = fields.Boolean(load_default=True)
    SESSION_TYPE = fields.String(load_default="filesystem")
    SECRET_KEY = fields.String(required=True, validate=Length(min=20))
    # le cookie expire toute les 7 jours par défaut
    COOKIE_EXPIRATION = fields.Integer(load_default=3600 * 24 * 7)
    COOKIE_AUTORENEW = fields.Boolean(load_default=True)
    TRAP_ALL_EXCEPTIONS = fields.Boolean(load_default=False)
    SENTRY_DSN = fields.String()
    ROOT_PATH = fields.String(load_default=BACKEND_DIR)
    STATIC_FOLDER = fields.String(load_default="static")
    CUSTOM_STATIC_FOLDER = fields.String(load_default=ROOT_DIR / "custom")
    MEDIA_FOLDER = fields.String(load_default="media")
    CAS = fields.Nested(CasSchemaConf, load_default=CasSchemaConf().load({}))
    MAIL_ON_ERROR = fields.Boolean(load_default=False)
    MAIL_CONFIG = fields.Nested(MailConfig, load_default=MailConfig().load({}))
    CELERY = fields.Nested(CeleryConfig, load_default=CeleryConfig().load({}))
    METADATA = fields.Nested(MetadataConfig, load_default=MetadataConfig().load({}))
    ADMIN_APPLICATION_LOGIN = fields.String()
    ACCOUNT_MANAGEMENT = fields.Nested(
        AccountManagement, load_default=AccountManagement().load({})
    )
    BAD_LOGIN_STATUS_CODE = fields.Integer(load_default=401)
    USERSHUB = fields.Nested(UsersHubConfig, load_default=UsersHubConfig().load({}))
    SERVER = fields.Nested(ServerConfig, load_default=ServerConfig().load({}))
    MEDIAS = fields.Nested(MediasConfig, load_default=MediasConfig().load({}))
    ALEMBIC = fields.Nested(AlembicConfig, load_default=AlembicConfig().load({}))

    @post_load()
    def folders(self, data, **kwargs):
        data["STATIC_FOLDER"] = os.path.join(data["ROOT_PATH"], data["STATIC_FOLDER"])
        if "CUSTOM_STATIC_FOLDER" in data:
            data["CUSTOM_STATIC_FOLDER"] = os.path.join(
                data["ROOT_PATH"], data["CUSTOM_STATIC_FOLDER"]
            )
        data["MEDIA_FOLDER"] = os.path.join(data["ROOT_PATH"], data["MEDIA_FOLDER"])
        return data

    @post_load()
    def unwrap_usershub(self, data, **kwargs):
        """
        On met la section [USERSHUB] à la racine de la conf
        pour compatibilité et simplicité ave le sous-module d'authentif
        """
        for key, value in data["USERSHUB"].items():
            data[key] = value
        data.pop("USERSHUB")
        return data

    @validates_schema
    def validate_enable_usershub_and_mail(self, data, **kwargs):
        # si account management = true, URL_USERSHUB et MAIL_CONFIG sont necessaire
        if data["ACCOUNT_MANAGEMENT"].get("ENABLE_SIGN_UP", False) or data[
            "ACCOUNT_MANAGEMENT"
        ].get("ENABLE_USER_MANAGEMENT", False):
            if (
                data["USERSHUB"].get("URL_USERSHUB", None) is None
                or data["USERSHUB"].get("ADMIN_APPLICATION_LOGIN", None) is None
                or data["USERSHUB"].get("ADMIN_APPLICATION_PASSWORD", None) is None
            ):
                raise ValidationError(
                    (
                        "URL_USERSHUB, ADMIN_APPLICATION_LOGIN et ADMIN_APPLICATION_PASSWORD sont necessaires si ENABLE_SIGN_UP=True "
                        "ou si ENABLE_USER_MANAGEMENT=True"
                    ),
                    "URL_USERSHUB",
                )
            if data["MAIL_CONFIG"].get("MAIL_SERVER", None) is None:
                raise ValidationError(
                    "Veuillez remplir la rubrique MAIL_CONFIG si ENABLE_SIGN_UP=True",
                    "ENABLE_SIGN_UP",
                )


class GnFrontEndConf(Schema):
    PROD_MOD = fields.Boolean(load_default=True)
    DISPLAY_FOOTER = fields.Boolean(load_default=True)
    DISPLAY_STAT_BLOC = fields.Boolean(load_default=True)
    STAT_BLOC_TTL = fields.Integer(load_default=3600)
    DISPLAY_MAP_LAST_OBS = fields.Boolean(load_default=True)
    MULTILINGUAL = fields.Boolean(load_default=False)
    ENABLE_PROFILES = fields.Boolean(load_default=True)

    # show email on synthese and validation info obs modal
    DISPLAY_EMAIL_INFO_OBS = fields.Boolean(load_default=True)
    DISPLAY_EMAIL_DISPLAY_INFO = fields.List(fields.String(), load_default=["NOM_VERN"])


class Synthese(Schema):
    # --------------------------------------------------------------------
    # SYNTHESE - SEARCH FORM
    AREA_FILTERS = fields.List(
        fields.Dict, load_default=[{"label": "Communes", "type_code": "COM"}]
    )
    # Nombre de résultat à afficher pour la rechercher autocompleté de taxon
    TAXON_RESULT_NUMBER = fields.Integer(load_default=20)
    # Afficher ou non l'arbre taxonomique
    DISPLAY_TAXON_TREE = fields.Boolean(load_default=True)
    # Switch the observer form input in free text input (true) or in select input (false)
    SEARCH_OBSERVER_WITH_LIST = fields.Boolean(load_default=False)
    # Id of the observer list -- utilisateurs.t_menus
    ID_SEARCH_OBSERVER_LIST = fields.Integer(load_default=1)
    # Regulatory or not status list of fields
    STATUS_FILTERS = fields.List(
        fields.Dict,
        load_default=[
            {
                "id": "protections",
                "show": True,
                "display_name": "Taxons protégés",
                "status_types": ["PN", "PR", "PD"],
            },
            {
                "id": "regulations",
                "show": True,
                "display_name": "Taxons réglementés",
                "status_types": ["REGLII", "REGLLUTTE", "REGL", "REGLSO"],
            },
            {
                "id": "znief",
                "show": True,
                "display_name": "Espèces déterminantes ZNIEFF",
                "status_types": ["ZDET"],
            },
        ],
    )
    # Red lists list of fields
    RED_LISTS_FILTERS = fields.List(
        fields.Dict,
        load_default=[
            {
                "id": "worldwide",
                "show": True,
                "display_name": "Liste rouge mondiale",
                "status_type": "LRM",
            },
            {
                "id": "european",
                "show": True,
                "display_name": "Liste rouge européenne",
                "status_type": "LRE",
            },
            {
                "id": "national",
                "show": True,
                "display_name": "Liste rouge nationale",
                "status_type": "LRN",
            },
            {
                "id": "regional",
                "show": True,
                "display_name": "Liste rouge régionale",
                "status_type": "LRR",
            },
        ],
    )

    # Filtres par défaut pour la synthese
    DEFAULT_FILTERS = fields.Dict(load_default={})

    # --------------------------------------------------------------------
    # SYNTHESE - OBSERVATIONS LIST
    # Listes des champs renvoyés par l'API synthese '/synthese'
    # Si on veut afficher des champs personnalisés dans le frontend (paramètre LIST_COLUMNS_FRONTEND) il faut
    # d'abbord s'assurer que ces champs sont bien renvoyé par l'API !
    # Champs disponibles: tous ceux de la vue 'v_synthese_for_web_app
    COLUMNS_API_SYNTHESE_WEB_APP = fields.List(
        fields.String, load_default=DEFAULT_COLUMNS_API_SYNTHESE
    )
    # Colonnes affichées sur la liste des résultats de la sytnthese
    LIST_COLUMNS_FRONTEND = fields.List(fields.Dict, load_default=DEFAULT_LIST_COLUMN)

    # --------------------------------------------------------------------
    # SYNTHESE - DOWNLOADS (AKA EXPORTS)
    EXPORT_COLUMNS = fields.List(fields.String(), load_default=DEFAULT_EXPORT_COLUMNS)
    # Certaines colonnes sont obligatoires pour effectuer les filtres CRUVED
    EXPORT_ID_SYNTHESE_COL = fields.String(load_default="id_synthese")
    EXPORT_ID_DATASET_COL = fields.String(load_default="jdd_id")
    EXPORT_ID_DIGITISER_COL = fields.String(load_default="id_digitiser")
    EXPORT_OBSERVERS_COL = fields.String(load_default="observateurs")
    EXPORT_GEOJSON_4326_COL = fields.String(load_default="geojson_4326")
    EXPORT_GEOJSON_LOCAL_COL = fields.String(load_default="geojson_local")
    EXPORT_METADATA_ID_DATASET_COL = fields.String(load_default="jdd_id")
    EXPORT_METADATA_ACTOR_COL = fields.String(load_default="acteurs")
    # Formats d'export disponibles ["csv", "geojson", "shapefile", "gpkg"]
    EXPORT_FORMAT = fields.List(fields.String(), load_default=["csv", "geojson", "shapefile"])
    # Nombre max d'observation dans les exports
    NB_MAX_OBS_EXPORT = fields.Integer(load_default=50000)

    # --------------------------------------------------------------------
    # SYNTHESE - OBSERVATION DETAILS
    # Liste des id attributs Taxhub à afficher sur la fiche détaile de la synthese
    # et sur les filtres taxonomiques avancés
    ID_ATTRIBUT_TAXHUB = fields.List(fields.Integer(), load_default=[102, 103])
    # Display email on synthese and validation info obs modal
    DISPLAY_EMAIL = fields.Boolean(load_default=True)

    # --------------------------------------------------------------------
    # SYNTHESE - SHARED PARAMETERS
    # Nom des colonnes de la table gn_synthese.synthese que l'on veux retirer des filtres dynamiques
    # et de la modale d'information détaillée d'une observation example = "[non_digital_proof]"
    EXCLUDED_COLUMNS = fields.List(fields.String(), load_default=[])

    # Nombre max d'observation à afficher sur la carte
    NB_MAX_OBS_MAP = fields.Integer(load_default=50000)
    # Clusteriser les layers sur la carte
    ENABLE_LEAFLET_CLUSTER = fields.Boolean(load_default=True)
    # Nombre des "dernières observations" affichées à l'arrivée sur la synthese
    NB_LAST_OBS = fields.Integer(load_default=100)

    # Display email on synthese and validation info obs modal
    DISPLAY_EMAIL = fields.Boolean(load_default=True)
    # Limit comment max length for the discussion tab
    DISCUSSION_MAX_LENGTH = fields.Integer(load_default=1500)
    # Allow disable discussion tab for synthese or validation
    DISCUSSION_MODULES = fields.List(fields.String(), load_default=["SYNTHESE", "VALIDATION"])
    # Allow disable alert synthese module for synthese or validation or any
    ALERT_MODULES = fields.List(fields.String(), load_default=["SYNTHESE", "VALIDATION"])
    # Allow to activate pin tool for any, some or all VALIDATION, SYNTHESE
    PIN_MODULES = fields.List(fields.String(), load_default=["SYNTHESE", "VALIDATION"])
    # Enable areas vizualisation with toggle slide
    AREA_AGGREGATION_ENABLED = fields.Boolean(load_default=True)
    # Choose size of areas
    AREA_AGGREGATION_TYPE = fields.String(load_default="M10")
    # Activate areas mode by default
    AREA_AGGREGATION_BY_DEFAULT = fields.Boolean(load_default=False)
    # Areas legend classes to use
    AREA_AGGREGATION_LEGEND_CLASSES = fields.List(
        fields.Dict(),
        load_default=[
            {"min": 100, "color": "#800026"},
            {"min": 50, "color": "#BD0026"},
            {"min": 20, "color": "#E31A1C"},
            {"min": 10, "color": "#FC4E2A"},
            {"min": 5, "color": "#FD8D3C"},
            {"min": 2, "color": "#FEB24C"},
            {"min": 1, "color": "#FED976"},
            {"min": 0, "color": "#FFEDA0"},
        ],
    )


# Map configuration
BASEMAP = [
    {
        "name": "OpenStreetMap",
        "url": "//{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
        "options": {
            "attribution": "<a href='https://www.openstreetmap.org/copyright' target='_blank'>© OpenStreetMap contributors</a>",
        },
    },
    {
        "name": "OpenTopoMap",
        "url": "//a.tile.opentopomap.org/{z}/{x}/{y}.png",
        "options": {
            "attribution": "Map data: © <a href='https://www.openstreetmap.org/copyright' target='_blank'>OpenStreetMap contributors</a>, SRTM | Map style: © <a href='https://opentopomap.org' target='_blank'>OpenTopoMap</a> (<a href='https://creativecommons.org/licenses/by-sa/3.0/' target='_blank'>CC-BY-SA</a>)",
        },
    },
    {
        "name": "GoogleSatellite",
        "layer": "//{s}.google.com/vt/lyrs=s&x={x}&y={y}&z={z}",
        "options": {
            "subdomains": ["mt0", "mt1", "mt2", "mt3"],
            "attribution": "© Google Maps",
        },
    },
]


class MapConfig(Schema):
    BASEMAP = fields.List(fields.Dict(), load_default=BASEMAP)
    CENTER = fields.List(fields.Float, load_default=[46.52863469527167, 2.43896484375])
    ZOOM_LEVEL = fields.Integer(load_default=6)
    ZOOM_LEVEL_RELEVE = fields.Integer(load_default=15)
    # zoom appliqué sur la carte lorsque l'on clique sur une liste
    # ne s'applique qu'aux points
    ZOOM_ON_CLICK = fields.Integer(load_default=18)
    # Restreindre la recherche OpenStreetMap (sur la carte dans l'encart "Rechercher un lieu")
    # à certains pays. Les pays doivent être au format ISO_3166-1 :
    # https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 et séparés par une virgule.
    # Exemple : OSM_RESTRICT_COUNTRY_CODES = "fr,es,be,ch" (Restreint à France, Espagne, Belgique
    # et Suisse)
    # Laisser à null pour n'avoir aucune restriction
    OSM_RESTRICT_COUNTRY_CODES = fields.String(load_default=None)
    REF_LAYERS = fields.List(
        fields.Dict(),
        load_default=[
            {
                "code": "limitesadministratives",
                "label": "Limites administratives (IGN)",
                "type": "wms",
                "url": "https://wxs.ign.fr/essentiels/geoportail/r/wms",
                "activate": False,
                "params": {
                    "VERSION": "1.3.0",
                    "crs": "CRS:84",
                    "dpiMode": 7,
                    "format": "image/png",
                    "layers": "LIMITES_ADMINISTRATIVES_EXPRESS.LATEST",
                    "styles": "",
                },
            },
            {
                "code": "znieff1",
                "label": "ZNIEFF1 (INPN)",
                "type": "wms",
                "url": "https://ws.carmencarto.fr/WMS/119/fxx_inpn",
                "activate": False,
                "params": {
                    "layers": "znieff1",
                    "opacity": 0.2,
                    "crs": "EPSG:4326",
                    "service": "wms",
                    "format": "image/png",
                    "version": "1.3.0",
                    "request": "GetMap",
                    "transparent": True,
                },
            },
        ],
    )
    REF_LAYERS_LEGEND = fields.Boolean(load_default=False)


class TaxHub(Schema):
    ID_TYPE_MAIN_PHOTO = fields.Integer(load_default=1)


# class a utiliser pour les paramètres que l'on veut passer au frontend
class GnGeneralSchemaConf(Schema):
    appName = fields.String(load_default="GeoNature2")
    LOGO_STRUCTURE_FILE = fields.String(load_default="logo_structure.png")
    GEONATURE_VERSION = fields.String(load_default=GEONATURE_VERSION.strip())
    DEFAULT_LANGUAGE = fields.String(load_default="fr")
    PASS_METHOD = fields.String(load_default="hash", validate=OneOf(["hash", "md5"]))
    DEBUG = fields.Boolean(load_default=False)
    URL_APPLICATION = fields.Url(required=True)
    API_ENDPOINT = fields.Url(required=True)
    API_TAXHUB = fields.Url(required=True)
    CODE_APPLICATION = fields.String(load_default="GN")
    XML_NAMESPACE = fields.String(load_default="{http://inpn.mnhn.fr/mtd}")
    MTD_API_ENDPOINT = fields.Url(load_default="https://preprod-inpn.mnhn.fr/mtd")
    DISABLED_MODULES = fields.List(fields.String(), load_default=[])
    CAS_PUBLIC = fields.Nested(CasFrontend, load_default=CasFrontend().load({}))
    RIGHTS = fields.Nested(RightsSchemaConf, load_default=RightsSchemaConf().load({}))
    FRONTEND = fields.Nested(GnFrontEndConf, load_default=GnFrontEndConf().load({}))
    SYNTHESE = fields.Nested(Synthese, load_default=Synthese().load({}))
    MAPCONFIG = fields.Nested(MapConfig, load_default=MapConfig().load({}))
    # Ajoute la surchouche 'taxonomique' sur l'API nomenclature
    ENABLE_NOMENCLATURE_TAXONOMIC_FILTERS = fields.Boolean(load_default=True)
    BDD = fields.Nested(BddConfig, load_default=BddConfig().load({}))
    URL_USERSHUB = fields.Url(required=False)
    ACCOUNT_MANAGEMENT = fields.Nested(
        AccountManagement, load_default=AccountManagement().load({})
    )
    MEDIAS = fields.Nested(MediasConfig, load_default=MediasConfig().load({}))
    STATIC_URL = fields.String(load_default="/static")
    MEDIA_URL = fields.String(load_default="/media")
    METADATA = fields.Nested(MetadataConfig, load_default=MetadataConfig().load({}))
    MTD = fields.Nested(MTDSchemaConf, load_default=MTDSchemaConf().load({}))
    NB_MAX_DATA_SENSITIVITY_REPORT = fields.Integer(load_default=1000000)
    ADDITIONAL_FIELDS = fields.Nested(AdditionalFields, load_default=AdditionalFields().load({}))
    PUBLIC_ACCESS_USERNAME = fields.String(load_default="")
    TAXHUB = fields.Nested(TaxHub, load_default=TaxHub().load({}))
    HOME = fields.Nested(HomeConfig, load_default=HomeConfig().load({}))
    NOTIFICATIONS_ENABLED = fields.Boolean(load_default=True)

    @validates_schema
    def validate_enable_sign_up(self, data, **kwargs):
        # si CAS_PUBLIC = true and ENABLE_SIGN_UP = true
        if data["CAS_PUBLIC"]["CAS_AUTHENTIFICATION"] and (
            data["ACCOUNT_MANAGEMENT"]["ENABLE_SIGN_UP"]
            or data["ACCOUNT_MANAGEMENT"]["ENABLE_USER_MANAGEMENT"]
        ):
            raise ValidationError(
                "CAS_PUBLIC et ENABLE_SIGN_UP ou ENABLE_USER_MANAGEMENT ne peuvent être activés ensemble",
                "ENABLE_SIGN_UP, ENABLE_USER_MANAGEMENT",
            )

    @validates_schema
    def validate_account_autovalidation(self, data, **kwargs):
        account_config = data["ACCOUNT_MANAGEMENT"]
        if (
            account_config["AUTO_ACCOUNT_CREATION"] is False
            and account_config["VALIDATOR_EMAIL"] is None
        ):
            raise ValidationError(
                "Si AUTO_ACCOUNT_CREATION = False, veuillez remplir le paramètre VALIDATOR_EMAIL",
                "AUTO_ACCOUNT_CREATION, VALIDATOR_EMAIL",
            )

    @post_load
    def insert_module_config(self, data, **kwargs):
        for module_code_entry in iter_entry_points("gn_module", "code"):
            module_code = module_code_entry.resolve()
            if module_code in data["DISABLED_MODULES"]:
                continue
            data[module_code] = get_module_config(module_code_entry.dist)
        return data
