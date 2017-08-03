import argparse
import shlex
import sys

from copy import deepcopy

from ..config import Configuration
from ..setting import BooleanSetting, ChoiceSetting, ListSetting
from .base import Source


__all__ = (
    'CommandLineSource',
)


# pylint: disable=R0201


class CommandLineSource(Source):
    # pylint: disable=R0913
    def __init__(
            self,
            arguments=None,
            options=None,
            version=None,
            parser_options=None,
            positional=None):
        super(CommandLineSource, self).__init__()

        if arguments is None:
            self.arguments = sys.argv[1:]
        elif isinstance(arguments, str):
            self.arguments = shlex.split(arguments)
        elif isinstance(arguments, (list, tuple)):
            self.arguments = arguments
        else:
            raise TypeError('arguments must be a string or list of strings')

        self.version = version
        self.options = options or {}
        self.parser_options = parser_options or {}
        self.positional = positional or ()

    def get_flags(self, setting):
        if setting.name in self.options:
            if 'flags' in self.options[setting.name]:
                return self.options[setting.name]['flags']

        flags = []
        flag = '--%s' % setting.name.lower().replace('_', '-')
        flags.append(flag)
        return flags

    def get_action(self, setting):
        if isinstance(setting, BooleanSetting):
            return 'store_false' if setting.default else 'store_true'
        elif isinstance(setting, ListSetting):
            return 'append'
        else:
            return 'store'

    # pylint: disable=W0613
    def get_default(self, setting):
        # Caveat: Returning something other than SUPPRESS probably won't
        # work the way you'd think.
        return argparse.SUPPRESS

    def get_type(self, setting):
        if isinstance(setting, (ListSetting, BooleanSetting)):
            return None
        elif isinstance(setting, ChoiceSetting):
            return setting.subtype.sanitize
        else:
            return setting.sanitize

    def get_dest(self, setting):
        return setting.name

    def get_choices(self, setting):
        if isinstance(setting, ChoiceSetting):
            return setting.choices
        else:
            return None

    def get_help(self, setting):
        if setting.name in self.options:
            if 'help' in self.options[setting.name]:
                return self.options[setting.name]['help']
        return None

    def get_metavar(self, setting):
        if setting.name in self.options:
            if 'metavar' in self.options[setting.name]:
                return self.options[setting.name]['metavar']
        return None

    def build_argument(self, setting):
        flags = self.get_flags(setting)
        action = self.get_action(setting)
        default = self.get_default(setting)
        argtype = self.get_type(setting)
        dest = self.get_dest(setting)
        choices = self.get_choices(setting)
        arghelp = self.get_help(setting)
        metavar = self.get_metavar(setting)

        argument_kwargs = {
            'action': action,
            'default': default,
            'dest': dest,
            'help': arghelp,
        }
        if argtype:
            argument_kwargs['type'] = argtype
        if choices:
            argument_kwargs['choices'] = choices
        if metavar:
            argument_kwargs['metavar'] = metavar

        return flags, argument_kwargs

    def build_parser(self, settings, manager):
        parser_options = deepcopy(self.parser_options)
        if not parser_options.get('prog') and manager:
            parser_options['prog'] = manager.name
        parser = argparse.ArgumentParser(**parser_options)

        add_version = (self.version is not None)

        for setting in settings:
            flags, argument_kwargs = self.build_argument(setting)
            parser.add_argument(*flags, **argument_kwargs)

            if add_version and setting.name == 'version':
                # Don't want to conflict with the desired setting
                add_version = False

        if add_version:
            parser.add_argument(
                '--version',
                action='version',
                version='%(prog)s ' + self.version,
            )

        if self.positional:
            for name, options in self.positional:
                parser.add_argument(name, **options)

        return parser

    def get_config(self, settings, manager=None, parent=None):
        parser = self.build_parser(settings, manager)
        parsed = parser.parse_args(self.arguments)

        for setting in settings:
            if hasattr(parsed, setting.name):
                setting.value = getattr(parsed, setting.name)

        if self.positional and manager:
            arguments = {}
            for name, _ in self.positional:
                if hasattr(parsed, name):
                    arguments[name] = getattr(parsed, name)
            setattr(manager, 'arguments', arguments)

        return Configuration(settings=settings, parent=parent)
