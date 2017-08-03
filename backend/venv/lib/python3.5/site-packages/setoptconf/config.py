from .exception import MissingRequiredError, ReadOnlyError
from .util import UnicodeMixin


__all__ = (
    'Configuration',
)


class Configuration(UnicodeMixin):
    def __init__(self, settings, parent=None):
        self.__dict__['_parent'] = parent

        self.__dict__['_settings'] = {}
        for setting in settings:
            self._settings[setting.name] = setting

    def validate_setting(self, name):
        if name in self._settings:
            setting = self._settings[name]
            if setting.required and not setting.established:
                if self._parent:
                    self._parent.validate_setting(name)
                else:
                    raise MissingRequiredError(name)
        elif self._parent:
            self._parent.validate_setting(name)
        else:
            raise AttributeError('No such setting "%s"' % name)

    def validate(self):
        for name in self:
            self.validate_setting(name)

    def __getattr__(self, name):
        if name in self._settings:
            if self._settings[name].established:
                return self._settings[name].value
            elif self._parent:
                return getattr(self._parent, name)
            else:
                return self._settings[name].default
        elif self._parent:
            return getattr(self._parent, name)
        else:
            raise AttributeError('No such setting "%s"' % name)

    def __getitem__(self, key):
        return getattr(self, key)

    def __setattr__(self, name, value):
        raise ReadOnlyError('Cannot change the value of settings')

    def __setitem__(self, key, value):
        setattr(self, key, value)

    def __delattr__(self, name):
        raise ReadOnlyError('Cannot delete settings')

    def __delitem__(self, key):
        delattr(self, key)

    def __iter__(self):
        all_names = set(self._settings.keys())
        if self._parent:
            all_names.update(iter(self._parent))
        return iter(all_names)

    def __len__(self):
        return len(list(iter(self)))

    def __contains__(self, item):
        return item in list(iter(self))

    def __unicode__(self):  # pragma: no cover
        return 'Configuration(%s)' % (
            ', '.join([
                '%s=%s' % (name, repr(self[name]))
                for name in self
            ])
        )

    def __repr__(self):  # pragma: no cover
        return '<%s>' % str(self)
