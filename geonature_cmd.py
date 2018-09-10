#!/usr/bin/env python3

"""
    Main entry point to manage a geonature project.

    Use it only after having installed geonature, and once the geonature
    virtualenv is activated.

    To get some help: python geonature.py --help.

    The install process should make this command always available anywhere
    as long as the virtualenv is activated as just "geonature".
"""

import sys

try:
    from pathlib import Path
except ImportError:
    sys.exit(
        'GeoNature requires Python 3.5 or higher. Check that you have '
        'installed GeoNature and that you have activated the GeoNature '
        'virtualenv.'
    )

# Add backend dir in the PYTHONPATH so that we can import the "geonature"
# module
BACKEND_DIR = Path(__file__).absolute().parent / "backend"
sys.path.insert(0, str(BACKEND_DIR))

import geonature.core.command  # pylint: disable=E0401,C0413

geonature.core.command.main()
