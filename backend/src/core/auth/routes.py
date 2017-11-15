# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request, make_response, url_for, redirect, current_app
import requests
import datetime
import xmltodict
from xml.etree import ElementTree as ET

from ...utils.utilssqlalchemy import json_resp

from flask_sqlalchemy import SQLAlchemy
db = SQLAlchemy()

### Module d'identificiation provisoire pour test du CAS INPN ###

routes = Blueprint('test_auth', __name__)


@routes.route('/login_cas', methods=['GET'])
def loginCas():
    configCas = current_app.config['CAS']
    params = request.args
    if 'ticket' in params:
        base_url = current_app.config['URL_API']+"/test_auth/login_cas"
        urlValidate = "%s?ticket=%s&service=%s"%(configCas['URL_VALIDATION'], params['ticket'], base_url)
        r = requests.get(urlValidate)
        user = None
        if r.status_code == 200:
            xmlDict = xmltodict.parse(r.content)
            resp = xmlDict['cas:serviceResponse']
            if 'cas:authenticationSuccess' in resp:
                user = resp['cas:authenticationSuccess']['cas:user']
        if user:
            WSUserUrl = "%s/%s/?verify=false"%(configCas['USER_WS']['URL'], user)
            r  = requests.get(WSUserUrl, auth=(configCas['USER_WS']['ID'], configCas['USER_WS']['PASSWORD']))
            if r.status_code == 200:
                infoUser = r.json()
                idOrganisme = infoUser['codeOrganisme']
                currentUser = infoUser['prenom']+" "+infoUser['nom']
                response = make_response(redirect(current_app.config['URL_APPLICATION']+"/login"))
                cookieExp = datetime.datetime.utcnow()
                cookieExp += datetime.timedelta(seconds=current_app.config['COOKIE_EXPIRATION'])
                response.set_cookie('token',
                                    'test12345',
                                    expires=cookieExp)
                response.set_cookie('idOrganisme',
                                     str(idOrganisme),
                                     expires=cookieExp)
                response.set_cookie('currentUser',
                                     currentUser,
                                     expires=cookieExp)
            return response
        else:
            # redirect to inpn            
            return "echec de l'authentification"
            