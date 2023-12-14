"""
    Route permettant de manipuler les fichiers
    contenus dans gn_media
"""
from flask import request, redirect, jsonify
from werkzeug.exceptions import NotFound

from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.models import TMedias
from geonature.utils.env import DB
from utils_flask_sqla.response import json_resp, json_resp_accept_empty_list


from ..routes import routes


@routes.route("/medias/<string:uuid_attached_row>", methods=["GET"])
@json_resp_accept_empty_list
def get_medias(uuid_attached_row):
    """
    Retourne des medias
    .. :quickref: Commons;
    """

    res = DB.session.scalars(
        DB.select(TMedias).where(TMedias.uuid_attached_row == uuid_attached_row)
    ).all()
    return [r.as_dict() for r in (res or [])]


@routes.route("/media/<int:id_media>", methods=["GET"])
def get_media(id_media):
    """
    Retourne un media
    .. :quickref: Commons;
    """

    media = TMediaRepository(id_media=id_media).media
    if not media:
        raise NotFound
    return jsonify(media.as_dict())


@routes.route("/media", methods=["POST", "PUT"])
@routes.route("/media/<int:id_media>", methods=["POST", "PUT"])
@json_resp
def insert_or_update_media(id_media=None):
    """
    Insertion ou mise à jour d'un média
    avec prise en compte des fichiers joints

    .. :quickref: Commons;
    """

    # gestion des parametres de route
    # @TODO utilisé quelque part ?
    if request.files:
        file = request.files["file"]
    else:
        file = None

    data = {}
    # Useful ? @jacquesfize YES ! -> used when add media when adding a taxon occurrence
    if request.form:
        formData = dict(request.form)
        for key in formData:
            data[key] = formData[key]
            if data[key] in ["null", "undefined"]:
                data[key] = None
            if isinstance(data[key], list):
                data[key] = data[key][0]
            if (
                key in ["id_table_location", "id_nomenclature_media_type", "id_media"]
                and data[key] is not None
            ):
                data[key] = int(data[key])
            if data[key] == "true":
                data[key] = True
            if data[key] == "false":
                data[key] = False

    else:
        data = request.get_json(silent=True)

    m = TMediaRepository(data=data, file=file, id_media=id_media).create_or_update_media()

    return m.as_dict()


@routes.route("/media/<int:id_media>", methods=["DELETE"])
@json_resp
def delete_media(id_media):
    """
    Suppression d'un media

    .. :quickref: Commons;
    """

    TMediaRepository(id_media=id_media).delete()

    return {"resp": "media {} deleted".format(id_media)}


@routes.route("/media/thumbnails/<int:id_media>/<int:size>", methods=["GET"])
def get_media_thumb(id_media, size):
    """
    Retourne le thumbnail d'un media
    .. :quickref: Commons;
    """
    media_repo = TMediaRepository(id_media=id_media)
    m = media_repo.media
    if not m:
        raise NotFound("Media introuvable")

    url_thumb = media_repo.get_thumbnail_url(size)

    return redirect(url_thumb)
