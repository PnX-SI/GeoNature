# coding: utf8

from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

"""
    Command line tools to initialize the database.
"""

import sys
import argparse

import sqlalchemy

from pypnusershub.db.tools import (init_schema, delete_schema, load_fixtures)


def run_db_cmd(func, db_uri, *args, **kwargs):
    """ Run a function from pypnuserhub.db.tools with proper warnings """
    try:
        func(db_uri, *args, **kwargs)
    except sqlalchemy.exc.ArgumentError as e:
        sys.exit('Unable to use the passed URI strings: %s' % e)
    except sqlalchemy.exc.OperationalError as e:
        if "authentication failed" in str(e):
            sys.exit(("Unable to authenticate to '%s'. "
                      "Make sure to either provide a proper user/password "
                      "or execute this command as PostGreSQL "
                      "admin user (E.G: 'postgres') ") % db_uri)
        raise
    print('Done')


# Wrap all calls to pypnuserhub.db.tools's function in run_db_cmd
# to have good warning messages.
def call_init_schema(args):
    print('Initializing schema')
    run_db_cmd(init_schema, args.db_uri)


def call_delete_schema(args):
    confirm = input("This will delete all the content of "
                    " the 'utilisateurs' db. Are you sure ? [N/y] ")
    if confirm != "y":
        print('Abort')
        sys.exit(0)

    print('Deleting schema')
    run_db_cmd(delete_schema, args.db_uri)


def call_reset_schema(args):
    call_delete_schema(args)
    call_init_schema(args)


def call_load_fixtures(args):
    print('Loading fixtures')
    run_db_cmd(load_fixtures, args.db_uri)


def make_cmd_parser():
    """ Create a CMD parser with subcommands for pypnuserhub.db.tools funcs"""
    parser = argparse.ArgumentParser('python -m pypnuserhub')

    parser.set_defaults(func=lambda x: parser.print_usage(sys.stderr))

    subparsers = parser.add_subparsers()

    parser_init_schema = subparsers.add_parser('init_schema')
    parser_init_schema.add_argument('db_uri', type=str)
    parser_init_schema.set_defaults(func=call_init_schema)

    parser_delete_schema = subparsers.add_parser('delete_schema')
    parser_delete_schema.add_argument('db_uri', type=str)
    parser_delete_schema.set_defaults(func=call_delete_schema)

    parser_reset_schema = subparsers.add_parser('reset_schema')
    parser_reset_schema.add_argument('db_uri', type=str)
    parser_reset_schema.set_defaults(func=call_reset_schema)

    parser_load_fixture = subparsers.add_parser('load_fixtures')
    parser_load_fixture.add_argument('db_uri', type=str)
    parser_load_fixture.set_defaults(func=call_load_fixtures)

    return parser


if __name__ == '__main__':
    parser = make_cmd_parser()
    args = parser.parse_args()
    args.func(args)
