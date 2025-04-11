from .app import create_app
from .utils.celery import celery_app as app
from .utils.module import iter_modules_dist
from .utils.env import db


flask_app = create_app()


class ContextTask(app.Task):
    def __call__(self, *args, **kwargs):
        with flask_app.app_context():
            result = self.run(*args, **kwargs)
            db.session.remove()
        return result


app.Task = ContextTask

app.conf.imports += ("geonature.tasks",)
app.conf.imports += tuple(
    [ep.module for dist in iter_modules_dist() for ep in dist.entry_points.select(name="tasks")]
)
