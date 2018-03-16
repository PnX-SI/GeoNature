import sys
from ruamel.yaml import YAML

from pypnnomenclature.repository import get_nomenclature_list

yml = YAML(typ='safe')
def generate_config(file_path):
    '''
        Lecture et modification des fichiers de configuration yml
        Pour l'instant utile pour la compatiblité avec l'application projet_suivi
            ou le frontend génrère les formulaires à partir de ces données
    '''
    # Chargement du fichier de configuration
    config = open_and_load_yml(file_path)
    config_data = find_field_config(config)
    return yml.dump(config_data, sys.stdout)


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


def open_and_load_yml(file_path):
    with open(file_path, 'r') as fp:
        result = yml.load(fp)
        return result


def parse_field(fieldlist):
    '''
       Traitement particulier pour les champs de type field :
       Chargement des listes de valeurs de nomenclature
    '''
    for field in fieldlist:
        if 'options' not in field:
            field['options'] = {}
        if 'thesaurusID' in field:
            field['options']['choices'] = format_nomenclature_list(
                {'id_type': field['thesaurusID']}
            )
        if 'thesaurusHierarchyID' in field:
            field['options']['choices'] = format_nomenclature_list(
                {
                    'id_type': field['thesaurusID'],
                    'hierarchy': field['thesaurusHierarchyID']
                }
            )
    return fieldlist


def format_nomenclature_list(params):
    '''
        Mise en forme des listes de valeurs de façon à assurer une
        compatibilité avec l'application de suivis
        @TODO Devrait être modifier dans l'application suivis
    '''
    nomenclature = get_nomenclature_list(**params)
    result = []
    if 'values' not in nomenclature:
        return []
    for term in nomenclature['values']:
        result.append({
            'id': term['id_nomenclature'],
            'libelle': term['label_default']
        })

    return result
