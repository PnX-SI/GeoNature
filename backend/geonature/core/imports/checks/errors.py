class ImportCodeError:
    """
    List of all the possible errors returned during the import process.

    Attributes
    ----------
    DATASET_NOT_FOUND : str
        The referenced dataset was not found
    DATASET_NOT_AUTHORIZED : str
        The dataset is not authorized to the current user
    DATASET_NOT_ACTIVE : str
        The dataset is inactive
    MULTIPLE_ATTACHMENT_TYPE_CODE : str
        Multiple attachments of the same type are not allowed
    MULTIPLE_CODE_ATTACHMENT : str
        Multiple attachments (commune, maille, departement) with the same code were given.
    INVALID_DATE : str
        The date is not valid
    INVALID_UUID : str
        The uuid is not valid
    INVALID_INTEGER : str
        The integer is not valid
    INVALID_NUMERIC : str
        The numeric is not valid
    INVALID_WKT : str
        The WKT string is not valid
    INVALID_GEOMETRY : str
        The geometry is not valid
    INVALID_BOOL : str
        The boolean is not valid
    INVALID_ATTACHMENT_CODE : str
        The code given does not exists in the desitination referential
    INVALID_CHAR_LENGTH : str
        The character length is not valid
    DATE_MIN_TOO_HIGH : str
        The date min is too high
    DATE_MAX_TOO_LOW : str
        The date max is too low
    DATE_MAX_TOO_HIGH : str
        The date max is too high
    DATE_MIN_TOO_LOW : str
        The date min is too low
    ALTI_MIN_SUP_ALTI_MAX : str
        The altitude min is superior to the altitude max
    DATE_MIN_SUP_DATE_MAX : str
        The date min is superior to the date max
    DEPTH_MIN_SUP_ALTI_MAX : str
        The depth min is superior to the altitude max
    ORPHAN_ROW : str
        The row could not be attached to an other entity # FIXME: clarify
    DUPLICATE_ROWS : str
        One rows appears more than once
    DUPLICATE_UUID : str
        A uuid value is duplicated
    EXISTING_UUID: str
        A uuid value already exists in the destination table
    SKIP_EXISTING_UUID: str
        A uuid value already exists in the destination table and should be skipped
    MISSING_VALUE : str
        A required value is missing (see `mandatory` column in `gn_imports.bib_fields` table)
    MISSING_GEOM : str
        The geometry is missing
    GEOMETRY_OUTSIDE : str
        The geometry is outside the polygon defined by ID_AREA_RESTRICTION in the configuration
    NO_GEOM : str
        No geometry given (wherever WKT or latitude/longitude)
    GEOMETRY_OUT_OF_BOX : str
        The geometry is outside of a bounding box
    ERRONEOUS_PARENT_ENTITY : str
        The parent entity is not valid
    NO_PARENT_ENTITY : str
        The parent entity is not found
    DUPLICATE_ENTITY_SOURCE_PK : str
        The entity source primary key is duplicated
    COUNT_MIN_SUP_COUNT_MAX : str
        The count min is superior to the count max
    INVALID_NOMENCLATURE : str
        The nomenclature is invalid
    INVALID_EXISTING_PROOF_VALUE : str
        The existing proof value is invalid
    CONDITIONAL_MANDATORY_FIELD_ERROR : str
        Some conditional mandatory fields are missing #FIXME: clarify
    INVALID_NOMENCLATURE_WARNING : str
        The nomenclature is invalid
    UNKNOWN_ERROR : str
        An unknown error occurred
    INVALID_STATUT_SOURCE_VALUE : str
        The statut source value is invalid
    CONDITIONAL_INVALID_DATA : str
        The conditional data is invalid
    INVALID_URL_PROOF : str
        The url proof is invalid
    ROW_HAVE_TOO_MUCH_COLUMN : str
        A row have too much column
    ROW_HAVE_LESS_COLUMN : str
        A row have less column
    EMPTY_ROW : str
        A row is empty
    HEADER_SAME_COLUMN_NAME : str
        The header have same column name
    EMPTY_FILE : str
        The file is empty
    NO_FILE_SENDED : str
        No file was sent
    ERROR_WHILE_LOADING_FILE : str
        An error occurred while loading the file
    FILE_FORMAT_ERROR : str
        The file format is not valid
    FILE_EXTENSION_ERROR : str
        The file extension is not valid
    FILE_OVERSIZE : str
        The file is too big
    FILE_NAME_TOO_LONG : str
        The file name is too long
    FILE_WITH_NO_DATA : str
        The file have no data
    INCOHERENT_DATA : str
        An entity data is different in multiple rows
    CD_HAB_NOT_FOUND : str
        The habitat code is not found
    CD_NOM_NOT_FOUND : str
        The cd_nom is not found in the instance TaxRef


    """

    # Dataset error
    DATASET_NOT_FOUND = "DATASET_NOT_FOUND"
    DATASET_NOT_AUTHORIZED = "DATASET_NOT_AUTHORIZED"
    DATASET_NOT_ACTIVE = "DATASET_NOT_ACTIVE"
    MULTIPLE_ATTACHMENT_TYPE_CODE = "MULTIPLE_ATTACHMENT_TYPE_CODE"
    MULTIPLE_CODE_ATTACHMENT = "MULTIPLE_CODE_ATTACHMENT"

    # Invalid type error
    INVALID_DATE = "INVALID_DATE"
    INVALID_UUID = "INVALID_UUID"
    INVALID_INTEGER = "INVALID_INTEGER"
    INVALID_NUMERIC = "INVALID_NUMERIC"
    INVALID_WKT = "INVALID_WKT"
    INVALID_GEOMETRY = "INVALID_GEOMETRY"
    INVALID_BOOL = "INVALID_BOOL"
    INVALID_ATTACHMENT_CODE = "INVALID_ATTACHMENT_CODE"
    INVALID_CHAR_LENGTH = "INVALID_CHAR_LENGTH"

    # Date error
    DATE_MIN_TOO_HIGH = "DATE_MIN_TOO_HIGH"
    DATE_MAX_TOO_LOW = "DATE_MAX_TOO_LOW"
    DATE_MAX_TOO_HIGH = "DATE_MAX_TOO_HIGH"
    DATE_MIN_TOO_LOW = "DATE_MIN_TOO_LOW"

    # Min value > max value errors
    DATE_MIN_SUP_DATE_MAX = "DATE_MIN_SUP_DATE_MAX"
    DEPTH_MIN_SUP_ALTI_MAX = "DEPTH_MIN_SUP_ALTI_MAX"
    ALTI_MIN_SUP_ALTI_MAX = "ALTI_MIN_SUP_ALTI_MAX"

    # Line with no child entity associated to a parent
    ORPHAN_ROW = "ORPHAN_ROW"
    DUPLICATE_ROWS = "DUPLICATE_ROWS"
    DUPLICATE_UUID = "DUPLICATE_UUID"
    EXISTING_UUID = "EXISTING_UUID"
    SKIP_EXISTING_UUID = "SKIP_EXISTING_UUID"

    # Missing value when required
    MISSING_VALUE = "MISSING_VALUE"

    # Geometry
    MISSING_GEOM = "MISSING_GEOM"
    GEOMETRY_OUTSIDE = "GEOMETRY_OUTSIDE"
    NO_GEOM = "NO-GEOM"
    GEOMETRY_OUT_OF_BOX = "GEOMETRY_OUT_OF_BOX"

    # Check between child and parent entities
    ERRONEOUS_PARENT_ENTITY = "ERRONEOUS_PARENT_ENTITY"
    NO_PARENT_ENTITY = "NO_PARENT_ENTITY"
    DUPLICATE_ENTITY_SOURCE_PK = "DUPLICATE_ENTITY_SOURCE_PK"
    COUNT_MIN_SUP_COUNT_MAX = "COUNT_MIN_SUP_COUNT_MAX"

    # Nomenclature
    INVALID_NOMENCLATURE = "INVALID_NOMENCLATURE"
    INVALID_EXISTING_PROOF_VALUE = "INVALID_EXISTING_PROOF_VALUE"
    INVALID_NOMENCLATURE_WARNING = "INVALID_NOMENCLATURE_WARNING"

    CONDITIONAL_MANDATORY_FIELD_ERROR = (
        "CONDITIONAL_MANDATORY_FIELD_ERROR"  # FIXME : weird name and confusing where it is used
    )

    UNKNOWN_ERROR = "UNKNOWN_ERROR"
    INVALID_STATUT_SOURCE_VALUE = "INVALID_STATUT_SOURCE_VALUE"
    CONDITIONAL_INVALID_DATA = "CONDITIONAL_INVALID_DATA"
    INVALID_URL_PROOF = "INVALID_URL_PROOF"

    # Source File related errors
    ROW_HAVE_TOO_MUCH_COLUMN = "ROW_HAVE_TOO_MUCH_COLUMN"
    ROW_HAVE_LESS_COLUMN = "ROW_HAVE_LESS_COLUMN"
    EMPTY_ROW = "EMPTY_ROW"
    HEADER_SAME_COLUMN_NAME = "HEADER_SAME_COLUMN_NAME"
    EMPTY_FILE = "EMPTY_FILE"
    NO_FILE_SENDED = "NO_FILE_SENDED"
    ERROR_WHILE_LOADING_FILE = "ERROR_WHILE_LOADING_FILE"
    FILE_FORMAT_ERROR = "FILE_FORMAT_ERROR"
    FILE_EXTENSION_ERROR = "FILE_EXTENSION_ERROR"
    FILE_OVERSIZE = "FILE_OVERSIZE"
    FILE_NAME_TOO_LONG = "FILE_NAME_TOO_LONG"
    FILE_WITH_NO_DATA = "FILE_WITH_NO_DATA"

    # Duplicate entry with different data error
    INCOHERENT_DATA = "INCOHERENT_DATA"

    # Referential error
    CD_HAB_NOT_FOUND = "CD_HAB_NOT_FOUND"
    CD_NOM_NOT_FOUND = "CD_NOM_NOT_FOUND"
