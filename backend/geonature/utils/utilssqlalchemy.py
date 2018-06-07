'''
Fonctions utilitaires
'''
import json
from functools import wraps

from dateutil import parser
from flask import Response
from werkzeug.datastructures import Headers

from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import MetaData

from geojson import Feature, FeatureCollection

from geoalchemy2 import Geometry
from geoalchemy2.shape import to_shape

from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError


def testDataType(value, sqlType, paramName):
    if sqlType == DB.Integer or isinstance(sqlType, (DB.Integer)):
        try:
            int(value)
        except Exception as e:
            return '{0} must be an integer'.format(paramName)
    if sqlType == DB.Numeric or isinstance(sqlType, (DB.Numeric)):
        try:
            float(value)
        except Exception as e:
            return '{0} must be an float (decimal separator .)'\
                .format(paramName)
    elif sqlType == DB.DateTime or isinstance(sqlType, (DB.Date, DB.DateTime)):
        try:
            dt = parser.parse(value)
        except Exception as e:
            return '{0} must be an date (yyyy-mm-dd)'.format(paramName)
    return None


"""
    Liste des types de données sql qui
    nécessite une sérialisation particulière en
    @TODO MANQUE FLOAT
"""
SERIALIZERS = {
    'date': lambda x: str(x) if x else None,
    'datetime': lambda x: str(x) if x else None,
    'time': lambda x: str(x) if x else None,
    'timestamp': lambda x: str(x) if x else None,
    'uuid': lambda x: str(x) if x else None,
    'numeric': lambda x: str(x) if x else None
}


class GenericTable:
    """
        Classe permettant de créer à la volée un mapping
            d'une vue avec la base de données par rétroingénierie
    """
    def __init__(self, tableName, schemaName, geometry_field):
        meta = MetaData(schema=schemaName, bind=DB.engine)
        meta.reflect(views=True)
        try:
            self.tableDef = meta.tables["{}.{}".format(schemaName, tableName)]
        except KeyError:
            raise KeyError("table doesn't exists")

        self.geometry_field = geometry_field

        # Mise en place d'un mapping des colonnes en vue d'une sérialisation
        self.serialize_columns = [
            (
                name,
                SERIALIZERS.get(
                    db_col.type.__class__.__name__.lower(),
                    lambda x: x
                )
            )
            for name, db_col in self.tableDef.columns.items()
            if not db_col.type.__class__.__name__ == 'Geometry'
        ]

        self.columns = [column.name for column in self.tableDef.columns]


    def as_dict(self, data):
        return {
            item: _serializer(getattr(data, item)) for item, _serializer in self.serialize_columns
        }

    def as_geo_feature(self, data):
        geometry = to_shape(getattr(data, self.geometry_field))
        feature = Feature(
            geometry=geometry,
            properties=self.as_dict(data)
        )
        return feature


