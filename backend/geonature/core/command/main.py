

"""
    Entry point for the command line used in geonature_cmd.py
"""

import logging

import click

from geonature.utils.env import (
    virtualenv_status,
    DEFAULT_VIRTUALENV_DIR,
    install_geonature_command,
    GEONATURE_VERSION,
    create_frontend_config
)

log = logging.getLogger(__name__)


@click.group()
@click.version_option(version=GEONATURE_VERSION)
@click.pass_context
def main(ctx):
    """ Group all the subcommands """

    # Make sure nobody run this script by mistake before installing
    # geonature properly. We should be most of the time in a venv, unless
    # people really know what they are doing.
    in_virtualenv, allow_no_virtualenv = virtualenv_status()
    if not in_virtualenv:

        if not allow_no_virtualenv:
            ctx.fail((
                'You must be in the GeoNature virtualenv to be able to run '
                'this script. The virtualenv is made available once GeoNature '
                "has been installed and it's default directory is '{0}'. You "
                'can activate it by doing "source {0}/activate/bin/activate". '
                'If you installed GeoNature outside of a virtualenv, you can '
                'bypass this check by setting the GEONATURE_NO_VIRTUALENV '
                'env var to 1. How ever, this setupis not officially '
                'supported by the GeoNature team.'
            ).format(DEFAULT_VIRTUALENV_DIR))

        log.warning(
            'Running with "GEONATURE_NO_VIRTUALENV=1". This setup may work, '
            'but is not officially supported by the GeoNature team.'
        )


@main.command()
@click.pass_context
def install_command(ctx):
    """ Install an alias of geonature_cmd.py in the current virtualenv bin dir.

        This way it can be used anywhere as "geonature" as long as the
        virtualenv is activated.
    """

    try:
        install_geonature_command()
    except EnvironmentError:
        ctx.fail((
            'You must be in the GeoNature virtualenv to be able to run '
            'this script. The virtualenv is made available once GeoNature '
            "has been installed and it's default directory is '{0}'. You "
            'can activate it by doing "source {0}/activate/bin/activate". '
            'If you installed GeoNature outside of a virtualenv, you should '
            'stick to using "python geonature_cmd.py" manually.'
        ).format(DEFAULT_VIRTUALENV_DIR))


@main.command()
@click.option(
    '--conf_file'
)
def generate_frontend_config(conf_file):
    """
        Génération des fichiers de configurations pour javascript
    """
    create_frontend_config(conf_file)

