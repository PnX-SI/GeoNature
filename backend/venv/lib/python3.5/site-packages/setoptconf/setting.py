
# pylint: disable=W0401,W0223

import re

from .datatype import *
from .exception import NamingError
from .util import UnicodeMixin


__all__ = (
    'Setting',
    'StringSetting',
    'IntegerSetting',
    'FloatSetting',
    'BooleanSetting',
    'ListSetting',
    'ChoiceSetting',
)


class Setting(UnicodeMixin, DataType):
    RE_NAME = re.compile(r'^[a-z](?:[a-z0-9]|[_](?![_]))*[a-z0-9]$')

    def __init__(self, name, default=None, required=False):
        if Setting.RE_NAME.match(name):
            self.name = name
        else:
            raise NamingError(name)

        self._value = None
        self.default = self.sanitize(default)
        self.required = required
        self.established = False

    @property
    def value(self):
        return self._value

    @value.setter
    def value(self, value):
        self._value = self.sanitize(value)
        self.established = True

    def __unicode__(self):  # pragma: no cover
        return str(self.name)

    def __repr__(self):  # pragma: no cover
        return '<%s(%s=%s)>' % (
            self.__class__.__name__,
            self.name,
            self.value if self.established else '',
        )


class StringSetting(Setting, String):
    pass


class IntegerSetting(Setting, Integer):
    pass


class FloatSetting(Setting, Float):
    pass


class BooleanSetting(Setting, Boolean):
    pass


class ListSetting(Setting, List):
    def __init__(self, name, subtype, **kwargs):
        List.__init__(self, subtype)
        Setting.__init__(self, name, **kwargs)


class ChoiceSetting(Setting, Choice):
    def __init__(self, name, choices, subtype=None, **kwargs):
        Choice.__init__(self, choices, subtype=subtype)
        Setting.__init__(self, name, **kwargs)
