import datetime

from collections import OrderedDict

import numpy as np
import geog
import zipfile
import fiona

from fiona.crs import from_epsg
from geoalchemy2.shape import to_shape
from shapely.geometry import Point, Polygon, MultiPolygon, mapping

from geonature.utils.errors import GeonatureApiError

# Creation des shapefiles avec la librairies fiona

FIONA_MAPPING = {
    'date': 'str',
    'datetime': 'str',
    'time': 'str',
    'timestamp': 'str',
    'uuid': 'str',
    'text': 'str',
    'unicode': 'str',
    'varchar': 'str',
    'integer': 'int',
    'bigint': 'int',
    'float': 'float',
    'boolean': 'str',
}


class FionaShapeService():
    """
    Service to create shapefiles from sqlalchemy models

    How to use:
    FionaShapeService.create_shapes_struct(**args)
    FionaShapeService.create_features(**args)
    FionaShapeService.save_and_zip_shapefiles()
    """

    @classmethod
    def create_shapes_struct(cls, db_cols, srid, dir_path, file_name, col_mapping=None):
        """
        Create three shapefiles (point, line, polygon) with the attributes give by db_cols
        Parameters:
            db_cols (list): columns from a SQLA model (model.__mapper__.c)
            srid (int): epsg code
            dir_path (str): directory path
            file_name (str): file of the shapefiles
            col_mapping (dict): mapping between SQLA class attributes and 'beatifiul' columns name

        Returns:
            void
        """
        cls.db_cols = db_cols
        cls.source_crs = from_epsg(srid)
        cls.dir_path = dir_path
        cls.file_name = file_name

        cls.columns = []
        # if we want to change to columns name of the SQLA class
        # in the export shapefiles structures
        shp_properties = OrderedDict()
        if col_mapping:
            for db_col in db_cols:
                if not db_col.type.__class__.__name__ == 'Geometry':
                    shp_properties.update({
                        col_mapping.get(db_col.key): FIONA_MAPPING.get(
                            db_col.type.__class__.__name__.lower())
                    })
                    cls.columns.append(col_mapping.get(db_col.key))
        else:
            for db_col in db_cols:
                if not db_col.type.__class__.__name__ == 'Geometry':
                    shp_properties.update({
                        db_col.key: FIONA_MAPPING.get(
                            db_col.type.__class__.__name__.lower())
                    })
                    cls.columns.append(db_col.key)

        cls.polygon_schema = {'geometry': 'MultiPolygon', 'properties': shp_properties, }
        cls.point_schema = {'geometry': 'Point', 'properties': shp_properties, }
        cls.polyline_schema = {'geometry': 'LineString', 'properties': shp_properties}

        cls.file_point = cls.dir_path + "/POINT_" + cls.file_name
        cls.file_poly = cls.dir_path + "/POLYGON_" + cls.file_name
        cls.file_line = cls.dir_path + "/POLYLINE_" + cls.file_name
        # boolean to check if features are register in the shapefile
        cls.point_feature = False
        cls.polygon_feature = False
        cls.polyline_feature = False
        cls.point_shape = fiona.open(cls.file_point, 'w', 'ESRI Shapefile', cls.point_schema, crs=cls.source_crs)
        cls.polygone_shape = fiona.open(cls.file_poly, 'w', 'ESRI Shapefile', cls.polygon_schema, crs=cls.source_crs)
        cls.polyline_shape = fiona.open(cls.file_line, 'w', 'ESRI Shapefile', cls.polyline_schema, crs=cls.source_crs)

    @classmethod
    def create_feature(cls, data, geom):
        """
        Create a feature (a record of the shapefile) for the three shapefiles
        by serializing an SQLAlchemy object

        Parameters:
            data (dict): the SQLAlchemy model serialized as a dict
            geom (WKB): the geom as WKB


        Returns:
            void
        """
        try:
            geom_wkt = to_shape(geom)
            geom_geojson = mapping(geom_wkt)
            feature = {'geometry': geom_geojson, 'properties': data}
            if isinstance(geom_wkt, Point):
                cls.point_shape.write(feature)
                cls.point_feature = True
            elif isinstance(geom_wkt, Polygon) or isinstance(geom_wkt, MultiPolygon):
                cls.polygone_shape.write(feature)
                cls.polygon_feature = True
            else:
                cls.polyline_shape.write(feature)
                cls.polyline_feature = True
        except AssertionError:
            cls.close_files()
            raise GeonatureApiError('Cannot create a shapefile record whithout a Geometry')
        except Exception as e:
            cls.close_files()
            raise GeonatureApiError(e)

    @classmethod
    def create_features_generic(cls, view, data, geom_col):
        """
        Create the features of the shapefiles by serializing the datas from a GenericTable (non mapped table)

        Parameters:
            view (GenericTable): the GenericTable object
            data (list): Array of SQLA model
            geom_col (str): name of the geometry column of the SQLA Model

        Returns:
            void

        """
        for d in data:
            geom = getattr(d, geom_col)
            geom_wkt = to_shape(geom)
            geom_geojson = mapping(geom_wkt)
            feature = {'geometry': geom_geojson, 'properties': view.as_dict(d, columns=cls.columns)}
            if isinstance(geom_wkt, Point):
                cls.point_shape.write(feature)
                cls.point_feature = True
            elif isinstance(geom_wkt, Polygon) or isinstance(geom_wkt, MultiPolygon):
                cls.polygone_shape.write(feature)
                cls.polygon_feature = True
            else:
                cls.polyline_shape.write(feature)
                cls.polyline_feature = True

    @classmethod
    def save_and_zip_shapefiles(cls):
        """
        Save and zip the files
        Only zip files where there is at least on feature

        Returns:
            void
        """
        cls.close_files()

        format_to_save = []
        if cls.point_feature:
            format_to_save = ['POINT']
        if cls.polygon_feature:
            format_to_save.append('POLYGON')
        if cls.polyline_feature:
            format_to_save.append('POLYLINE')

        zip_path = cls.dir_path + '/' + cls.file_name + '.zip'
        zp_file = zipfile.ZipFile(zip_path, mode='w')

        for shape_format in format_to_save:
            final_file_name = cls.dir_path + '/' + shape_format + "_" + cls.file_name
            final_file_name = '{dir_path}/{shape_format}_{file_name}/{shape_format}_{file_name}'.format(
                dir_path=cls.dir_path,
                shape_format=shape_format,
                file_name=cls.file_name
            )
            extentions = ("dbf", "shx", "shp", "prj")
            for ext in extentions:
                zp_file.write(
                    final_file_name + "." + ext,
                    shape_format + "_" + cls.file_name + "." + ext
                )
        zp_file.close()

    @classmethod
    def close_files(cls):
        cls.point_shape.close()
        cls.polygone_shape.close()
        cls.polyline_shape.close()


