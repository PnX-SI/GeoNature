from copy import deepcopy

from .config import Configuration
from .setting import Setting
from .source.base import Source


__all__ = (
    'ConfigurationManager',
)


class ConfigurationManager(object):
    def __init__(self, name):
        self.name = name
        self.settings = []

    def add(self, setting):
        if isinstance(setting, Setting):
            self.settings.append(setting)
        else:
            raise TypeError('Can only add objects of type Setting')

    def retrieve(self, *sources):
        to_process = []
        for source in reversed(sources):
            if isinstance(source, Source):
                to_process.append(source)
            elif isinstance(source, type) and issubclass(source, Source):
                to_process.append(source())
            else:
                raise TypeError('All sources must be a Source')

        config = Configuration(settings=self.settings)
        for source in to_process:
            config = source.get_config(
                deepcopy(self.settings),
                manager=self,
                parent=config,
            )

        config.validate()

        return config
