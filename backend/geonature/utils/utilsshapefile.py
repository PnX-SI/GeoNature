import zipfile
import datetime

import shapefile

from pyproj import Proj
from geoalchemy2.shape import to_shape
from shapely.geometry import Point, Polygon
from osgeo import osr


SERIALIZERS = {
    'date': lambda x: str(x) if x else None,
    'datetime': lambda x: str(x) if x else None,
    'time': lambda x: str(x) if x else None,
    'timestamp': lambda x: str(x) if x else None,
    'uuid': lambda x: str(x) if x else None,
}

COLUMNTYPE = {
    'date': 'C',
    'datetime': 'C',
    'time': 'C',
    'timestamp': 'C',
    'uuid': 'C',
    'boolean': 'C',
    'integer': 'N',
    'float': 'F',
    'unicode': 'C',
    'nonetype': 'C',
    'text': 'C',
    'varchar': 'C',
    'bigint': 'N'
}

SHAPETYPE = {
    'POINT': 1,
    'POLYLINE': 3,
    'POLYGON': 5
}


def shapeseralizable(cls):
    """
        Decorateur de classe permettant de générer
        des shapefile à partir d'une classe SQLAlechemy
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

    def serialize_list(self, columns=()):
        """
        Methods which return the object as a list
        exclude geom column of the serialization

        Parameters
        ----------
            columns: list
                columns list of the object which are serialize
        # TODO: recursif
        """
        if columns:
            fprops = list(filter(lambda d: d[0] in columns, cls_db_columns))
        else:
            fprops = cls_db_columns

        out = [
            _serializer(getattr(self, item)) for item, _serializer in fprops
        ]

        return out

    @classmethod
    def to_shape_fn(
            cls, geom_col=None, srid=None, data=None,
            dir_path=None, file_name=None, columns=None
    ):
        """
        Class method to create 3 shapes from datas
        Parameters
        -----------
        geom_col: name of the geometry column (string)
        data: list of datas (list)
        file_name: (string)
        columns: columns to be serialize (list)
        """
        if not data:
            data=[]

        file_name = file_name or datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')

        # TODO ? Pas compris ce que représentait co
        co(
            cls.__mapper__.c,
            columns, data, dir_path,
            file_name, geom_col, srid
        )

    cls.as_shape = to_shape_fn
    cls.as_list = serialize_list
    return cls


def zip_it(dir_path, file_name, formats):
    """
        ZIP all the extensions of a shapefile
        parameters:
            -dir_path: string
            -filename: string
            -formats: array of shape type ['POINT', 'POLYLINE', POLYGON']
    """
    zip_path = dir_path + '/' + file_name + '.zip'
    zp_file = zipfile.ZipFile(zip_path, mode='w')

    for shape_format in formats:
        final_file_name = dir_path + '/' + shape_format + "_" + file_name
        extentions = ("dbf", "shx", "shp", "prj")
        for ext in extentions:
            zp_file.write(
                final_file_name + "." + ext,
                shape_format + "_" + file_name + "." + ext
            )
    zp_file.close()


def create_shape_struct(db_cols, columns):
    point = shapefile.Writer(1)
    polyline = shapefile.Writer(3)
    polygon = shapefile.Writer(5)

    if columns:
        db_cols = [db_col for db_col in db_cols if db_col.key in columns]
    else:
        db_cols = db_cols

    # fields
    for db_col in db_cols:
        col_type = db_col.type.__class__.__name__.lower()
        if col_type != 'geometry':
            point.field(db_col.key, COLUMNTYPE.get(col_type), '100')
            polygon.field(db_col.key, COLUMNTYPE.get(col_type), '100')
            polyline.field(db_col.key, COLUMNTYPE.get(col_type), '100')

    return point, polyline, polygon


def get_fields_row_generic(mapped_table, data, columns=[]):
    """ return the fields of of row serialized in a table
        for generic table
    """
    return mapped_table.as_list(data, columns)


def get_fields_row(data, columns=[]):
    """ return the fields of of row serialized in a table
        for generic table
    """
    return data.as_list(columns=columns)


def create_features(row_as_list, row, geom_col, point, polyline, polygon):
    """
    Create a shapefile feature with:
    - row_as_list: the formated attribute in a list
    - row: the origingal data row, with the geom column
    """
    geom = to_shape(getattr(row, geom_col))
    # TODO: catch exception
    if isinstance(geom, Point):
        point.point(geom.x, geom.y)
        point.record(*row_as_list)
    elif isinstance(geom, Polygon):
        polygon.poly(parts=([geom.exterior.coords]))
        polygon.record(*row_as_list)
    else:
        polyline.line(parts=([geom.coords]))
        polyline.record(*row_as_list)


def save_shape(dir_path, file_name, point, polyline, polygon, srid):
    file_point = dir_path + "/POINT_" + file_name
    file_polygon = dir_path + "/POLYGON_" + file_name
    file_polyline = dir_path + "/POLYLINE_" + file_name

    proj = osr.SpatialReference()
    proj.ImportFromEPSG(srid)
    for shape in ['POINT', 'POLYLINE', 'POLYGON']:
        path = dir_path + '/' + shape + '_' + file_name + '.prj'
        with open(path, "w") as prj_file:
            prj_file.write(str(proj))
    point.save(file_point)
    polygon.save(file_polygon)
    polyline.save(file_polyline)


def create_shapes(db_cols, columns, data, dir_path, file_name, geom_col, srid):
    point, line, polygon = create_shape_struct(db_cols, columns)
    for d in data:
        row_as_list = get_fields_row(d, columns)
        create_features(row_as_list, d, geom_col, point, line, polygon)
    save_shape(dir_path, file_name, point, line, polygon, srid)
    zip_it(
        dir_path,
        file_name,
        ['POINT', 'POLYLINE', 'POLYGON']
    )

def create_shapes_generic(mapped_table, db_cols, columns, data, dir_path, file_name, geom_col, srid):
    point, line, polygon = create_shape_struct(db_cols, columns)
    for d in data:
        row_fields = get_fields_row_generic(mapped_table, d, columns)
        create_features(row_fields, d, geom_col, point, line, polygon)
    save_shape(dir_path, file_name, point, line, polygon, srid)
    zip_it(
        dir_path,
        file_name,
        ['POINT', 'POLYLINE', 'POLYGON']
    )
