'''
GeoNature backend global configuration file
Don't change this
'''

import os


class Config():
    # Database
    SQLALCHEMY_DATABASE_URI = "postgresql://monuser:monpassachanger@localhost:monport/mondbname"
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Application
    PASS_METHOD = 'hash'                                    # Authentification password encoding method (hash or md5)
    DEBUG = True
    URL_APPLICATION = 'http://my_url.com/geonature'         # Replace my_url.com by your domain or IP
    API_ENDPOINT = 'http://my_url.com/geonature/api'        # Replace my_url.com by your domain or IP
    ID_APPLICATION_GEONATURE = 14                           # id_application of GeoNature in UsersHub
    SESSION_TYPE = 'filesystem'
    SECRET_KEY = 'super secret key'
    COOKIE_EXPIRATION = 7200
    COOKIE_AUTORENEW = True

    # CAS authentification (Optional, instead of UsersHub local authentification)
    CAS = {
        'URL_LOGIN': 'https://preprod-inpn.mnhn.fr/auth/login',
        'URL_LOGOUT': 'https://preprod-inpn.mnhn.fr/auth/logout',
        'URL_VALIDATION': 'https://preprod-inpn.mnhn.fr/auth/serviceValidate',
        'USER_WS': {
            'URL': 'https://inpn2.mnhn.fr/authentication/information',
            'ID': 'mon_id',
            'PASSWORD': 'mon_pass'
        }
    }

    # MTD
    XML_NAMESPACE = "{http://inpn.mnhn.fr/mtd}"
    MTD_API_ENDPOINT = "https://preprod-inpn.mnhn.fr/mtd"

    # File
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    UPLOAD_FOLDER = 'static/medias'
