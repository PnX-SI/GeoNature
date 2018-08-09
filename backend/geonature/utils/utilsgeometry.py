import numpy as np
import geog
import shapely.geometry
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
    'text': lambda x: (x[:254]).encode('utf-8') if x else None,
    'unicode': lambda x: str(x).encode('utf-8') if x else None,
    'varchar': lambda x: str(x).encode('utf-8') if x else None,
}

COLUMNTYPE = {
    'date': ['C', 100],
    'datetime': ['C', 100],
    'time': ['C', 100],
    'timestamp': ['C', 100],
    'uuid': ['C', 100],
    'boolean': ['L', 1],
    'integer': ['N', 6, 0],
    'float': 'F',
    'unicode': ['C', 255],
    'nonetype': ['C', 10],
    'text': ['C', 255],
    'varchar': ['C', 255],
    'bigint': ['N', 6, 0]
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
            data = []

        file_name = file_name or datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')

        if columns:
            db_cols = [db_col for db_col in db_col in cls.__mapper__.c if db_col.key in columns]
        else:
            db_cols = cls.__mapper__.c

        shape_service = ShapeService(
            db_cols,
            srid
        )
        shape_service.create_shapes(
            data=data,
            dir_path=dir_path,
            file_name=file_name,
            geom_col=geom_col,
        )

    cls.as_shape = to_shape_fn
    cls.as_list = serialize_list
    return cls


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
        # TODO: save only if len(shapefile.records > 0)
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
    return shapely.geometry.Polygon(polygon)
