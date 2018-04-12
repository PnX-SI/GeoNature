'''
    Modèles du schéma gn_commons
'''

from sqlalchemy import ForeignKey
from sqlalchemy.sql import select, func
from sqlalchemy.dialects.postgresql import UUID

from geonature.utils.utilssqlalchemy import serializable
from geonature.utils.env import DB


@serializable
class BibMediaTypes(DB.Model):
    __tablename__ = 'bib_media_types'
    __table_args__ = {'schema': 'gn_commons'}
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
    __table_args__ = {'schema': 'gn_commons'}
    id_media = DB.Column(DB.Integer, primary_key=True)
    id_type = DB.Column(
        DB.Integer,
        ForeignKey('gn_commons.bib_media_types.id_type')
    )
    id_table_location = DB.Column(
        DB.Integer,
        ForeignKey('gn_commons.bib_tables_location.id_table_location')
    )
    unique_id_media = DB.Column(
        UUID(as_uuid=True),
        default=select([func.uuid_generate_v4()])
    )
    uuid_attached_row = DB.Column(UUID(as_uuid=True))
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
    is_public = DB.Column(DB.Boolean, default=True)
