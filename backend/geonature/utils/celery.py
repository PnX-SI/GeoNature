from celery import Celery, Task
from geonature.utils.env import db
from geonature.utils.config import config
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session

import flask
from flask_sqlalchemy import SQLAlchemy


class SQLASessionTask(Task):
    def __init__(self):
        self.sessions = {}

    def before_start(self, task_id, args, kwargs):
        engine = create_engine(
            config["SQLALCHEMY_DATABASE_URI"],
        )
        session_factory = sessionmaker(bind=engine)
        self.sessions[task_id] = scoped_session(session_factory)
        super().before_start(task_id, args, kwargs)

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        session = self.sessions.pop(task_id)
        session.close()
        super().after_return(status, retval, task_id, args, kwargs, einfo)


class FlaskCelery(Celery):

    def __init__(self, *args, **kwargs):

        super(FlaskCelery, self).__init__(*args, **kwargs)
        self.patch_task()

        if "app" in kwargs:
            self.init_app(kwargs["app"])

    def patch_task(self):
        _celery = self

        class ContextTask(SQLASessionTask):
            abstract = True

            def __call__(self, *args, **kwargs):
                if flask.has_app_context():
                    return SQLASessionTask.__call__(self, *args, **kwargs)
                else:
                    with _celery.app.app_context():
                        return SQLASessionTask.__call__(self, *args, **kwargs)

        self.Task = ContextTask

    def init_app(self, app):
        self.app = app
        self.config_from_object(app.config)


celery_app = FlaskCelery("geonature")
