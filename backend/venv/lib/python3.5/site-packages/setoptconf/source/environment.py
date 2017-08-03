import os

from ..config import Configuration
from ..setting import ListSetting
from ..util import csv_to_list
from .base import Source


__all__ = (
    'EnvironmentVariableSource',
)


class EnvironmentVariableSource(Source):
    def __init__(self, prefix=None):
        super(EnvironmentVariableSource, self).__init__()
        self.prefix = prefix

    def get_config(self, settings, manager=None, parent=None):
        if manager and not self.prefix:
            self.prefix = manager.name

        for setting in settings:
            self.get_setting(setting)

        return Configuration(settings=settings, parent=parent)

    def get_setting(self, setting):
        name = setting.name
        if self.prefix:
            name = '%s_%s' % (self.prefix, name)
        name = name.upper()

        if name in os.environ:
            if isinstance(setting, ListSetting):
                setting.value = csv_to_list(os.environ[name])
            else:
                setting.value = os.environ[name]
