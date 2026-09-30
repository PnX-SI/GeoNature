"""
Namespace package for user-provided plugins (e.g. custom authentication providers).

Extends this package's search path to look inside ``custom/python/`` at the repo root.
A file placed at e.g. ``custom/python/providers/my_provider.py`` becomes
importable as ``geonature.plugins.providers.my_provider``.
"""

from geonature.utils.env import CUSTOM_PYTHON_DIR

if CUSTOM_PYTHON_DIR.is_dir():
    __path__.append(str(CUSTOM_PYTHON_DIR))
