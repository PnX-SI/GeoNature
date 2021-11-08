# coding: utf8

from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

"""
    Collections of utilities unrelated to the main module purpose.
"""

import os
import io

from types import ModuleType


class RessourceError(EnvironmentError):

    def __init__(self, msg, errors):
        super(RessourceError, self).__init__(msg)
        self.errors = errors


def binary_resource_stream(resource, locations):
    """ Return a resource from this path or package """

    # convert
    errors = []

    # If location is a string or a module, we wrap it in a tuple
    if isinstance(locations, (str, ModuleType)):
        locations = (locations,)

    for location in locations:

        # Assume location is a module and try to load it using pkg_resource
        try:
            import pkg_resources
            module_name = getattr(location, '__name__', location)
            return pkg_resources.resource_stream(module_name, resource)
        except (ImportError, EnvironmentError) as e:
            errors.append(e)

            # Falling back to load it from path.
            try:
                # location is a module
                module_path = __import__(location).__file__
                parent_dir = os.path_dirname(module_path)
            except (AttributeError, ImportError):
                # location is a dir path
                parent_dir = os.path.realpath(location)

            # Now we got a resource full path. Just open it as a regular file.
            canonical_path = os.path.join(parent_dir, resource)
            try:
                return open(os.path.join(canonical_path), mode="rb")
            except EnvironmentError as e:
                errors.append(e)

    msg = ('Unable to find resource "%s" in "%s". '
           'Inspect RessourceError.errors for list of encountered errors.')
    raise RessourceError(msg % (resource, locations), errors)


def text_resource_stream(path, locations, encoding="utf8", errors=None,
                         newline=None, line_buffering=False):
    """ Return a resource from this path or package. Transparently decode the stream. """
    stream = binary_resource_stream(path, locations)
    return io.TextIOWrapper(stream, encoding, errors, newline, line_buffering)
