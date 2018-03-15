'''
    Route permettant de manipuler les fichiers
    contenus dans gn_media
'''

from flask import Blueprint, request

from geonature.core.gn_medias.repositories import TMediaRepository

from geonature.utils.utilssqlalchemy import json_resp

routes = Blueprint('gn_medias', __name__)


@routes.route('/<int:id_media>', methods=['GET'])
@json_resp
def get_media(id_media):
    '''
        Retourne un media
    '''
    m = TMediaRepository(id_media=id_media).media
    return m.as_dict()


@routes.route('/', methods=['POST', 'PUT'])
@routes.route('/<int:id_media>', methods=['POST', 'PUT'])
@json_resp
def insert_or_update_media(id_media=None):
    '''
        Insertion ou mise à jour d'un média
        avec prise en compte des fichiers joints
    '''
    if request.files:
        file = request.files['file']
    else:
        file = None

    data = {}
    if request.form:
        formData = dict(request.form)
        for key in formData:
            data[key] = formData[key][0]
    else:
        data = request.get_json(silent=True)

    m = TMediaRepository(
        data=data, file=file, id_media=id_media
    ).create_or_update_media()
    return m.as_dict()


@routes.route('/<int:id_media>', methods=['DELETE'])
@json_resp
def delete_media(id_media):
    '''
        Suppression d'un media
    '''
    TMediaRepository(id_media=id_media).delete()
    return {"resp": "media {} deleted".format(id_media)}
