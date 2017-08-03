import codecs

import yaml

from .filebased import FileBasedSource


__all__ = (
    'YamlFileSource',
)


class YamlFileSource(FileBasedSource):
    def __init__(self, *args, **kwargs):
        self.encoding = kwargs.pop('encoding', 'utf-8')
        super(YamlFileSource, self).__init__(*args, **kwargs)

    def get_settings_from_file(self, file_path, settings, manager=None):
        content = codecs.open(file_path, 'r', self.encoding).read().strip()
        if not content:
            return None

        content = yaml.safe_load(content)
        if not content:
            return None

        if not isinstance(content, dict):
            raise TypeError('YAML files must contain only mappings')

        for setting in settings:
            if setting.name in content:
                setting.value = content[setting.name]

        return settings
