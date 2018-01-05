# coding: utf8


class Config():
    '''
    Fichier de configuration générale de l'application
    '''

    SQLALCHEMY_DATABASE_URI = "postgresql://monuser:monpassachanger@localhost:monport/mondbname"
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    PASS_METHOD='hash'
    DEBUG=True
    URL_APPLICATION = 'http://my_url.com/geonature' 
    API_ENDPOINT = 'http://my_url.com/geonature/api'
    ID_APPLICATION_GEONATURE = 14
    SESSION_TYPE = 'filesystem'
    SECRET_KEY = 'super secret key'
    COOKIE_EXPIRATION = 7200
    COOKIE_AUTORENEW = True


    #CAS
    CAS = {
    'URL_LOGIN': 'https://preprod-inpn.mnhn.fr/auth/login',
    'URL_LOGOUT': 'https://preprod-inpn.mnhn.fr/auth/logout',
    'URL_VALIDATION' : 'https://preprod-inpn.mnhn.fr/auth/serviceValidate',
    'USER_WS': {
        'URL': 'https://preprod-inpn2.mnhn.fr/authentication/information',
        'ID': 'user1',
        'PASSWORD': 'password1'
    } 
    }

    #File
    import os
    BASE_DIR = os.path.abspath(os.path.dirname(__file__))
    UPLOAD_FOLDER = 'static/medias'
