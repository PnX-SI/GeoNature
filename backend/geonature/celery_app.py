from .app import create_app
from .utils.celery import celery_app as app
from .utils.module import iter_modules_dist


flask_app = create_app()


class ContextTask(app.Task):
    def __call__(self, *args, **kwargs):
        with flask_app.app_context():
            return self.run(*args, **kwargs)


app.Task = ContextTask

app.conf.imports += ("geonature.tasks",)
app.conf.imports += tuple(
    [ep.module for dist in iter_modules_dist() for ep in dist.entry_points.select(name="tasks")]
)
