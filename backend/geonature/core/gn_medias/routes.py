# @TODO
# POST /upload_file
# DELETE /upload_file

from flask import Blueprint, request

from geonature.core.gn_medias.repositories import TMediaRepository

from geonature.utils.utilssqlalchemy import json_resp

routes = Blueprint('gn_medias', __name__)


@routes.route('/upload_file', methods=['POST'])
@json_resp
def upload_file():
    if request.files:
        file = request.files['file']
        data = {}
        if request.form:
            formData = dict(request.form)
            for key in formData:
                data[key] = formData[key][0]
        else:
            data = request.get_json(silent=True)

    m = TMediaRepository().save(data, file)
    return m.as_dict()
