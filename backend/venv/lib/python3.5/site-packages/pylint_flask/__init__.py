'''pylint_flask module'''

from astroid import MANAGER
from astroid import nodes
import re


def register(_):
    '''register is expected by pylint for plugins, but we are creating a
    transform, not registering a checker.
    '''
    pass


def copy_node_info(src, dest):
    """Copy information from src to dest

    Every node in the AST has to have line number information.  Get
    the information from the old stmt."""
    for attr in ['lineno', 'fromlineno', 'tolineno',
                 'col_offset', 'parent']:
        if hasattr(src, attr):
            setattr(dest, attr, getattr(src, attr))


def mark_transformed(node):
    '''Mark a node as transformed so we don't process it multiple times.'''
    node.pylint_flask_was_transformed = True


def is_transformed(node):
    '''Return True if `node` was already transformed.'''
    return getattr(node, 'pylint_flask_was_transformed', False)


def make_non_magical_flask_import(flask_ext_name):
    '''Convert a flask.ext.admin into flask_admin.'''
    match = re.match(r'flask\.ext\.(.*)', flask_ext_name)
    if match is None:
        raise LookupError("Module name `{}` doesn't match"
                          "`flask.ext` style import.")
    from_name = match.group(1)
    actual_module_name = 'flask_{}'.format(from_name)
    return actual_module_name


def transform_flask_from_import(node):
    '''Translates a flask.ext from-style import into a non-magical import.

    Translates:
        from flask.ext import wtf, bcrypt as fcrypt
    Into:
        import flask_wtf as wtf, flask_bcrypt as fcrypt

    '''
    new_names = []
    # node.names is a list of 2-tuples. Each tuple consists of (name, as_name).
    # So, the import would be represented as:
    #
    #    from flask.ext import wtf as ftw, admin
    #
    # node.names = [('wtf', 'ftw'), ('admin', None)]
    for (name, as_name) in node.names:
        actual_module_name = 'flask_{}'.format(name)
        new_names.append((actual_module_name, as_name or name))

    new_node = nodes.Import()
    copy_node_info(node, new_node)
    new_node.names = new_names
    mark_transformed(new_node)
    return new_node


def is_flask_from_import(node):
    '''Predicate for checking if we have the flask module.'''
    # Check for transformation first so we don't double process
    return not is_transformed(node) and node.modname == 'flask.ext'

MANAGER.register_transform(nodes.From,
                           transform_flask_from_import,
                           is_flask_from_import)


def transform_flask_from_long(node):
    '''Translates a flask.ext.wtf from-style import into a non-magical import.

    Translates:
        from flask.ext.wtf import Form
        from flask.ext.admin.model import InlineFormAdmin
    Into:
        from flask_wtf import Form
        from flask_admin.model import InlineFormAdmin

    '''
    actual_module_name = make_non_magical_flask_import(node.modname)
    new_node = nodes.From(actual_module_name, node.names, node.level)
    copy_node_info(node, new_node)
    mark_transformed(new_node)
    return new_node


def is_flask_from_import_long(node):
    '''Check if an import is like `from flask.ext.wtf import Form`.'''
    # Check for transformation first so we don't double process
    return not is_transformed(node) and node.modname.startswith('flask.ext.')

MANAGER.register_transform(nodes.From,
                           transform_flask_from_long,
                           is_flask_from_import_long)


def transform_flask_bare_import(node):
    '''Translates a flask.ext.wtf bare import into a non-magical import.

    Translates:
        import flask.ext.admin as admin
    Into:
        import flask_admin as admin
    '''

    new_names = []
    for (name, as_name) in node.names:
        match = re.match(r'flask\.ext\.(.*)', name)
        from_name = match.group(1)
        actual_module_name = 'flask_{}'.format(from_name)
        new_names.append((actual_module_name, as_name))

    new_node = nodes.Import()
    copy_node_info(node, new_node)
    new_node.names = new_names
    mark_transformed(new_node)
    return new_node


def is_flask_bare_import(node):
    '''Check if an import is like `import flask.ext.admin as admin`.'''
    return (not is_transformed(node) and
            any(['flask.ext' in pair[0] for pair in node.names]))

MANAGER.register_transform(nodes.Import,
                           transform_flask_bare_import,
                           is_flask_bare_import)
