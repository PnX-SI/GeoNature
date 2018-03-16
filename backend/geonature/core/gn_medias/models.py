'''
    Modèles du schéma gn_medias
'''

from sqlalchemy import ForeignKey

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB


@serializable
class BibMediaTypes(DB.Model):
    __tablename__ = 'bib_media_types'
    __table_args__ = {'schema': 'gn_medias'}
    id_type = DB.Column(DB.Integer, primary_key=True)
    label_fr = DB.Column(DB.Unicode)
    label_en = DB.Column(DB.Unicode)
    label_it = DB.Column(DB.Unicode)
    label_es = DB.Column(DB.Unicode)
    label_de = DB.Column(DB.Unicode)
    description_fr = DB.Column(DB.Unicode)
    description_en = DB.Column(DB.Unicode)
    description_it = DB.Column(DB.Unicode)
    description_es = DB.Column(DB.Unicode)
    description_de = DB.Column(DB.Unicode)


@serializable
class TMedias(DB.Model):
    __tablename__ = 't_medias'
    __table_args__ = {'schema': 'gn_medias'}
    id_media = DB.Column(DB.Integer, primary_key=True)
    id_type = DB.Column(
        DB.Integer,
        ForeignKey('gn_medias.bib_media_types.id_type')
    )
    entity_name = DB.Column(DB.Unicode)
    entity_value = DB.Column(DB.Integer)  # A voir à renommer en entity_id
    title_fr = DB.Column(DB.Unicode)
    title_en = DB.Column(DB.Unicode)
    title_it = DB.Column(DB.Unicode)
    title_es = DB.Column(DB.Unicode)
    title_de = DB.Column(DB.Unicode)
    url = DB.Column(DB.Unicode)
    path = DB.Column(DB.Unicode)
    author = DB.Column(DB.Unicode)
    description_fr = DB.Column(DB.Unicode)
    description_en = DB.Column(DB.Unicode)
    description_it = DB.Column(DB.Unicode)
    description_es = DB.Column(DB.Unicode)
    description_de = DB.Column(DB.Unicode)
    meta_create_date = DB.Column(DB.DateTime)
    meta_update_date = DB.Column(DB.DateTime)
    is_public = DB.Column(DB.Boolean, default=True)
    deleted = DB.Column(DB.Boolean, default=False)
