"""
    Route permettant de manipuler les fichiers
    contenus dans gn_media
"""

from flask import request, redirect, jsonify
from werkzeug.exceptions import NotFound

from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.models import TMedias
from geonature.core.gn_synthese.models import Synthese
from geonature.utils.env import db, DB
from utils_flask_sqla.response import json_resp, json_resp_accept_empty_list
from sqlalchemy import select

from ..routes import routes
from apptax.taxonomie.models import Taxref


@routes.route("/medias/<string:uuid_attached_row>", methods=["GET"])
@json_resp_accept_empty_list
def get_medias(uuid_attached_row):
    """
    Retourne des medias
    .. :quickref: Commons;
    """

    res = DB.session.scalars(
        select(TMedias).where(TMedias.uuid_attached_row == uuid_attached_row)
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


@routes.route("/medias/taxon/<int:cd_ref>", methods=["GET"])
@json_resp_accept_empty_list
def get_taxon_medias(cd_ref):
    """
    Retourne tous les médias liés à une espèce (cd_ref)
    """
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)

    query = (
        select(TMedias)
        .join(Synthese, Synthese.unique_id_sinp == TMedias.uuid_attached_row)
        .where(TMedias.is_public == True)
        .order_by(TMedias.meta_create_date.desc())
    )

    taxref_cd_nom_list = db.session.scalars(select(Taxref.cd_nom).where(Taxref.cd_ref == cd_ref))
    query = query.where(Synthese.cd_nom.in_(taxref_cd_nom_list))

    pagination = DB.paginate(query, page=page, per_page=per_page)

    return {
        "total": pagination.total,
        "page": pagination.page,
        "per_page": pagination.per_page,
        "items": [media.as_dict() for media in pagination.items],
    }
