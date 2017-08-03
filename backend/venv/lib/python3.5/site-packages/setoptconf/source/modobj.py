import types

from ..config import Configuration
from .base import Source


__all__ = (
    'ModuleSource',
    'ObjectSource',
)


class ModuleSource(Source):
    def __init__(self, target):
        super(ModuleSource, self).__init__()

        if isinstance(target, types.ModuleType):
            self.target = target
        elif isinstance(target, str):
            self.target = __import__(target, globals(), locals(), [], -1)
        else:
            raise TypeError(
                'target must be a Module or a String naming a Module'
            )

    def get_config(self, settings, manager=None, parent=None):
        for setting in settings:
            if hasattr(self.target, setting.name):
                setting.value = getattr(self.target, setting.name)

        return Configuration(settings=settings, parent=parent)


class ObjectSource(Source):
    def __init__(self, target):
        super(ObjectSource, self).__init__()

        if isinstance(target, (type, object)):
            self.target = target
        elif isinstance(target, str):
            parts = target.rsplit('.', 2)
            if len(parts) == 2:
                mod = parts[0]
                fromlist = [parts[1]]
            else:
                mod = parts[0]
                fromlist = []
            self.target = __import__(mod, globals(), locals(), fromlist, -1)
        else:
            raise TypeError(
                'target must be an Object or a String naming an Object'
            )

    def get_config(self, settings, manager=None, parent=None):
        for setting in settings:
            if hasattr(self.target, setting.name):
                setting.value = getattr(self.target, setting.name)

        return Configuration(settings=settings, parent=parent)
