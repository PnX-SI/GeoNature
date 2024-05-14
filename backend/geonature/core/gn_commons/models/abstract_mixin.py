from .base import TModules
import abc


class AbstractMixin(abc.ABC):
    _module: TModules = None

    def __init__(self, module: TModules) -> None:
        self._module = module

    @classmethod
    def is_implemented_in_module(cls, module: TModules) -> bool:
        return isinstance(module, cls)
