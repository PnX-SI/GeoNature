import datetime, ast

from collections import OrderedDict

import numpy as np
import geog
import zipfile
import fiona

from fiona.crs import from_epsg
from geoalchemy2.shape import to_shape
from shapely.geometry import *

from geonature.utils.errors import GeonatureApiError

# Creation des shapefiles avec la librairies fiona

FIONA_MAPPING = {
    "date": "str",
    "datetime": "str",
    "time": "str",
    "timestamp": "str",
    "uuid": "str",
    "text": "str",
    "unicode": "str",
    "varchar": "str",
    "char": "str",
    "integer": "int",
    "bigint": "int",
    "float": "float",
    "boolean": "str",
    "double_precision": "float",
    "uuid": "str",
}


class FionaShapeService:
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
                if not db_col.type.__class__.__name__ == "Geometry":
                    shp_properties.update(
                        {
                            col_mapping.get(db_col.key): FIONA_MAPPING.get(
                                db_col.type.__class__.__name__.lower()
                            )
                        }
                    )
                    cls.columns.append(col_mapping.get(db_col.key))
        else:
            for db_col in db_cols:
                if not db_col.type.__class__.__name__ == "Geometry":
                    shp_properties.update(
                        {
                            db_col.key: FIONA_MAPPING.get(
                                db_col.type.__class__.__name__.lower()
                            )
                        }
                    )
                    cls.columns.append(db_col.key)

        cls.polygon_schema = {"geometry": "MultiPolygon", "properties": shp_properties}
        cls.point_schema = {"geometry": "Point", "properties": shp_properties}
        cls.polyline_schema = {"geometry": "LineString", "properties": shp_properties}

        cls.file_point = cls.dir_path + "/POINT_" + cls.file_name
        cls.file_poly = cls.dir_path + "/POLYGON_" + cls.file_name
        cls.file_line = cls.dir_path + "/POLYLINE_" + cls.file_name
        # boolean to check if features are register in the shapefile
        cls.point_feature = False
        cls.polygon_feature = False
        cls.polyline_feature = False
        cls.point_shape = fiona.open(
            cls.file_point, "w", "ESRI Shapefile", cls.point_schema, crs=cls.source_crs
        )
        cls.polygone_shape = fiona.open(
            cls.file_poly, "w", "ESRI Shapefile", cls.polygon_schema, crs=cls.source_crs
        )
        cls.polyline_shape = fiona.open(
            cls.file_line,
            "w",
            "ESRI Shapefile",
            cls.polyline_schema,
            crs=cls.source_crs,
        )

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
            feature = {"geometry": geom_geojson, "properties": data}
            cls.write_a_feature(feature, geom_wkt)
        except AssertionError:
            cls.close_files()
            raise GeonatureApiError(
                "Cannot create a shapefile record whithout a Geometry"
            )
        except Exception as e:
            cls.close_files()
            raise GeonatureApiError(e)

    @classmethod
    def create_features_generic(cls, view, data, geom_col, geojson_col=None):
        """
        Create the features of the shapefiles by serializing the datas from a GenericTable (non mapped table)

        Parameters:
            view (GenericTable): the GenericTable object
            data (list): Array of SQLA model
            geom_col (str): name of the WKB geometry column of the SQLA Model
            geojson_col (str): name of the geojson column if present. If None create the geojson from geom_col with shapely
                               for performance reason its better to use geojson_col rather than geom_col

        Returns:
            void

        """
        # if the geojson col is not given
        # build it with shapely via the WKB col
        if geojson_col is None:
            for d in data:
                geom = getattr(d, geom_col)
                geom_wkt = to_shape(geom)
                geom_geojson = mapping(geom_wkt)
                feature = {
                    "geometry": geom_geojson,
                    "properties": view.as_dict(d, columns=cls.columns),
                }
                cls.write_a_feature(feature, geom_wkt)
        else:
            for d in data:
                geom_geojson = ast.literal_eval(getattr(d, geojson_col))
                feature = {
                    "geometry": geom_geojson,
                    "properties": view.as_dict(d, columns=cls.columns),
                }
                if geom_geojson["type"] == "Point":
                    cls.point_shape.write(feature)
                    cls.point_feature = True
                elif (
                    geom_geojson["type"] == "Polygon"
                    or geom_geojson["type"] == "MultiPolygon"
                ):
                    cls.polygone_shape.write(feature)
                    cls.polygon_feature = True
                else:
                    cls.polyline_shape.write(feature)
                    cls.polyline_feature = True

    @classmethod
    def write_a_feature(cls, feature, geom_wkt):
        """
            write a feature by checking the type of the shape given
        """
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
            format_to_save = ["POINT"]
        if cls.polygon_feature:
            format_to_save.append("POLYGON")
        if cls.polyline_feature:
            format_to_save.append("POLYLINE")

        zip_path = cls.dir_path + "/" + cls.file_name + ".zip"
        zp_file = zipfile.ZipFile(zip_path, mode="w")

        for shape_format in format_to_save:
            final_file_name = cls.dir_path + "/" + shape_format + "_" + cls.file_name
            final_file_name = "{dir_path}/{shape_format}_{file_name}/{shape_format}_{file_name}".format(
                dir_path=cls.dir_path,
                shape_format=shape_format,
                file_name=cls.file_name,
            )
            extentions = ("dbf", "shx", "shp", "prj")
            for ext in extentions:
                zp_file.write(
                    final_file_name + "." + ext,
                    shape_format + "_" + cls.file_name + "." + ext,
                )
        zp_file.close()

    @classmethod
    def close_files(cls):
        cls.point_shape.close()
        cls.polygone_shape.close()
        cls.polyline_shape.close()


