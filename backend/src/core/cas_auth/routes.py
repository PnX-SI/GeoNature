from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

routes = Blueprint('cas_auth', __name__)

@routes.route('/redirect', methods=['GET'])
def redirect():
    return 'yolo'