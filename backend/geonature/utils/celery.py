from celery import Celery
import flask
from geonature.utils.env import db


class FlaskCelery(Celery):

    def __init__(self, *args, **kwargs):

        super(FlaskCelery, self).__init__(*args, **kwargs)
        self.patch_task()

        if "app" in kwargs:
            self.init_app(kwargs["app"])

    def patch_task(self):
        TaskBase = self.Task
        _celery = self

        class ContextTask(TaskBase):
            abstract = True

            def __call__(self, *args, **kwargs):
                if hasattr(_celery, "app"):
                    with _celery.app.app_context():
                        # No need for db.session.remove() since it is automatically closed
                        # by flask-sqlalchemy when exit the app context created
                        return TaskBase.__call__(self, *args, **kwargs)
                else:
                    return TaskBase.__call__(self, *args, **kwargs)

        self.Task = ContextTask

    def init_app(self, app):
        self.app = app
        self.config_from_object(app.config)


celery_app = FlaskCelery("geonature")
