
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
from sqlalchemy import Table, create_engine, MetaData
from werkzeug.datastructures import Headers

db = SQLAlchemy()



class serializableModel(db.Model):
    __abstract__ = True

    def as_dict(self, recursif=False):
        return {column.key: getattr(self, column.key)
                if not isinstance(column.type, (db.Date, db.DateTime))
                else json.dumps(getattr(self, column.key))
                for column in self.__table__.columns }



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
