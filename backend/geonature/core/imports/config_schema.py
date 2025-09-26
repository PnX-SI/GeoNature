"""
Spécification du schéma toml des paramètres de configurations
"""

from marshmallow import Schema, fields
from marshmallow.validate import OneOf

DEFAULT_LIST_COLUMN = [
    {
        "prop": "format_source_file",
        "name": "Format",
        "show": False,
        "filter": False,
    },
    {
        "prop": "full_file_name",
        "name": "Fichier",
        "show": True,
        "filter": True,
    },
    {
        "prop": "statistics_rows",
        "name": "Lignes importées",
        "show": True,
        "filter": False,
    },
    {
        "prop": "date_create_import",
        "name": "Debut import",
        "show": True,
        "filter": True,
    },
    {
        "prop": "authors_name",
        "name": "Auteur",
        "show": True,
        "filter": False,
    },
]


UPLOAD_DIRECTORY = "upload"


IMPORTS_SCHEMA_NAME = "gn_imports"

PREFIX = "gn_"

SRID = [{"name": "WGS84", "code": 4326}, {"name": "Lambert93", "code": 2154}]

ENCODAGE = ["UTF-8"]


MAX_FILE_SIZE = 1000

ALLOWED_EXTENSIONS = [".csv"]

DEFAULT_COUNT_VALUE = 1

ALLOW_VALUE_MAPPING = True


# If VALUE MAPPING is not allowed, you must specify the DEFAULT_VALUE_MAPPING_ID
DEFAULT_VALUE_MAPPING_ID = 3

# Parameter to define the rank shown in the doughnut chart in the import report
# must be in ['regne', 'phylum', 'classe', 'ordre', 'famille', 'sous_famille', 'tribu', 'group1_inpn', 'group2_inpn']
DEFAULT_RANK = "regne"


class ImportConfigSchema(Schema):
    LIST_COLUMNS_FRONTEND = fields.List(fields.Dict, load_default=DEFAULT_LIST_COLUMN)
    PREFIX = fields.String(load_default=PREFIX)
    SRID = fields.List(fields.Dict, load_default=SRID)
    ENCODAGE = fields.List(fields.String, load_default=ENCODAGE)
    MAX_FILE_SIZE = fields.Integer(load_default=MAX_FILE_SIZE)
    MAX_ENCODING_DETECTION_DURATION = fields.Integer(load_default=2.0)
    ALLOWED_EXTENSIONS = fields.List(fields.String, load_default=ALLOWED_EXTENSIONS)
    DEFAULT_COUNT_VALUE = fields.Integer(load_default=DEFAULT_COUNT_VALUE)
    ALLOW_VALUE_MAPPING = fields.Boolean(load_default=ALLOW_VALUE_MAPPING)
    DEFAULT_VALUE_MAPPING_ID = fields.Integer(
        load_default=DEFAULT_VALUE_MAPPING_ID
    )  # FIXME: unused
    FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE = fields.Boolean(load_default=True)
    DISPLAY_MAPPED_VALUES = fields.Boolean(load_default=True)  # FIXME: unused
    # When setting PER_DATASET_UUID_CHECK=True (used for import in synthese):
    # - Replace the unicity constraint on unique_id_sinp with an unicity constraint on (unique_id_sinp,id_dataset).
    # - Disable per-row dataset import by setting display=False in gn_imports.bib_fields
    #   for the id_dataset field belonging to synthese destination.
    PER_DATASET_UUID_CHECK = fields.Boolean(load_default=False)

    CHECK_PRIVATE_JDD_BLURING = fields.Boolean(load_default=False)
    CHECK_REF_BIBLIO_LITTERATURE = fields.Boolean(load_default=True)
    CHECK_EXIST_PROOF = fields.Boolean(load_default=True)
    DEFAULT_GENERATE_MISSING_UUID = fields.Boolean(load_default=True)
    DEFAULT_RANK = fields.String(
        load_default=DEFAULT_RANK,
        validate=OneOf(
            [
                "regne",
                "phylum",
                "classe",
                "ordre",
                "famille",
                "sous_famille",
                "tribu",
                "group1_inpn",
                "group2_inpn",
            ]
        ),
    )
    ID_AREA_RESTRICTION = fields.Integer(load_default=None)
    ID_LIST_TAXA_RESTRICTION = fields.Integer(load_default=None)
    MODULE_URL = fields.String(load_default="/import")
    DATAFRAME_BATCH_SIZE = fields.Integer(load_default=10000)
    EXPORT_REPORT_PDF_FILENAME = fields.String(
        load_default="import_{id_import}_{date_create_import}_report.pdf"
    )
    INSERT_BATCH_SIZE = fields.Integer(load_default=1000)
