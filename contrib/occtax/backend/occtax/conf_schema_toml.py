"""
   Spécification du schéma toml des paramètres de configurations
   Fichier spécifiant les types des paramètres et leurs valeurs par défaut
   Fichier à ne pas modifier. Paramètres surcouchables dans config/config_gn_module.tml
"""

from marshmallow import Schema, fields, post_load


class MapListConfig(Schema):
    pass


class FormConfig(Schema):
    date_min = fields.Boolean(load_default=True)
    date_max = fields.Boolean(load_default=True)
    hour_min = fields.Boolean(load_default=True)
    hour_max = fields.Boolean(load_default=True)
    altitude_min = fields.Boolean(load_default=True)
    altitude_max = fields.Boolean(load_default=True)
    depth_min = fields.Boolean(load_default=False)
    depth_max = fields.Boolean(load_default=False)
    altitude_max = fields.Boolean(load_default=True)
    tech_collect = fields.Boolean(load_default=False)
    group_type = fields.Boolean(load_default=False)
    comment_releve = fields.Boolean(load_default=True)
    obs_tech = fields.Boolean(load_default=True)
    bio_condition = fields.Boolean(load_default=True)
    bio_status = fields.Boolean(load_default=True)
    naturalness = fields.Boolean(load_default=True)
    exist_proof = fields.Boolean(load_default=True)
    observation_status = fields.Boolean(load_default=True)
    blurring = fields.Boolean(load_default=False)
    determiner = fields.Boolean(load_default=True)
    determination_method = fields.Boolean(load_default=True)
    digital_proof = fields.Boolean(load_default=True)
    non_digital_proof = fields.Boolean(load_default=True)
    source_status = fields.Boolean(load_default=False)
    comment_occ = fields.Boolean(load_default=True)
    life_stage = fields.Boolean(load_default=True)
    sex = fields.Boolean(load_default=True)
    obj_count = fields.Boolean(load_default=True)
    type_count = fields.Boolean(load_default=True)
    count_min = fields.Boolean(load_default=True)
    count_max = fields.Boolean(load_default=True)
    display_nom_valide = fields.Boolean(load_default=True)
    geo_object_nature = fields.Boolean(load_default=False)
    habitat = fields.Boolean(load_default=True)
    grp_method = fields.Boolean(load_default=False)
    behaviour = fields.Boolean(load_default=True)
    place_name = fields.Boolean(load_default=False)
    precision = fields.Boolean(load_default=False)


default_map_list_conf = [
    {"prop": "taxons", "name": "Taxon(s)"},
    {"prop": "observateurs", "name": "Observateurs"},
    {"prop": "date", "name": "Date"},
    {"prop": "dataset", "name": "Jeu de données"},
]

available_maplist_column = [
    {"prop": "altitude_min", "name": "Altitude min"},
    {"prop": "altitude_max", "name": "Altitude max"},
    {"prop": "comment", "name": "Commentaire"},
    {"prop": "date", "name": "Date"},
    {"prop": "date_min", "name": "Date début"},
    {"prop": "date_max", "name": "Date fin"},
    {"prop": "id_dataset", "name": "ID jeu de données"},
    {"prop": "dataset", "name": "Jeu de données"},
    {"prop": "id_digitiser", "name": "ID rédacteur"},
    {"prop": "id_releve_occtax", "name": "ID relevé"},
    {"prop": "observateurs", "name": "Observateurs"},
    {"prop": "nb_taxons", "name": "Nb. taxon"},
]

default_columns_export = [
    "id_releve_occtax",
    "permId",
    "statObs",
    "nomCite",
    "dateDebut",
    "dateFin",
    "heureDebut",
    "heureFin",
    "altMax",
    "altMin",
    "profMin",
    "profMax",
    "cdNom",
    "cdRef",
    "versionTAXREF",
    "datedet",
    "comment",
    "dSPublique",
    "jddMetadonneeDEEId",
    "statSource",
    "diffusionNiveauPrecision",
    "idOrigine",
    "jddCode",
    "jddId",
    "refBiblio",
    "obsTech",
    "techCollect",
    "ocEtatBio",
    "ocNat",
    "ocSex",
    "ocStade",
    "ocBiogeo",
    "ocStatBio",
    "preuveOui",
    "ocMethDet",
    "preuvNum",
    "preuvNoNum",
    "obsCtx",
    "obsDescr",
    "permIdGrp",
    "methGrp",
    "typGrp",
    "denbrMax",
    "denbrMin",
    "objDenbr",
    "typDenbr",
    "obsId",
    "obsNomOrg",
    "detId",
    "detNomOrg",
    "orgGestDat",
    "WKT",
    "natObjGeo",
    "nomLieu",
    "precision",
    "additional_data",
]

# Export available format (Only csv, geojson and shapefile and 'gpkg' is possible)
available_export_format = ["csv", "geojson", "shapefile"]

list_messages = {
    "emptyMessage": "Aucune donnée à afficher",
    "totalMessage": "Relevé(s) au total",
}

export_message = """
<p> <b> Attention: </b> </br>
Vous vous apprêtez à télécharger les données de la <b>recherche courante. </b> </p>
"""

default_export_col_name_additional_data = "additional_data"

default_media_fields_details = [
    "title_fr",
    "description_fr",
    "id_nomenclature_media_type",
    "author",
    "bFile",
]


class GnModuleSchemaConf(Schema):
    form_fields = fields.Nested(FormConfig, load_default=FormConfig().load({}))
    observers_txt = fields.Boolean(load_default=False)
    export_view_name = fields.String(load_default="v_export_occtax")
    export_geom_columns_name = fields.String(load_default="geom_4326")
    export_id_column_name = fields.String(load_default="permId")
    export_srid = fields.Integer(load_default=4326)
    export_observer_txt_column = fields.String(load_default="obsId")
    export_available_format = fields.List(fields.String(), load_default=available_export_format)
    export_columns = fields.List(fields.String(), load_default=default_columns_export)
    export_message = fields.String(load_default=export_message)
    list_messages = fields.Dict(load_default=list_messages)
    digital_proof_validator = fields.Boolean(load_default=True)
    releve_map_zoom_level = fields.Integer()
    id_taxon_list = fields.Integer(load_default=None)
    taxon_result_number = fields.Integer(load_default=20)
    id_observers_list = fields.Integer(load_default=1)
    default_maplist_columns = fields.List(fields.Dict(), load_default=default_map_list_conf)
    available_maplist_column = fields.List(fields.Dict(), load_default=available_maplist_column)
    MAX_EXPORT_NUMBER = fields.Integer(load_default=50000)
    ENABLE_GPS_TOOL = fields.Boolean(load_default=True)
    ENABLE_UPLOAD_TOOL = fields.Boolean(load_default=True)
    DATE_FORM_WITH_TODAY = fields.Boolean(load_default=True)
    ENABLE_SETTINGS_TOOLS = fields.Boolean(load_default=False)
    ENABLE_MEDIAS = fields.Boolean(load_default=True)
    ENABLE_MY_PLACES = fields.Boolean(load_default=True)
    DISPLAY_VERNACULAR_NAME = fields.Boolean(load_default=True)
    export_col_name_additional_data = fields.String(
        load_default=default_export_col_name_additional_data
    )
    MEDIA_FIELDS_DETAILS = fields.List(fields.String(), load_default=default_media_fields_details)
    ADD_MEDIA_IN_EXPORT = fields.Boolean(load_default=False)
    ID_LIST_HABITAT = fields.Integer(load_default=None)
    CD_TYPO_HABITAT = fields.Integer(load_default=None)
