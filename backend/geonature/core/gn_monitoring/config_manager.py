'''
    Fonctions permettant de lire un fichier yml de configuration
    et de le parser
'''
from pypnnomenclature.repository import get_nomenclature_list_formated
from geonature.utils.utilstoml import load_toml

from geonature.core.gn_commons.repositories import get_table_location_id

def generate_config(file_path):
    '''
        Lecture et modification des fichiers de configuration yml
        Pour l'instant utile pour la compatiblité avec l'application
            projet_suivi
            ou le frontend génère les formulaires à partir de ces données
    '''
    # Chargement du fichier de configuration
    config = load_toml(file_path)
    config_data = find_field_config(config)
    return config_data


def find_field_config(config_data):
    '''
        Parcours des champs du fichier de config
        de façon à trouver toutes les occurences du champ field
        qui nécessite un traitement particulier
    '''
    if isinstance(config_data, dict):
        for ckey in config_data:
            if ckey == 'fields':
                config_data[ckey] = parse_field(config_data[ckey])
            elif isinstance(config_data[ckey], list):
                for idx, val in enumerate(config_data[ckey]):
                    config_data[ckey][idx] = find_field_config(val)
    return config_data


def parse_field(fieldlist):
    '''
       Traitement particulier pour les champs de type field :
       Chargement des listes de valeurs de nomenclature
    '''
    for field in fieldlist:
        if 'options' not in field:
            field['options'] = {}
        if 'thesaurus_code_type' in field:
            field['options']['choices'] = format_nomenclature_list(
                {
                    'code_type': field['thesaurus_code_type'],
                    'regne': field.get('regne'),
                    'group2_inpn': field.get('group2_inpn'),
                }
            )
        if 'thesaurusHierarchyID' in field:
            field['options']['choices'] = format_nomenclature_list(
                {
                    'code_type': field['thesaurus_code_type'],
                    'hierarchy': field['thesaurusHierarchyID']
                }
            )
        if 'attached_table_location' in field['options']:
            (schema_name, table_name) = field['options']['attached_table_location'].split('.') # noqa
            field['options']['id_table_location'] = (
                get_table_location_id(schema_name, table_name)
            )
        if 'fields' in field:
            field['fields'] = parse_field(field['fields'])

    return fieldlist


def format_nomenclature_list(params):
    '''
        Mise en forme des listes de valeurs de façon à assurer une
        compatibilité avec l'application de suivis
    '''
    mapping = {
        'id': {'object': 'nomenclature', 'field': 'id_nomenclature'},
        'libelle': {'object': 'nomenclature', 'field': 'label_default'}
    }
    nomenclature = get_nomenclature_list_formated(params, mapping)
    return nomenclature
