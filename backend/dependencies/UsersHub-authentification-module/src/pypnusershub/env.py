from os import environ
from importlib import import_module
from flask_marshmallow import Marshmallow
from flask_sqlalchemy import SQLAlchemy

db_path = environ.get('FLASK_SQLALCHEMY_DB')
if db_path:
    db_module_name, db_object_name = db_path.rsplit('.', 1)
    db_module = import_module(db_module_name)
    db = getattr(db_module, db_object_name)
else:
    db = SQLAlchemy()

marsmallow_path = environ.get('FLASK_MARSHMALLOW')
if marsmallow_path:
    ma_module_name, ma_object_name = marsmallow_path.rsplit('.', 1)
    ma_module = import_module(ma_module_name)
    MA = getattr(ma_module, ma_object_name)
else:
    MA = Marshmallow()

# Dictionnaire des post actions
#  Fonctions qui sont lancées lors de l'appel
#  à la route post_usershub/<mon_action>
REGISTER_POST_ACTION_FCT = {}