def create_shapes_generic(
    view, srid, db_cols, data, dir_path, file_name, geom_col, geojson_col
):
    FionaShapeService.create_shapes_struct(db_cols, srid, dir_path, file_name)
    FionaShapeService.create_features_generic(view, data, geom_col, geojson_col)
    FionaShapeService.save_and_zip_shapefiles()


def shapeserializable(cls):
    @classmethod
    def to_shape_fn(
        cls,
        geom_col=None,
        geojson_col=None,
        srid=None,
        data=None,
        dir_path=None,
        file_name=None,
        columns=None,
    ):
        """
        Class method to create 3 shapes from datas
        Parameters

        geom_col (string): name of the geometry column 
        geojson_col (str): name of the geojson column if present. If None create the geojson from geom_col with shapely
                            for performance reason its better to use geojson_col rather than geom_col
        data (list): list of datas 
        file_name (string): 
        columns (list): columns to be serialize

        Returns:
            void
        """
        if not data:
            data = []

        file_name = file_name or datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")

        if columns:
            db_cols = [
                db_col for db_col in db_col in cls.__mapper__.c if db_col.key in columns
            ]
        else:
            db_cols = cls.__mapper__.c

        FionaShapeService.create_shapes_struct(
            db_cols=db_cols, dir_path=dir_path, file_name=file_name, srid=srid
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


def convert_to_2d(geojson):
    """
    Convert a geojson 3d in 2d
    """
    # if its a Linestring, Polygon etc...
    if geojson["coordinates"][0] is list:
        two_d_coordinates = [[coord[0], coord[1]] for coord in geojson["coordinates"]]
    else:
        two_d_coordinates = [geojson["coordinates"][0], geojson["coordinates"][1]]

    geojson["coordinates"] = two_d_coordinates


def remove_third_dimension(geom):
    if not geom.has_z:
        return geom

    if isinstance(geom, Polygon):
        exterior = geom.exterior
        new_exterior = remove_third_dimension(exterior)

        interiors = geom.interiors
        new_interiors = []
        for int in interiors:
            new_interiors.append(remove_third_dimension(int))

        return Polygon(new_exterior, new_interiors)

    elif isinstance(geom, LinearRing):
        return LinearRing([xy[0:2] for xy in list(geom.coords)])

    elif isinstance(geom, LineString):
        return LineString([xy[0:2] for xy in list(geom.coords)])

    elif isinstance(geom, Point):
        return Point([xy[0:2] for xy in list(geom.coords)])

    elif isinstance(geom, MultiPoint):
        points = list(geom.geoms)
        new_points = []
        for point in points:
            new_points.append(remove_third_dimension(point))

        return MultiPoint(new_points)

    elif isinstance(geom, MultiLineString):
        lines = list(geom.geoms)
        new_lines = []
        for line in lines:
            new_lines.append(remove_third_dimension(line))

        return MultiLineString(new_lines)

    elif isinstance(geom, MultiPolygon):
        pols = list(geom.geoms)

        new_pols = []
        for pol in pols:
            new_pols.append(remove_third_dimension(pol))

        return MultiPolygon(new_pols)

    elif isinstance(geom, GeometryCollection):
        geoms = list(geom.geoms)

        new_geoms = []
        for geom in geoms:
            new_geoms.append(remove_third_dimension(geom))

        return GeometryCollection(new_geoms)

    else:
        raise RuntimeError(
            "Currently this type of geometry is not supported: {}".format(type(geom))
        )

