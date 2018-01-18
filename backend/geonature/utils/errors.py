'''
    Erreurs propres à GN
'''


class ConfigError(Exception):
    '''
        Configuration error class
        Retournée quand un fichier de configuration n'est pas conforme aux attentes
    '''
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)
