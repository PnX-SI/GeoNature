
'''
Fichier de configuration générale de l'application
'''

SQLALCHEMY_DATABASE_URI = "postgresql://geonatuser:test@localhost:5432/geonaturedb"
SQLALCHEMY_TRACK_MODIFICATIONS = False


DEBUG=True

URL_APPLICATION = 'http://127.0.0.1/geonature' 
URL_API = 'http://127.0.0.1/api'
ID_APPLICATION_GEONATURE = 14
SESSION_TYPE = 'filesystem'
SECRET_KEY = 'super secret key'
COOKIE_EXPIRATION = 7200
COOKIE_AUTORENEW = True

CAS = {
  'URL_LOGIN': 'URL_LOGIN',
  'URL_LOGOUT': 'URL_LOGOUT',
  'URL_VALIDATION' : 'URL_VALIDATION',
  'USER_WS': {
    'URL': 'URL_WS',
    'ID': 'MY_ID',
    'PASSWORD': 'MY_PASS'
  } 
}

#File
import os
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
UPLOAD_FOLDER = 'static/medias'
