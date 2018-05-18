import os
import zipfile
import datetime

import shapefile
import urllib.request


from flask import current_app
from pyproj import Proj
from geoalchemy2.shape import to_shape
from shapely.geometry import Point, Polygon
from osgeo import osr

from .env import ROOT_DIR
from geonature.utils.errors import GeonatureApiError

SERIALIZERS = {
    'date': lambda x: str(x) if x else None,
    'datetime': lambda x: str(x) if x else None,
    'time': lambda x: str(x) if x else None,
    'timestamp': lambda x: str(x) if x else None,
    'uuid': lambda x: str(x) if x else None,
}

COLUMNTYPE = {
    'date': 'C',
    'datetime':'C',
    'time': 'C',
    'timestamp': 'C',
    'uuid': 'C',
    'boolean': 'C',
    'integer': 'N',
    'float': 'F',
    'unicode': 'C',
    'nonetype': 'C'
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

        out = [_serializer(getattr(self, item)) for item, _serializer in fprops]

        return out
    
    @classmethod
    def to_shape_fn(cls, geom_col=None, srid=None, data=[], dir_path=None, file_name=None, columns=None):
        """
        Class method to create 3 shapes from datas
        Parameters
        -----------
        geom_col: name of the geometry column (string)
        data: list of datas (list)
        file_name: (string)
        columns: columns to be serialize (list)
        """
        file_name = file_name or datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')
        create_shapes(cls, geom_col, srid, data, dir_path, file_name, columns)
        

    cls.as_shape = to_shape_fn
    cls.as_list = serialize_list
    return cls



def create_shapes(cls, geom_col, srid, data, dir_path, file_name, columns=None):
    """
        Create tree shapefiles (point, line, polyline) from data of a SQLAlchemy Class
        the class must be serializable
    """
    point = shapefile.Writer(1)
    polyline = shapefile.Writer(3)
    polygon = shapefile.Writer(5)
        
    if columns:
        db_cols = [db_col for db_col in cls.__mapper__.c if db_col.key in columns]
    else:
        db_cols = cls.__mapper__.c

    # fields
    for db_col in db_cols:
        col_type = db_col.type.__class__.__name__.lower()
        if col_type != 'geometry':
            point.field(db_col.key, COLUMNTYPE.get(col_type) ,'100')
            polygon.field(db_col.key, COLUMNTYPE.get(col_type) ,'100')
            polyline.field(db_col.key, COLUMNTYPE.get(col_type) ,'100')
    
    #datas
    try:
        for d in data:
            field_values = d.as_list(columns=columns)
            geom = to_shape(getattr(d, geom_col))

            if isinstance(geom, Point):
                point.point(geom.x, geom.y)
                point.record(*field_values)
            elif isinstance(geom, Polygon):
                polygon.poly(parts=([geom.exterior.coords]))
                polygon.record(*field_values)
            else:
                polyline.line(parts=([geom.coords]))
                polyline.record(*field_values)

            file_point = dir_path+"/POINT_"+file_name
            file_polygon = dir_path+"/POLYGON_"+file_name
            file_polyline = dir_path+"/POLYLINE_"+file_name

            
        proj = osr.SpatialReference()
        proj.ImportFromEPSG(srid)
        for shape in ['POINT', 'POLYLINE', 'POLYGON']:
            path = dir_path+'/'+shape+'_'+file_name+'.prj'
            with open(path, "w") as prj_file:
                prj_file.write(str(proj))
        point.save(file_point)
        polygon.save(file_polygon)
        polyline.save(file_polyline)
    except AttributeError as e:
        raise GeonatureApiError(
            message="Class {} has no {} attribute".format(
                cls, geom_col
            )
        )
    except Exception as e:
        raise GeonatureApiError(message=e)


    zip_it(
        dir_path,
        file_name,
        ['POINT', 'POLYLINE', 'POLYGON']
    )

def zip_it(dir_path, file_name, formats):
    """
        ZIP all the extensions of a shapefile
        parameters:
            -dir_path: string
            -filename: string
            -formats: array of shape type ['POINT', 'POLYLINE', POLYGON']
    """
    zip_path = dir_path+'/'+file_name+'.zip'
    zf = zipfile.ZipFile(zip_path, mode='w')
    
    for shape_format in formats:
        final_file_name = dir_path+'/'+shape_format+"_"+file_name
        zf.write(final_file_name+".dbf", shape_format+"_"+file_name+".dbf")
        zf.write(final_file_name+".shx", shape_format+"_"+file_name+".shx")
        zf.write(final_file_name+".shp", shape_format+"_"+file_name+".shp")
        zf.write(final_file_name+".prj", shape_format+"_"+file_name+".prj")
    zf.close()
