
__all__ = (
    'SetOptConfError',
    'NamingError',
    'DataTypeError',
    'MissingRequiredError',
    'ReadOnlyError',
)


class SetOptConfError(Exception):
    pass


class NamingError(SetOptConfError):
    pass


class DataTypeError(SetOptConfError):
    pass


class MissingRequiredError(SetOptConfError):
    pass


class ReadOnlyError(SetOptConfError):
    pass
