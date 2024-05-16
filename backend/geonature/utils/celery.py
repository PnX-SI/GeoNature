from celery import Celery, Task
from geonature.utils.env import db
from geonature.utils.config import config
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker, scoped_session


class SQLASessionTask(Task):
    def __init__(self):
        self.sessions = {}

    def before_start(self, task_id, args, kwargs):
        engine = create_engine(
            config["SQLALCHEMY_DATABASE_URI"],
        )
        session_factory = sessionmaker(bind=engine)
        session = scoped_session(session_factory)
        db.session = session
        self.sessions[task_id] = session
        super().before_start(task_id, args, kwargs)

    def after_return(self, status, retval, task_id, args, kwargs, einfo):
        session = self.sessions.pop(task_id)
        session.close()
        super().after_return(status, retval, task_id, args, kwargs, einfo)

    @property
    def session(self):
        return self.sessions[self.request.id]


celery_app = Celery("geonature", task_cls=SQLASessionTask)
