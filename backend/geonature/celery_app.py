from pkg_resources import iter_entry_points

from .app import create_app
from .utils.celery import celery_app as app


flask_app = create_app()


class ContextTask(app.Task):
    def __call__(self, *args, **kwargs):
        with flask_app.app_context():
            return self.run(*args, **kwargs)


app.Task = ContextTask

app.conf.imports += tuple(ep.module_name for ep in iter_entry_points("gn_module", "tasks"))
