from ..config import Configuration
from .base import Source


__all__ = (
    'MappingSource',
)


class MappingSource(Source):
    def __init__(self, target):
        super(MappingSource, self).__init__()
        self.target = target

    def get_config(self, settings, manager=None, parent=None):
        for setting in settings:
            if setting.name in self.target:
                setting.value = self.target[setting.name]

        return Configuration(settings=settings, parent=parent)
