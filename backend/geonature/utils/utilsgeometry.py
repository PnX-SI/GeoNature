import datetime

import numpy as np
import geog
import zipfile
import shapefile
import fiona

from fiona.crs import from_epsg
from pyproj import Proj
from geoalchemy2.shape import to_shape
from shapely.geometry import Point, Polygon, MultiPolygon, mapping
from osgeo import osr

# Creation des shapefiles avec la librairie pyshp - Ne pas utiliser
# pour des raisons de problème d'encodage du fichier .dbf


class ShapeService():
    """
    Service to create shapefiles from sqlalchemy models
    Init the service:
    params:
        - db_cols: column list of the sqlachemy models in the export
            (type: List of SQLAlchemy Column class: returned by MappedClass.__mapper__.c)
        - srid: EPSG code: type integer

    Attributes:
        point: shapefile Writter (shapefile librairy)
        polyline: shapefile Writter (shapefile librairy)
        polygon: shapefile Writter (shapefile librairy)
        srid: EPSG code
        db_cols: column list of the sqlachemy models in the export
        saved_shapefiles: array of shapefiles written after call the save_shape method

    """

    def __init__(self, db_columns, srid, format=['POINT', 'POLYLINE', 'POLYGON']):
        """

        """
        self.point = shapefile.Writer(1)
        self.polyline = shapefile.Writer(3)
        self.polygon = shapefile.Writer(5)
        self.srid = srid

        self.db_cols = [db_col for db_col in db_columns]
        self.columns = [db_col.key for db_col in db_columns]
        self.saved_shapefiles = []

    def get_fields_row_generic(self, mapped_table, data, columns=[]):
        """ return the fields of of row serialized in a table
            for generic table
        """
        return mapped_table.as_list(data, columns)

    def get_fields_row(self, row, columns=[]):
        """ return the fields of of row serialized in a table
            for generic table
        """
        return row.as_list(columns=columns)

    def create_shape_struct(self):
        """
        Create the fields (columns) of the shapefiles 
        """
        for db_col in self.db_cols:
            col_type = db_col.type.__class__.__name__.lower()
            if col_type != 'geometry':
                self.point.field(db_col.key, *COLUMNTYPE.get(col_type))
                self.polygon.field(db_col.key, *COLUMNTYPE.get(col_type))
                self.polyline.field(db_col.key, *COLUMNTYPE.get(col_type))

    def create_features(self, row_as_list, geom):
        """
        Create a shapefile feature with:
        - row_as_list: the formated attribute in a list
        - the geom of the row in WKB (sqlachemy Geometry)
        """
        geom = to_shape(geom)
        # TODO: catch exception
        if isinstance(geom, Point):
            self.point.point(geom.x, geom.y)
            self.point.record(*row_as_list)
        elif isinstance(geom, Polygon):
            self.polygon.poly(parts=([geom.exterior.coords]))
            self.polygon.record(*row_as_list)
        else:
            self.polyline.line(parts=([geom.coords]))
            self.polyline.record(*row_as_list)

    def save_shape(self, dir_path, file_name):
        """
        Save the tree shapefiles
        """
        file_point = dir_path + "/POINT_" + file_name
        file_polygon = dir_path + "/POLYGON_" + file_name
        file_polyline = dir_path + "/POLYLINE_" + file_name

        proj = osr.SpatialReference()
        proj.ImportFromEPSG(self.srid)

        # check if shape records is not empty
        if len(self.point.records) > 0:
            self.saved_shapefiles.append('POINT')
        if len(self.polyline.records) > 0:
            self.saved_shapefiles.append('POLYLINE')
        if len(self.polygon.records) > 0:
            self.saved_shapefiles.append('POLYGON')

        # save only the shape which have records
        for shape_format in self.saved_shapefiles:
            # write the .prj file with the projection
            path = dir_path + '/' + shape_format + '_' + file_name + '.prj'
            with open(path, "w") as prj_file:
                prj_file.write(str(proj))
            # save the shapegile
            shape_object = getattr(self, shape_format.lower())
            shape_object.save(dir_path+'/'+shape_format + '_' + file_name)

    def zip_it(self, dir_path, file_name, formats=['POINT', 'POLYLINE', 'POLYGON']):
        """
            ZIP all the extensions of a shapefile
            parameters:
                -dir_path: string
                -filename: string
                -formats: array of shape type, default: ['POINT', 'POLYLINE', POLYGON']
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

    def create_shapes(self, data, dir_path, file_name, geom_col):
        """
        High level function to create the shapefiles
        params:
            data: data from sqlachemy. Type: array of model
            dir_path: export directory path (static directory). Type: string
            file_name:: export filename. Type: string
            geom_col: name of the geomtry column of the sqlachemy model. Type: string

        """
        self.create_shape_struct()
        for d in data:
            row_as_list = self.get_fields_row(d, self.columns)
            geom = getattr(d, geom_col)
            self.create_features(row_as_list, geom)
        self.save_shape(dir_path, file_name)
        self.zip_it(
            dir_path,
            file_name,
            self.saved_shapefiles
        )

    def create_shapes_generic(self, mapped_table, data, dir_path, file_name, geom_col):
        """
        High level function to create the shapefiles from a non mapped table (GenericTable from utilsqlachemy)
        params:
            mapped_table: a GenericTable object from utilsqlachemy
            data: data from sqlachemy. Type: array of model
            dir_path: export directory path (static directory). Type: string
            file_name:: export filename. Type: string
            geom_col: name of the geomtry column of the sqlachemy model. Type: string

        """
        self.create_shape_struct()
        for d in data:
            row_fields = self.get_fields_row_generic(mapped_table, d, self.columns)
            geom = getattr(d, geom_col)
            self.create_features(row_fields, geom)
        self.save_shape(dir_path, file_name)
        self.zip_it(
            dir_path,
            file_name,
            self.saved_shapefiles
        )


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
    'float': 'float'
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
    def create_shapes_struct(cls, db_cols, srid, dir_path, file_name):
        """
        Create three shapefiles (point, line, polygon) with the attributes give by db_cols
        Parameters:
            db_cols (list): columns from a SQLA model (model.__mapper__.c)
            srid (int): epsg code
            dir_path (str): directory path
            file_name (str): file of the shapefiles

        Returns:
            void
        """
        cls.db_cols = db_cols
        cls.source_crs = from_epsg(srid)
        cls.dir_path = dir_path
        cls.file_name = file_name

        shp_properties = {}
        cls.columns = []
        for db_col in db_cols:
            if not db_col.type.__class__.__name__ == 'Geometry':
                shp_properties[db_col.key] = FIONA_MAPPING.get(
                    db_col.type.__class__.__name__.lower()
                )
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
    def create_features(cls, data, geom_col):
        """
        Create the features of the shapefiles by serializing the datas from SQLAlchemy model

        Parameters:
            data (list): Array of SQLA model
            geom_col (str): name of the geometry column of the SQLA Model

        Returns:
            void
        """
        for d in data:
            geom = getattr(d, geom_col)
            geom_wkt = to_shape(geom)
            geom_geojson = mapping(geom_wkt)
            feature = {'geometry': geom_geojson, 'properties': d.as_dict(columns=cls.columns)}
            if isinstance(geom_wkt, Point):
                cls.point_shape.write(feature)
                cls.point_feature = True
            elif isinstance(geom_wkt, Polygon) or isinstance(geom_wkt, MultiPolygon):
                cls.polygone_shape.write(feature)
                cls.polygon_feature = True
            else:
                cls.polyline_shape.write(feature)
                cls.polyline_feature = True

        cls.point_shape.close()
        cls.polygone_shape.close()
        cls.polyline_shape.close()

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
            print('LAAAAAAAAAAAa')
            print(feature)
            if isinstance(geom_wkt, Point):
                cls.point_shape.write(feature)
                cls.point_feature = True
            elif isinstance(geom_wkt, Polygon) or isinstance(geom_wkt, MultiPolygon):
                cls.polygone_shape.write(feature)
                cls.polygon_feature = True
            else:
                cls.polyline_shape.write(feature)
                cls.polyline_feature = True

        cls.point_shape.close()
        cls.polygone_shape.close()
        cls.polyline_shape.close()

    @classmethod
    def save_and_zip_shapefiles(cls):
        """
        Save and zip the files
        Only zip files where there is at leas on feature

        Returns:
            void
        """
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


def create_shapes_generic(view, srid, db_cols, data, dir_path, file_name, geom_col):
    FionaShapeService.create_shapes_struct(db_cols, srid, dir_path, file_name)
    FionaShapeService.create_features_generic(view, data, geom_col)
    FionaShapeService.save_and_zip_shapefiles()


def shape_serializable(cls):

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
        FionaShapeService.create_features(
            data=data,
            geom_col=geom_col
        )

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
