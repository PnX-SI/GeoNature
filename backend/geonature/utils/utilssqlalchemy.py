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
from geonature.utils.utilsgeometry import create_shapes_generic


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


def get_geojson_feature(wkb):
    ''' retourne une feature geojson à partir d'un WKB'''
    geometry = to_shape(wkb)
    feature = Feature(
        geometry=geometry,
        properties={}
    )
    return feature


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

    def __init__(self, tableName, schemaName, geometry_field, srid=None):
        meta = MetaData(schema=schemaName, bind=DB.engine)
        meta.reflect(views=True)
        try:
            self.tableDef = meta.tables["{}.{}".format(schemaName, tableName)]
        except KeyError:
            raise KeyError("table doesn't exists")

        self.geometry_field = geometry_field
        self.srid = srid

        # Mise en place d'un mapping des colonnes en vue d'une sérialisation
        self.serialize_columns, self.db_cols = self.get_serialized_columns()

    def get_serialized_columns(self, serializers=SERIALIZERS):
        """
            Return a tuple of serialize_columns, and db_cols
            from the generic table
        """
        regular_serialize = []
        db_cols = []
        for name, db_col in self.tableDef.columns.items():
            if not db_col.type.__class__.__name__ == 'Geometry':
                serialize_attr = (
                    name,
                    serializers.get(
                        db_col.type.__class__.__name__.lower(),
                        lambda x: x
                    )
                )
                regular_serialize.append(serialize_attr)

            db_cols.append(db_col)
        return regular_serialize, db_cols

    def as_dict(self, data, columns=None):
        if columns:
            fprops = list(
                filter(lambda d: d[0] in columns, self.serialize_columns)
            )
        else:
            fprops = self.serialize_columns

        return {
            item: _serializer(getattr(data, item)) for item, _serializer in fprops
        }

    def as_geofeature(self, data, columns=None):
        if getattr(data, self.geometry_field) is not None:
            geometry = to_shape(getattr(data, self.geometry_field))

            return Feature(
                geometry=geometry,
                properties=self.as_dict(data, columns)
            )

    def as_shape(self, db_cols, data=None, dir_path=None, file_name=None):
        if not data:
            data = []
        create_shapes_generic(
            view=self,
            db_cols=db_cols,
            srid=self.srid,
            data=data,
            geom_col=self.geometry_field,
            dir_path=dir_path,
            file_name=file_name
        )


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
        if param_name in self.view.tableDef.columns:
            query = query.filter(
                self.view.tableDef.columns[param_name] == param_value
            )

        if param_name.startswith('ilike_'):
            col = self.view.tableDef.columns[param_name[6:]]
            if col.type.__class__.__name__ == "TEXT":
                query = query.filter(col.ilike('%{}%'.format(param_value)))

        if param_name.startswith('filter_d_'):
            col = self.view.tableDef.columns[param_name[12:]]
            col_type = col.type.__class__.__name__
            test_type = testDataType(param_value, DB.DateTime, col)
            if test_type:
                raise GeonatureApiError(message=test_type)
            if col_type in ("Date", "DateTime", "TIMESTAMP"):
                if param_name.startswith('filter_d_up_'):
                    query = query.filter(col >= param_value)
                if param_name.startswith('filter_d_lo_'):
                    query = query.filter(col <= param_value)
                if param_name.startswith('filter_d_eq_'):
                    query = query.filter(col == param_value)

        if param_name.startswith('filter_n_'):
            col = self.view.tableDef.columns[param_name[12:]]
            col_type = col.type.__class__.__name__
            test_type = testDataType(param_value, DB.Numeric, col)
            if test_type:
                raise GeonatureApiError(message=test_type)
            if param_name.startswith('filter_n_up_'):
                query = query.filter(col >= param_value)
            if param_name.startswith('filter_n_lo_'):
                query = query.filter(col <= param_value)
        return query

    def build_query_order(self, query, parameters):
        # Ordonnancement
        if 'orderby' in parameters:
            if parameters.get('orderby') in self.view.columns:
                ordel_col = getattr(
                    self.view.tableDef.columns,
                    parameters['orderby']
                )
        else:
            return query

        if 'order' in parameters:
            if parameters['order'] == 'desc':
                ordel_col = ordel_col.desc()
                return query.order_by(ordel_col)
        else:
            return query

        return query

    def return_query(self):
        '''
            Lance la requete et retourne les résutats dans un format standard
        '''
        q = self.db_session.query(self.view.tableDef)
        nb_result_without_filter = q.count()

        if self.filters:
            q = self.build_query_filters(q, self.filters)
            q = self.build_query_order(q, self.filters)

        data = q.limit(self.limit).offset(self.offset * self.limit).all()
        nb_results = q.count()

        if self.geometry_field:
            results = FeatureCollection(
                [
                    self.view.as_geofeature(d)
                    for d in data
                    if getattr(d, self.geometry_field) is not None
                ]
            )
        else:
            results = [self.view.as_dict(d) for d in data]

        return {
            'total': nb_result_without_filter,
            'total_filtered': nb_results,
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


def serializeQueryOneResult(row, column_def):
    row = {
        c['name']: getattr(row, c['name'])
        for c in column_def if getattr(row, c['name']) is not None
    }
    return row


def serializeQueryTest(data, column_def):
    rows = list()
    for row in data:
        inter = {}
        for c in column_def:
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
        Permet de rajouter la fonction as_dict
        qui est basée sur le mapping SQLAlchemy
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
            if getattr(self, rel):
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
        if not getattr(self, geoCol) is None:
            geometry = to_shape(getattr(self, geoCol))
        else:
            geometry = {"type": "Point", "coordinates": [0,0]}

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
