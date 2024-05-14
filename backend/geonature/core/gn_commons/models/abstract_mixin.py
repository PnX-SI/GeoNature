from .base import TModules
import abc
import typing


class AbstractMixin(abc.ABC):
    _module: TModules = None

    def __init__(self, module: TModules) -> None:
        self._module = module

    @classmethod
    def is_implemented_in_module(cls, module_type: typing.Type) -> bool:
        return issubclass(module_type, cls)
