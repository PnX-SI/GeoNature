from .base import TModules
import typing


class AbstractMixin:
    _module: TModules = None

    def __init__(self, module: TModules) -> None:
        self._module = module

    @classmethod
    def is_implemented_in_module(cls, module_type: typing.Type) -> bool:
        return issubclass(module_type, cls)
