from .exception import DataTypeError


__all__ = (
    'DataType',
    'String',
    'Integer',
    'Float',
    'Boolean',
    'List',
    'Choice',
)


class DataType(object):
    def sanitize(self, value):
        raise NotImplementedError()

    def is_valid(self, value):
        try:
            self.sanitize(value)
        except DataTypeError:
            return False
        else:
            return True


class String(DataType):
    def sanitize(self, value):
        if value is not None:
            value = str(value)
        return value


class Integer(DataType):
    def sanitize(self, value):
        if value is not None:
            try:
                value = int(value)
            except:
                raise DataTypeError('"%s" is not valid Integer' % value)
        return value


class Float(DataType):
    def sanitize(self, value):
        if value is not None:
            try:
                value = float(value)
            except:
                raise DataTypeError('"%s" is not valid Float' % value)
        return value


class Boolean(DataType):
    TRUTHY_STRINGS = ('Y', 'YES', 'T', 'TRUE', 'ON', '1')
    FALSY_STRINGS = ('', 'N', 'NO', 'F', 'FALSE', 'OFF', '0')

    def sanitize(self, value):
        if value is None or isinstance(value, bool):
            return value

        if isinstance(value, int):
            return True if value else False

        if isinstance(value, str) and value:
            value = value.strip().upper()
            if value in self.TRUTHY_STRINGS:
                return True
            elif value in self.FALSY_STRINGS:
                return False
            else:
                raise DataTypeError(
                    'Could not coerce "%s" to a Boolean' % (
                        value,
                    )
                )

        return True if value else False


class List(DataType):
    def __init__(self, subtype):
        super(List, self).__init__()
        if isinstance(subtype, DataType):
            self.subtype = subtype
        elif isinstance(subtype, type) and issubclass(subtype, DataType):
            self.subtype = subtype()
        else:
            raise TypeError('subtype must be a DataType')

    def sanitize(self, value):
        if value is None:
            return value

        if not isinstance(value, (list, tuple)):
            value = [value]

        value = [
            self.subtype.sanitize(v)
            for v in value
        ]

        return value


class Choice(DataType):
    def __init__(self, choices, subtype=None):
        super(Choice, self).__init__()

        subtype = subtype or String()
        if isinstance(subtype, DataType):
            self.subtype = subtype
        elif isinstance(subtype, type) and issubclass(subtype, DataType):
            self.subtype = subtype()
        else:
            raise TypeError('subtype must be a DataType')

        self.choices = choices

    def sanitize(self, value):
        if value is None:
            return value

        value = self.subtype.sanitize(value)

        if value not in self.choices:
            raise DataTypeError(
                '"%s" is not one of (%s)' % (
                    value,
                    ', '.join([repr(c) for c in self.choices]),
                )
            )

        return value
