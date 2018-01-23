'''
    Erreurs propres à GN
'''


class GeoNatureError(Exception):
    pass


class GNModuleInstallError(GeoNatureError):
    pass


class ConfigError(GeoNatureError):
    '''
        Configuration error class
        Quand un fichier de configuration n'est pas conforme aux attentes
    '''
    def __init__(self, file, value):
        self.value = value
        self.file = file

    def __str__(self):
        msg = "Error in the config file '{}'. Fix the following:\n"
        msg = msg.format(self.file)
        for key, errors in self.value.items():
            errors = "\n\t\t-".join(errors)
            msg += "\n\t{}:\n\t\t-{}".format(key, errors)
        return msg
