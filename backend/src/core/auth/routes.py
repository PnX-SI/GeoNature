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
        urlValidate = "%s?ticket=%s&service=%s"%(configCas['URL_VALIDATION'], params['ticket'], request.base_url)
        r = requests.get(urlValidate)
        user = None
        if r.status_code == 200:
            xmlDict = xmltodict.parse(r.content)
            resp = xmlDict['cas:serviceResponse']
            print(resp)
            if 'cas:user' in resp:
                user = resp['cas:user']
        print(user)
        if user:
            WSUserUrl = "%s/%s/?verify=false"%(configCas['USER_WS']['URL'], user)
            r  = requests.get(WSUserUrl, auth=(configCas['USER_WS']['ID'], configCas['USER_WS']['PASSWORD']))
            if r.status_code == 200:
                infoUser = r.json()
                print(infoUser)
                idOrganisme = infoUser.codeOrganisme
                currentUser = infoUser.prenom+" "+infoUser.nom
                response = make_response(redirect(current_app.config['URL_APPLICATION']))
                cookieExp = datetime.datetime.utcnow()
                cookieExp += datetime.timedelta(seconds=current_app.config['COOKIE_EXPIRATION'])
                response.set_cookie('token',
                                    'test12345',
                                    expires=cookieExp)
                response.set_cookie('idOrganisme',
                                     idOrganisme,
                                     expires=cookieExp)
                response.set_cookie('idOrganisme',
                                     currentUser,
                                     expires=cookieExp)
            return response
        else:
            # redirect to inpn
            requests.get(configCas['URL_LOGOUT'])
            urlRedirect = "%s?service=%s"%(configCas['URL_LOGIN'], request.base_url)
            return redirect(urlRedirect)
            