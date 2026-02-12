"""[import] review on error types description

Revision ID: 8c31693c2183
Revises: ea261b6185b3
Create Date: 2025-08-18 14:17:03.445536

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.schema import Table, MetaData


# revision identifiers, used by Alembic.
revision = "8c31693c2183"
down_revision = "ea261b6185b3"
branch_labels = None
depends_on = None

MODIFICATIONS = {
    "ALTI_MIN_SUP_ALTI_MAX": {
        "NEW": "Une des altitudes minimales fournies est supérieure à l'altitude maximale.",
        "OLD": "Une des alititudes minimales fournies est supérieure à l'altitude maximale  ",
    },
    "CD_HAB_NOT_FOUND": {
        "NEW": "Le cd_hab indiqué est introuvable dans le référentiel Habref présent en base de données.",
        "OLD": "Le cdHab indiqué est introuvable dans le référentiel Habref présent en base de donneés.",
    },
    "CD_NOM_NOT_FOUND": {
        "NEW": "Le cd_nom indiqué est introuvable dans le référentiel TAXREF présent en base de données ou dans la liste de taxons importables configurée par l'administrateur.",
        "OLD": "Le Cd_nom renseigné ne peut être importé car il est absent du référentiel TAXREF ou de la liste de taxons importables configurée par l'administrateur",
    },
    "CONDITIONAL_INVALID_DATA": {"NEW": "Erreur de valeur", "OLD": "Erreur de valeur"},
    "CONDITIONAL_MANDATORY_FIELD_ERROR": {
        "NEW": "Un champ rendu obligatoire par la présence d’un autre champ n’a pas été rempli. Par exemple, si profondeur_max est indiqué, profondeur_min doit être donné.",
        "OLD": "Champs obligatoires conditionnels manquants. Il existe des ensembles de champs liés à un concept qui sont “obligatoires conditionnels”, c’est à dire que si l'un des champs du concept est utilisé, alors d'autres champs du concept deviennent obligatoires.",
    },
    "COUNT_MIN_SUP_COUNT_MAX": {
        "NEW": "Incohérence entre les champs dénombrement. La valeur de dénombrement_min est supérieure à celle de dénombrement_max ou la valeur de dénombrement_max est inférieure à dénombrement_min.",
        "OLD": "Incohérence entre les champs dénombrement. La valeur de denombrement_min est supérieure à celle de denombrement _max ou la valeur de denombrement _max est inférieur à denombrement_min.",
    },
    "DATASET_NOT_ACTIVE": {
        "NEW": "Les jeux de données doivent être actifs pour pouvoir importer des données.",
        "OLD": "Les jeux de données doivent être actifs pour pouvoir importer des données.",
    },
    "DATASET_NOT_AUTHORIZED": {
        "NEW": "Vous n’avez pas les permissions nécessaires sur un des jeux de données.",
        "OLD": "Vous n’avez pas les permissions nécessaire sur le jeu de données.",
    },
    "DATASET_NOT_FOUND": {
        "NEW": "Un ou plusieurs jeux de données indiqués par leur identifiant n’ont pas été trouvés.",
        "OLD": "La référence du jeu de données n’a pas été trouvé",
    },
    "DATE_MAX_TOO_HIGH": {
        "NEW": "La date de fin donnée est supérieure à la date d'exécution de l'import.",
        "OLD": "La date de fin est dans le futur",
    },
    "DATE_MAX_TOO_LOW": {
        "NEW": "La date de fin est inférieure à 1900.",
        "OLD": "La date de fin est inférieur à 1900",
    },
    "DATE_MIN_SUP_DATE_MAX": {
        "NEW": "Une des dates de début fournies est supérieure à sa date de fin.",
        "OLD": "date_min > date_max",
    },
    "DATE_MIN_TOO_HIGH": {
        "NEW": "La date de début est supérieure à la date d'exécution de l'import.",
        "OLD": "La date de début est dans le futur",
    },
    "DATE_MIN_TOO_LOW": {
        "NEW": "La date de début est inférieure à 1900.",
        "OLD": "La date de début est inférieur à 1900",
    },
    "DEPTH_MIN_SUP_ALTI_MAX": {
        "NEW": "Une des profondeurs minimales fournies est supérieure à sa profondeur maximale.",
        "OLD": "profondeur min > profondeur max",
    },
    "DUPLICATE_ENTITY_SOURCE_PK": {
        "NEW": "Deux lignes entités ont la même clé primaire d’origine. Les clés primaires du fichier source ne peuvent pas être dupliquées.",
        "OLD": "Deux lignes du fichier ont la même clé primaire d’origine ; les clés primaires du fichier source ne peuvent pas être dupliquées.",
    },
    "DUPLICATE_UUID": {
        "NEW": "Un ou plusieurs UUID sont utilisés pour identifier différentes entités dans le fichier fourni.",
        "OLD": "L'identificant sinp n'est pas unique dans le fichier fournis",
    },
    "EMPTY_FILE": {"NEW": "Le fichier fourni est vide.", "OLD": "Le fichier fournit est vide"},
    "EMPTY_ROW": {
        "NEW": "Une ligne du fichier est vide. Chaque ligne doit avoir au moins une cellule non vide.",
        "OLD": "Une ligne du fichier est vide ; les lignes doivent avoir au moins une cellule non vide.",
    },
    "ENCODING_ERROR": {
        "NEW": "Erreur de lecture des données en raison d'un problème d'encodage.",
        "OLD": "Erreur de lecture des données en raison d'un problème d'encodage.",
    },
    "ERRONEOUS_PARENT_ENTITY": {
        "NEW": "L’entité parente est en erreur. Par exemple, si une ou plusieurs observations est associé à une visite qui contient des erreurs, celles-ci ne pourront pas être importées.",
        "OLD": "L’entité parente est en erreur.",
    },
    "ERROR_WHILE_LOADING_FILE": {
        "NEW": "Une erreur s'est produite lors du chargement du fichier. Une des erreurs les plus communes repose sur l'utilisation d'un séparateur incompatible (Séparateur accepté : ',' , ';').",
        "OLD": "Une erreur de chargement s'est produite, probablement à cause d'un mauvais séparateur dans le fichier.",
    },
    "EXISTING_UUID": {
        "NEW": "L'identifiant UUID fourni existe déjà en base. Il faut en fournir un autre UUID ou laisser la valeur vide pour que l'attribution d'UUID soit automatique.",
        "OLD": "L'identifiant SINP fourni existe déjà en base.  Il faut en fournir une autre ou laisser la valeur vide pour une attribution automatique.",
    },
    "FILE_EXTENSION_ERROR": {
        "NEW": "L'extension du fichier téléversé est incorrecte.",
        "OLD": "L'extension de fichier fournie n'est pas correct",
    },
    "FILE_FORMAT_ERROR": {
        "NEW": "Le format du fichier téléversé est incorrect.",
        "OLD": "Erreur de lecture des données ; le format du fichier est incorrect.",
    },
    "FILE_NAME_ERROR": {
        "NEW": "Le nom de fichier ne comporte que des chiffres.",
        "OLD": "Le nom de fichier ne comporte que des chiffres.",
    },
    "FILE_NAME_TOO_LONG": {
        "NEW": "Le nom du fichier téléversé est trop long. La longueur du nom de fichier ne doit pas être supérieure à 100 caractères.",
        "OLD": "Nom de fichier trop long ; la longueur du nom de fichier ne doit pas être supérieure à 100 caractères",
    },
    "FILE_OVERSIZE": {
        "NEW": "La taille du fichier dépasse la limite autorisée.",
        "OLD": "La taille du fichier dépasse la taille du fichier autorisée",
    },
    "FILE_WITH_NO_DATA": {
        "NEW": "Le fichier ne comporte aucune donnée.",
        "OLD": "Le fichier ne comporte aucune donnée.",
    },
    "GEOMETRY_OUTSIDE": {
        "NEW": "La géométrie se trouve à l'extérieur du territoire renseigné.",
        "OLD": "La géométrie se trouve à l'extérieur du territoire renseigné",
    },
    "GEOMETRY_OUT_OF_BOX": {
        "NEW": "Coordonnées géographiques en dehors du périmètre géographique de l'instance.",
        "OLD": "Coordonnées géographiques en dehors du périmètre géographique de l'instance",
    },
    "HEADER_COLUMN_EMPTY": {
        "NEW": "Un des noms de colonne de l’en-tête est vide. Toutes les colonnes doivent être associées avec une en-tête.",
        "OLD": "Un des noms de colonne de l’en-tête est vide ; tous les noms de colonne doivent avoir une valeur.",
    },
    "HEADER_SAME_COLUMN_NAME": {
        "NEW": "Plusieurs colonnes portent le même nom. Veiller à ce que chaque nom de colonne soit unique.",
        "OLD": "Plusieurs colonnes de l'en-tête portent le même nom ; tous les noms de colonne de l'en-tête doivent être uniques.",
    },
    "ID_DIGITISER_NOT_EXISITING": {
        "NEW": 'L’id_digitizer fourni n\'existe pas dans la table "t_roles".',
        "OLD": "id_digitizer n'existe pas dans la table \"t_roles",
    },
    "INCOHERENT_DATA": {
        "NEW": "Pour une même entité (e.g. un site), des incohérences ont été trouvées sur les valeurs d'une ou plusieurs colonnes. Par exemple, des géométries différentes pour un même site.",
        "OLD": "Les données indiquées pour une ou plusieurs entités sont incohérentes sur différentes lignes.",
    },
    "INVALID_ATTACHMENT_CODE": {
        "NEW": "La valeur de codeCommune/codeMaille/codeDepartement n’a pu être trouvée dans la version courante du référentiel géographique.",
        "OLD": "Le code commune/maille/département indiqué ne fait pas partie du référentiel des géographique; la valeur de codeCommune/codeMaille/codeDepartement n’a pu être trouvée dans la version courante du référentiel.",
    },
    "INVALID_BOOL": {
        "NEW": "Le champ doit être renseigné avec une valeur binaire (0 ou 1, true ou false).",
        "OLD": "Le champ doit être renseigné avec une valeur binaire (0 ou 1, true ou false).",
    },
    "INVALID_CHAR_LENGTH": {
        "NEW": "La longueur de la chaîne dépasse la longueur maximale autorisée.",
        "OLD": "Chaîne de caractères trop longue ; la longueur de la chaîne dépasse la longueur maximale autorisée.",
    },
    "INVALID_DATE": {
        "NEW": "Le format de date est incorrect dans une colonne de type Datetime. Le format attendu est YYYY-MM-DD ou DD-MM-YYYY (les heures sont acceptées sous ce format : HH:MM:SS) - Les séparateurs / . : sont également acceptés.",
        "OLD": "Le format de date est incorrect dans une colonne de type Datetime. Le format attendu est YYYY-MM-DD ou DD-MM-YYYY (les heures sont acceptées sous ce format : HH:MM:SS) - Les séparateurs / . : sont également acceptés",
    },
    "INVALID_EXISTING_PROOF_VALUE": {
        "NEW": "Incohérence entre les champs de preuve. Si le champ “preuveExistante” vaut oui, alors l’un des deux champs “preuveNumérique” ou “preuveNonNumérique” doit être rempli. A l’inverse, si l’un de ces deux champs est rempli, alors “preuveExistante” ne doit pas prendre une autre valeur que “oui” (code 1).",
        "OLD": "Incohérence entre les champs de preuve ; si le champ “preuveExistante” vaut oui, alors l’un des deux champs “preuveNumérique” ou “preuveNonNumérique” doit être rempli. A l’inverse, si l’un de ces deux champs est rempli, alors “preuveExistante” ne doit pas prendre une autre valeur que “oui” (code 1).",
    },
    "INVALID_GEOMETRY": {
        "NEW": "La géométrie indiquée n'est pas valide. Si le format attendu est des coordonnées en (latitude, longitude), vérifier que les valeurs données sont bien des nombres réels. Si la géométrie provient d'un WKT, vérifier que ces dernières respectent les normes de validités listées dans la documentation de PostGIS https://postgis.net/docs/using_postgis_dbmanagement.html#OGC_Validity .",
        "OLD": "Géométrie invalide",
    },
    "INVALID_GEOM_CODE": {
        "NEW": "Le code (maille/département/commune) n'existe pas dans le référentiel géographique actuel.",
        "OLD": "Le code (maille/département/commune) n'existe pas dans le réferentiel géographique actuel",
    },
    "INVALID_INTEGER": {
        "NEW": "Format numérique entier incorrect ou négatif dans une des colonnes de type Entier.",
        "OLD": "Format numérique entier incorrect ou négatif dans une des colonnes de type Entier.",
    },
    "INVALID_NOMENCLATURE": {
        "NEW": "Code nomenclature erroné. La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au standard en cours.",
        "OLD": "Code nomenclature erroné ; La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au Standard en cours.",
    },
    "INVALID_NOMENCLATURE_WARNING": {
        "NEW": "(Non bloquant) Code nomenclature erroné et remplacé par sa valeur par défaut. La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au Standard en cours.",
        "OLD": "(Non bloquant) Code nomenclature erroné et remplacé par sa valeur par défaut ; La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au Standard en cours.",
    },
    "INVALID_NUMERIC": {
        "NEW": "Le champ doit être renseigné avec une valeur numérique (entier, flottant).",
        "OLD": "Le champ doit être renseigné avec une valeur numérique (entier, flottant).",
    },
    "INVALID_REAL": {
        "NEW": "Le format numérique réel est incorrect ou négatif dans une des colonnes de type REEL.",
        "OLD": "Le format numérique réel est incorrect ou négatif dans une des colonnes de type REEL.",
    },
    "INVALID_STATUT_SOURCE_VALUE": {
        "NEW": "Référence bibliographique manquante. Si le champ “statutSource” a la valeur “Li” (Littérature), alors une référence bibliographique doit être indiquée.",
        "OLD": "Référence bibliographique manquante ; si le champ “statutSource” a la valeur “Li” (Littérature), alors une référence bibliographique doit être indiquée.",
    },
    "INVALID_URL_PROOF": {
        "NEW": "PreuveNumerique n’est pas une url ; le champ “preuveNumérique” indique l’adresse web à laquelle on pourra trouver la preuve numérique ou l’archive contenant toutes les preuves numériques. Il doit commencer par “http://”, “https://”, ou “ftp://”.",
        "OLD": "PreuveNumerique n’est pas une url ; le champ “preuveNumérique” indique l’adresse web à laquelle on pourra trouver la preuve numérique ou l’archive contenant toutes les preuves numériques. Il doit commencer par “http://”, “https://”, ou “ftp://”.",
    },
    "INVALID_UUID": {
        "NEW": "L'identifiant permanent doit être un UUID valide, ou sa valeur doit être vide.",
        "OLD": "L'identifiant permanent doit être un UUID valide, ou sa valeur doit être vide.",
    },
    "INVALID_WKT": {
        "NEW": "La valeur de la géométrie ne correspond pas au format WKT. Veuillez vérifier que données respectent le standard définie sur https://en.wikipedia.org/wiki/Well-known_text_representation_of_geometry .",
        "OLD": "Géométrie invalide ; la valeur de la géométrie ne correspond pas au format WKT.",
    },
    "MISSING_GEOM": {
        "NEW": "Géoréférencement manquant. Un géoréférencement doit être fourni, c’est à dire qu’il faut livrer : soit une géométrie, soit une ou plusieurs commune(s), ou département(s), ou maille(s), dont le champ “typeInfoGeo” est indiqué à 1.",
        "OLD": "Géoréférencement manquant ; un géoréférencement doit être fourni, c’est à dire qu’il faut livrer : soit une géométrie, soit une ou plusieurs commune(s), ou département(s), ou maille(s), dont le champ “typeInfoGeo” est indiqué à 1.",
    },
    "MISSING_VALUE": {
        "NEW": "Valeur manquante dans un champ obligatoire.",
        "OLD": "Valeur manquante dans un champs obligatoire",
    },
    "MULTIPLE_ATTACHMENT_TYPE_CODE": {
        "NEW": "Plusieurs géoréférencements ; un seul géoréférencement doit être livré. Une seule des colonnes codeCommune/codeMaille/codeDépartement doit être remplie pour chaque ligne.",
        "OLD": "Plusieurs géoréférencements ; un seul géoréférencement doit être livré. Une seule des colonnes codeCommune/codeMaille/codeDépartement doit être remplie pour chaque ligne",
    },
    "MULTIPLE_CODE_ATTACHMENT": {
        "NEW": "Plusieurs codes de rattachement fournis pour une même ligne. Une ligne doit avoir un seul code rattachement (code commune OU code maille OU code département)",
        "OLD": "Plusieurs codes de rattachement fournis pour une même ligne. Une ligne doit avoir un seul code rattachement (code commune OU code maille OU code département)",
    },
    "NO-GEOM": {
        "NEW": "Aucune géométrie fournie (ni X/Y, WKT ou code)",
        "OLD": "Aucune géometrie fournie (ni X/Y, WKT ou code)",
    },
    "NO_FILE_DETECTED": {"NEW": "Aucun fichier détecté.", "OLD": "Aucun fichier détecté."},
    "NO_FILE_SENDED": {"NEW": "Aucun fichier envoyé.", "OLD": "Aucun fichier envoyé"},
    "NO_PARENT_ENTITY": {
        "NEW": "Aucune entité parente identifiée.",
        "OLD": "Aucune entité parente identifiée.",
    },
    "ORPHAN_ROW": {
        "NEW": "La ligne du fichier n’a pû être rattachée à aucune entité.",
        "OLD": "La ligne du fichier n’a pû être rattaché à aucune entité.",
    },
    "PROJECTION_ERROR": {
        "NEW": "Erreur de projection pour les coordonnées fournies.",
        "OLD": "Erreur de projection pour les coordonnées fournies",
    },
    "ROW_HAVE_LESS_COLUMN": {
        "NEW": "Une ligne du fichier a moins de colonnes que l'en-tête.",
        "OLD": "Une ligne du fichier a moins de colonnes que l'en-tête.",
    },
    "ROW_HAVE_TOO_MUCH_COLUMN": {
        "NEW": "Une ligne du fichier a plus de colonnes que l'en-tête.",
        "OLD": "Une ligne du fichier a plus de colonnes que l'en-tête.",
    },
    "SKIP_EXISTING_UUID": {
        "NEW": "Les entités existantes selon leur UUID sont ignorées.",
        "OLD": "Les entitiés existantes selon UUID sont ignorees.",
    },
    "UNKNOWN_ERROR": {"NEW": "Erreur inconnue.", "OLD": ""},
}


def upgrade():
    metadata = MetaData(bind=op.get_bind())
    import_user_error = Table("bib_errors_types", metadata, schema="gn_imports", autoload=True)
    for error_name in MODIFICATIONS:
        op.execute(
            sa.update(import_user_error)
            .values(description=MODIFICATIONS[error_name]["NEW"])
            .where(import_user_error.c.name == error_name)
        )


def downgrade():
    metadata = MetaData(bind=op.get_bind())
    import_user_error = Table("bib_errors_types", metadata, schema="gn_imports", autoload=True)
    for error_name in MODIFICATIONS:
        op.execute(
            sa.update(import_user_error)
            .values(description=MODIFICATIONS[error_name]["OLD"])
            .where(import_user_error.c.name == error_name)
        )
