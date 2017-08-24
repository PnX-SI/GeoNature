
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

from geoalchemy2.shape import to_shape, from_shape
from geojson import Feature

from geoalchemy2 import Geometry

db = SQLAlchemy()



class serializableModel(db.Model):
    __abstract__ = True
    def as_dict(self, recursif=False):
        obj={}
        for prop in class_mapper(self.__class__).iterate_properties:
            if isinstance(prop, ColumnProperty)  :
                column = self.__table__.columns[prop.key]
                if isinstance(column.type, (db.Date, db.DateTime)) :
                    obj[prop.key] =str(getattr(self, prop.key))
                elif not isinstance(column.type, Geometry) :
                    obj[prop.key] =getattr(self, prop.key)
            if ((isinstance(prop,RelationshipProperty)) and (recursif)):
                if hasattr( getattr(self, prop.key), '__iter__') :
                    obj[prop.key] = [d.as_dict(recursif) for d in getattr(self, prop.key)]
                else :
                    obj[prop.key] = getattr(self, prop.key).as_dict(recursif)


        return obj

class serializableGeoModel(serializableModel):
    __abstract__ = True

    def as_geofeature(self, geoCol, idCol, recursif=False):
        geometry = to_shape(getattr(self, geoCol))
        feature = Feature(
                id=getattr(self, idCol),
                geometry=geometry,
                properties=self.as_dict(recursif)
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