def create_shapes_generic(view, srid, db_cols, data, dir_path, file_name, geom_col):
    FionaShapeService.create_shapes_struct(db_cols, srid, dir_path, file_name)
    FionaShapeService.create_features_generic(view, data, geom_col)
    FionaShapeService.save_and_zip_shapefiles()


def shapeserializable(cls):

    @classmethod
    def to_shape_fn(
            cls, geom_col=None, srid=None, data=None,
            dir_path=None, file_name=None, columns=None
    ):
        """
        Class method to create 3 shapes from datas
        Parameters

        geom_col (string): name of the geometry column 
        data (list): list of datas 
        file_name (string): 
        columns (list): columns to be serialize

        Returns:
            void
        """
        if not data:
            data = []

        file_name = file_name or datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')

        if columns:
            db_cols = [db_col for db_col in db_col in cls.__mapper__.c if db_col.key in columns]
        else:
            db_cols = cls.__mapper__.c

        FionaShapeService.create_shapes_struct(
            db_cols=db_cols,
            dir_path=dir_path,
            file_name=file_name,
            srid=srid
        )
        for d in data:
            d = d.as_dict(columns)
            geom = getattr(d, geom_col)
            FionaShapeService.create_feature(d, geom)

        FionaShapeService.save_and_zip_shapefiles()

    cls.as_shape = to_shape_fn
    return cls


def circle_from_point(point, radius, nb_point=20):
    """
    return a circle (shapely POLYGON) from a point 
    parameters:
        - point: a shapely POINT
        - radius: circle's diameter in meter
        - nb_point: nb of point of the polygo,

    """
    angles = np.linspace(0, 360, nb_point)
    polygon = geog.propagate(point, angles, radius)
    return Polygon(polygon)
