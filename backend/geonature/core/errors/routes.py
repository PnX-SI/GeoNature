#coding: utf8

from flask import current_app
from flask_sqlalchemy import SQLAlchemy
from ...utils.utilssqlalchemy import json_resp
db = SQLAlchemy()

@current_app.errorhandler(500)
@json_resp
def internal_error(error):
    db.session.rollback()
    return {'message': 'internal server error'}, 500