class GenericQuery:
    '''
        Classe permettant de manipuler des objets GenericTable
    '''
    def __init__(
        self,
        db_session,
        tableName, schemaName, geometry_field,
        filters, limit=100, offset=0
    ):
        self.db_session = db_session
        self.tableName = tableName
        self.schemaName = schemaName
        self.geometry_field = geometry_field
        self.filters = filters
        self.limit = limit
        self.offset = offset
        self.view = GenericTable(tableName, schemaName, geometry_field)

    def build_query_filters(self, query, parameters):
        '''
            Construction des filtres
        '''
        for f in parameters:
            query = self.build_query_filter(query, f, parameters.get(f))

        return query

    def build_query_filter(self, query, param_name, param_value):
        if param_name in self.view.columns:
            query = query.filter(self.view.tableDef.columns[param_name] == param_value)

        if param_name.startswith('ilike_'):
            col = self.view.tableDef.columns[param_name[6:]]
            if col.type.__class__.__name__ == "TEXT":
                query = query.filter(col.ilike('%{}%'.format(param_value)))

        if param_name.startswith('filter_d_'):
            col = self.view.tableDef.columns[f[12:]]
            col_type = col.type.__class__.__name__
            testT = testDataType(param_value, DB.DateTime, col)
            if testT:
                raise GeonatureApiError(message=testT)
            if col_type in ("Date", "DateTime", "TIMESTAMP"):
                if param_name.startswith('filter_d_up_'):
                    query = query.filter(col >= param_value)
                if param_name.startswith('filter_d_lo_'):
                    query = query.filter(col <= param_value)
                if param_name.startswith('filter_d_eq_'):
                    query = query.filter(col == param_value)

        if param_name.startswith('filter_n_'):
            col = self.view.tableDef.columns[f[12:]]
            col_type = col.type.__class__.__name__
            testT = testDataType(param_value, DB.Numeric, col)
            if testT:
                raise GeonatureApiError(message=testT)
            if param_name.startswith('filter_n_up_'):
                query = query.filter(col >= param_value)
            if param_name.startswith('filter_n_lo_'):
                query = query.filter(col <= param_value)
        return query

    def build_query_order(self, query, parameters):
        # Ordonnancement
        if 'orderby' in parameters:
            if parameters.get('orderby') in self.view.columns:
                orderCol = getattr(
                    self.view.tableDef.columns,
                    parameters['orderby']
                )
        else:
            return query

        if 'order' in parameters:
            if parameters['order'] == 'desc':
                orderCol = orderCol.desc()
                return query.order_by(orderCol)
        else:
            return query

        return query

    def return_query(self):
        '''
            Lance la requete et retourne les résutats dans un format standard
        '''
        q = self.db_session.query(self.view.tableDef)
        nbResultsWithoutFilter = q.count()

        if self.filters:
            q = self.build_query_filters(q, self.filters)
            q = self.build_query_order(q, self.filters)

        data = q.limit(self.limit).offset(self.offset * self.limit).all()
        nbResults = q.count()

        if self.geometry_field:
            results = FeatureCollection(
                [self.view.as_geo_feature(d) for d in data]
            )
        else:
            results = [self.view.as_dict(d) for d in data]

        return {
            'total': nbResultsWithoutFilter,
            'total_filtered': nbResults,
            'page': self.offset,
            'limit': self.limit,
            'items': results
        }

def serializeQuery(data, columnDef):
    rows = [
        {
            c['name']: getattr(row, c['name'])
            for c in columnDef if getattr(row, c['name']) is not None
        } for row in data
    ]
    return rows

def serializeQueryOneResult(row, columnDef):
    row = {
        c['name']: getattr(row, c['name'])
        for c in columnDef if getattr(row, c['name']) is not None
    }
    return row

def serializeQueryTest(data, columnDef):
    rows = list()
    for row in data:
        inter = {}
        for c in columnDef:
            if getattr(row, c['name']) is not None:
                if isinstance(c['type'], (DB.Date, DB.DateTime, UUID)):
                    inter[c['name']] = str(getattr(row, c['name']))
                elif isinstance(c['type'], DB.Numeric):
                    inter[c['name']] = float(getattr(row, c['name']))
                elif not isinstance(c['type'], Geometry):
                    inter[c['name']] = getattr(row, c['name'])
        rows.append(inter)
    return rows

