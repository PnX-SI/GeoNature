from astroid import MANAGER
from astroid.builder import AstroidBuilder
from astroid import nodes


def register(_):
    # this method is expected by pylint for plugins, however we don't
    # want to register any checkers
    pass


MODULE_TRANSFORMS = {}


def transform(module):
    try:
        tr = MODULE_TRANSFORMS[module.name]
    except KeyError:
        pass
    else:
        tr(module)
MANAGER.register_transform(nodes.Module, transform)


def celery_transform(module):
    fake = AstroidBuilder(MANAGER).string_build('''
class task_dummy(object):
    def __call__(self):
        pass
''')
    module.locals['task'] = fake.locals['task_dummy']


MODULE_TRANSFORMS['celery'] = celery_transform
