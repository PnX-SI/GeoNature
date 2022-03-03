from collections import deque
from itertools import chain
from io import StringIO

import click
import flask_migrate
from alembic.migration import MigrationContext
from alembic.context import EnvironmentContext
from alembic.script import ScriptDirectory
from flask_migrate.cli import db as db_cli
from flask.cli import with_appcontext

from geonature.utils.env import db, migrate


def box_drowing(up, down, left, right):
    if   not up and not down and not left and not right:
        return '─'
    elif     up and not down and not left and not right:
        return '┸'
    elif not up and     down and not left and not right:
        return '┰'
    elif     up and     down and not left and not right:
        return '┃'
    elif     up and not down and     left and not right:
        return '┛'
    elif     up and not down and not left and     right:
        return '┗'
    elif not up and not down and     left and     right:
        return '━'
    elif not up and     down and     left and not right:
        return '┓'
    elif not up and     down and not left and     right:
        return '┏'
    elif     up and     down and not left and     right:
        return '┣'
    elif     up and     down and     left and not right:
        return '┫'
    elif     up and not down and     left and     right:
        return '┻'
    elif not up and     down and     left and     right:
        return '┳'
    elif     up and     down and     left and     right:
        return '╋'
    else:
        raise Exception("Unexpected box drowing symbol")


@db_cli.command()
@click.option('-d', '--directory', default=None,
              help=('Migration script directory (default is "migrations")'))
@click.option('--sql', is_flag=True,
              help=('Don\'t emit SQL to database - dump to standard output '
                    'instead'))
@click.option('--tag', default=None,
              help=('Arbitrary "tag" name - can be used by custom env.py '
                    'scripts'))
@click.option('-x', '--x-arg', multiple=True,
              help='Additional arguments consumed by custom env.py scripts')
@with_appcontext
def autoupgrade(directory, sql, tag, x_arg):
    config = migrate.get_config(directory, x_arg)
    script = ScriptDirectory.from_config(config)
    heads = set(script.get_heads())
    migration_context = MigrationContext.configure(db.session.connection())
    current_heads = migration_context.get_current_heads()
    # get_current_heads does not return implicit revision through dependecies, get_all_current does
    current_heads = set(map(lambda rev: rev.revision, script.get_all_current(current_heads)))
    for head in current_heads - heads:
        revision = head + '@head'
        flask_migrate.upgrade(directory, revision, sql, tag, x_arg)


@db_cli.command()
@click.option('-d', '--directory', default=None,
              help=('Migration script directory (default is "migrations")'))
@click.option('-x', '--x-arg', multiple=True,
              help='Additional arguments consumed by custom env.py scripts')
@with_appcontext
def status(directory, x_arg):
    """Show all revisions sorted by branches."""
    config = migrate.get_config(directory, x_arg)
    script = ScriptDirectory.from_config(config)
    migration_context = MigrationContext.configure(db.session.connection())

    current_heads = migration_context.get_current_heads()
    applied_rev = set(script.iterate_revisions(current_heads, 'base'))

    bases = [ script.get_revision(base) for base in script.get_bases() ]
    heads = [ script.get_revision(head) for head in script.get_heads() ]

    outdated = False
    for branch_base in sorted(bases, key=lambda rev: next(iter(rev.branch_labels))):
        output = StringIO()
        branch, = branch_base.branch_labels
        levels = { branch_base: 0 }
        branch_outdated = False
        seen = set()
        todo = deque()
        todo.append(branch_base)
        while todo:
            rev = todo.pop()

            current_level = levels[rev]
            down_revisions = rev.down_revision if rev.is_merge_point else [rev.down_revision] if rev.down_revision else []
            down_revisions = [ script.get_revision(r) for r in down_revisions ]

            next_revisions = [ script.get_revision(r) for r in rev.nextrev ]

            if rev.is_merge_point and not seen.issuperset(down_revisions):
                continue
            seen.add(rev)

            down_levels = []
            for j, downrev in enumerate(sorted(down_revisions, key=lambda rev: levels[rev])):
                if downrev.is_branch_point:
                    down_levels.append(current_level)
                else:
                    down_levels.append(levels[downrev])

            next_levels = []
            for j, nextrev in enumerate(next_revisions):
                if j == 0:
                    next_level = current_level
                else:
                    # TODO: reuse unused levels
                    next_level = max(levels.values()) + 1
                levels[nextrev] = next_level
                next_levels.append(next_level)
                todo.append(nextrev)

            all_levels = list(chain(down_levels, next_levels))
            min_level = min(all_levels, default=0)
            max_level = max(all_levels, default=0)
            symbol = ''
            for i in range(max_level + 1):
                if i < min_level:
                    symbol += ' '
                else:
                    symbol += box_drowing(
                        up = i in down_levels,
                        down = i in next_levels,
                        left = i > min_level,
                        right = i < max_level,
                    )

            check = 'x' if rev in applied_rev else ' '
            if branch_base in applied_rev and rev in applied_rev:
                fg = 'white'
            elif branch_base in applied_rev:
                outdated = True
                branch_outdated = True
                fg = 'red'
            else:
                fg = None
            print(click.style(f"  [{check}] {symbol} {rev.revision} {rev.doc}", fg=fg), file=output)

        if branch_base in applied_rev:
            fg = 'white'
            mark = ' '
            mark += click.style('×', fg='red') if branch_outdated else click.style('✓', fg='green')
        else:
            fg = None
            mark = ''
        click.echo(click.style(f"[{branch}", bold=True, fg=fg) + mark + click.style("]", bold=True, fg=fg))
        click.echo(output.getvalue(), nl=False)

    if outdated:
        click.secho("Some branches are outdated, you can upgrade with: geonature db autoupgrade", fg="red")
