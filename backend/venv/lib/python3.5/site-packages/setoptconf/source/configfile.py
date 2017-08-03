import configparser

from ..setting import ListSetting
from ..util import csv_to_list
from .filebased import FileBasedSource


__all__ = (
    'ConfigFileSource',
)


class ConfigFileSource(FileBasedSource):
    def __init__(self, *args, **kwargs):
        self.section = kwargs.pop('section', None)
        super(ConfigFileSource, self).__init__(*args, **kwargs)

    def get_settings_from_file(self, file_path, settings, manager=None):
        section = self.section or manager.name.lower()

        parser = configparser.ConfigParser()
        parser.read(file_path)

        if not parser.has_section(section):
            return None

        for setting in settings:
            if parser.has_option(section, setting.name):
                opt = parser.get(section, setting.name)
                if isinstance(setting, ListSetting):
                    setting.value = csv_to_list(opt)
                else:
                    setting.value = opt

        return settings
