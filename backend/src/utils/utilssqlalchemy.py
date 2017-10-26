
# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

'''
Fonctions utilitaires
'''
from flask import jsonify,  Response, current_app
import json
from functools import wraps
from flask_sqlalchemy import SQLAlchemy
from werkzeug.datastructures import Headers

from sqlalchemy import inspect
from sqlalchemy.orm import class_mapper, ColumnProperty, RelationshipProperty

from sqlalchemy.dialects.postgresql import UUID

from geoalchemy2.shape import to_shape, from_shape
from geojson import Feature

from geoalchemy2 import Geometry

from datetime import date, datetime

db = SQLAlchemy()


def testDataType(value, sqlType, paramName):
    if sqlType == db.Integer or isinstance(sqlType, (db.Integer)) :
        try :
            int(value)
        except :
            return  '{0} must be an integer'.format(paramName)
    if sqlType == db.Numeric or isinstance(sqlType, (db.Numeric)) :
        try :
            float(value)
        except :
            return  '{0} must be an float (decimal separator .)'.format(paramName)
    elif sqlType == db.DateTime or isinstance(sqlType, (db.Date, db.DateTime)):
        try :
            from dateutil import parser
            dt = parser.parse(value)
        except :
            return  '{0} must be an date (yyyy-mm-dd)'.format(paramName)
    return None

class GenericTable:
    def __init__(self, tableName, schemaName):
        engine = create_engine(current_app.config['SQLALCHEMY_DATABASE_URI'])
        meta = MetaData(bind=engine)
        meta.reflect(schema=schemaName, views=True)
        self.tableDef = meta.tables[tableName]
        self.columns = [column.name for column in self.tableDef.columns]

    def serialize(self, data):
        return serializeQuery(data, self.columns)

def serializeQuery( data, columnDef):
    rows = [
        {c['name'] : getattr(row, c['name']) for c in columnDef if getattr(row, c['name']) != None } for row in data
    ]
    return rows

def serializeQueryOneResult( row, columnDef):
    row = {c['name'] : getattr(row, c['name']) for c in columnDef if getattr(row, c['name']) != None }
    return row

class serializableModel(db.Model):
    """
    Classe qui ajoute une méthode de transformation des données de l'objet en tableau json
    Paramètres :
       -
    """
    __abstract__ = True
    def as_dict(self, recursif=False, columns=()):
        """
        Méthode qui renvoie les données de l'objet sous la forme d'un dictionnaire
        :param recursif: Spécifie si on veut que les sous objet (relationship) soit égalament sérialisé
        :param columns: liste des columns qui doivent être prisent en compte
        """
        obj={}
        if  (not columns) :
            columns = self.__table__.columns

        for prop in class_mapper(self.__class__).iterate_properties:
            if (isinstance(prop, ColumnProperty) and (prop.key in columns)) :
                column = self.__table__.columns[prop.key]
                if isinstance(column.type, (db.Date, db.DateTime, UUID)) :
                    obj[prop.key] =str(getattr(self, prop.key))
                elif isinstance(column.type, db.Numeric) :
                    obj[prop.key] =float(getattr(self, prop.key))
                elif not isinstance(column.type, Geometry) :
                    obj[prop.key] =getattr(self, prop.key)
            if ((isinstance(prop,RelationshipProperty)) and (recursif)):
                if hasattr( getattr(self, prop.key), '__iter__') :
                    obj[prop.key] = [d.as_dict(recursif) for d in getattr(self, prop.key)]
                else :
                    if (getattr(getattr(self, prop.key), "as_dict", None)) :
                        obj[prop.key] = getattr(self, prop.key).as_dict(recursif)

        return obj

class serializableGeoModel(serializableModel):
    __abstract__ = True

    def as_geofeature(self, geoCol, idCol, recursif=False, columns=()):
        """
        Méthode qui renvoie les données de l'objet sous la forme d'une Feature geojson
        :param geoCol : Nom de la colonne géométrie
        :param idCol : Nom de la colonne primary key
        :param recursif: Spécifie si on veut que les sous objet (relationship) soit égalament sérialisé
        :param columns: liste des columns qui doivent être prisent en compte
        """
        geometry = to_shape(getattr(self, geoCol))
        feature = Feature(
                id=getattr(self, idCol),
                geometry=geometry,
                properties=self.as_dict(recursif, columns)
            )
        return feature

def json_resp(fn):
    '''
    Décorateur transformant le résultat renvoyé par une vue
    en objet JSON
    '''
    @wraps(fn)
    def _json_resp(*args, **kwargs):
        res = fn(*args, **kwargs)
        if isinstance(res, tuple):
            res, status = res
        else:
            status = 200
        return Response(json.dumps(res),
                status=status, mimetype='application/json')
    return _json_resp


def csv_resp(fn):
    '''
    Décorateur transformant le résultat renvoyé en un fichier csv
    '''
    @wraps(fn)
    def _csv_resp(*args, **kwargs):
        res = fn(*args, **kwargs)
        filename, data, columns, separator = res
        outdata =  [separator.join(columns)]

        headers = Headers()
        headers.add('Content-Type', 'text/plain')
        headers.add('Content-Disposition', 'attachment', filename='export_%s.csv'%filename)

        for o in data:
            outdata.append(separator.join('"%s"'%(o.get(i), '')[o.get(i) == None] for i in columns))

        out = '\r\n'.join(outdata)
        return Response(out, headers=headers)
    return _csv_resp