def serializable(cls):
    """
        Décorateur de classe pour les DB.Models
        Permet de rajouter la fonction as_dict qui est basée sur le mapping SQLAlchemy
    """

    """
        Liste des propriétés sérialisables de la classe
        associées à leur sérializer en fonction de leur type
    """
    cls_db_columns = [
        (
            db_col.key,
            SERIALIZERS.get(
                db_col.type.__class__.__name__.lower(),
                lambda x: x
            )
        )
        for db_col in cls.__mapper__.c
        if not db_col.type.__class__.__name__ == 'Geometry'
    ]


    """
        Liste des propriétés de type relationship
        uselist permet de savoir si c'est une collection de sous objet
        sa valeur est déduite du type de relation
        (OneToMany, ManyToOne ou ManyToMany)
    """
    cls_db_relationships = [
        (db_rel.key, db_rel.uselist) for db_rel in cls.__mapper__.relationships
    ]


    def serializefn(self, recursif=False, columns=()):
        """
        Méthode qui renvoie les données de l'objet sous la forme d'un dict

        Parameters
        ----------
            recursif: boolean
                Spécifie si on veut que les sous objet (relationship)
                soit également sérialisé
            columns: liste
                liste des colonnes qui doivent être prises en compte
        """
        if columns:
            fprops = list(filter(lambda d: d[0] in columns, cls_db_columns))
        else:
            fprops = cls_db_columns

        out = {
            item: _serializer(getattr(self, item)) for item, _serializer in fprops
        }

        if recursif is False:
            return out

        for (rel, uselist) in cls_db_relationships:
            if getattr(self, rel) is None:
                break

            if uselist is True:
                out[rel] = [x.as_dict(recursif) for x in getattr(self, rel)]
            else:
                out[rel] = getattr(self, rel).as_dict(recursif)

        return out


    cls.as_dict = serializefn
    return cls


def geoserializable(cls):
    """
        Décorateur de classe
        Permet de rajouter la fonction as_geofeature à une classe
    """

    def serializegeofn(self, geoCol, idCol, recursif=False, columns=()):
        """
        Méthode qui renvoie les données de l'objet sous la forme
        d'une Feature geojson

        Parameters
        ----------
           geoCol: string
            Nom de la colonne géométrie
           idCol: string
            Nom de la colonne primary key
           recursif: boolean
            Spécifie si on veut que les sous objet (relationship) soit
            également sérialisé
           columns: liste
            liste des columns qui doivent être prisent en compte
        """
        geometry = to_shape(getattr(self, geoCol))
        feature = Feature(
            id=str(getattr(self, idCol)),
            geometry=geometry,
            properties=self.as_dict(recursif, columns)
        )
        return feature

    cls.as_geofeature = serializegeofn
    return cls


def json_resp(fn):
    '''
    Décorateur transformant le résultat renvoyé par une vue
    en objet JSON
    '''
    @wraps(fn)
    def _json_resp(*args, **kwargs):
        res = fn(*args, **kwargs)
        if isinstance(res, tuple):
            return to_json_resp(*res)
        else:
            return to_json_resp(res)
    return _json_resp

def to_json_resp(
    res,
    status=200,
    filename=None,
    as_file=False,
    indent=None
):
    if not res:
        status = 404
        res = {'message': 'not found'}

    headers = None
    if as_file:
        headers = Headers()
        headers.add('Content-Type', 'application/json')
        headers.add(
            'Content-Disposition',
            'attachment',
            filename='export_%s.json' % filename
        )

    return Response(
        json.dumps(res, indent=indent),
        status=status,
        mimetype='application/json',
        headers=headers
    )



def csv_resp(fn):
    '''
    Décorateur transformant le résultat renvoyé en un fichier csv
    '''
    @wraps(fn)
    def _csv_resp(*args, **kwargs):
        res = fn(*args, **kwargs)
        filename, data, columns, separator = res
        return to_csv_resp(filename, data, columns, separator)
    return _csv_resp


def to_csv_resp(filename, data, columns, separator):
    outdata = [separator.join(columns)]

    headers = Headers()
    headers.add('Content-Type', 'text/plain')
    headers.add(
        'Content-Disposition',
        'attachment',
        filename='export_%s.csv' % filename
    )
    for o in data:
        outdata.append(
            separator.join(
                '"%s"' % (o.get(i), '')
                [o.get(i) is None] for i in columns
            )
        )
    out = '\r\n'.join(outdata)
    return Response(out, headers=headers)
