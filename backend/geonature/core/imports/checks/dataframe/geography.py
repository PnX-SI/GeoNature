from functools import partial

import sqlalchemy as sa
from geoalchemy2.functions import ST_Transform, ST_GeomFromWKB, ST_GeomFromText
import pandas as pd
from shapely import wkt
from shapely.geometry import Point, Polygon
from shapely.geometry.base import BaseGeometry
from shapely.ops import transform
from pyproj import CRS, Transformer
from ref_geo.models import LAreas

from geonature.utils.env import db

from .utils import dfcheck


def get_srid_bounding_box(srid):
    """
    calculate the local bounding box and
    return a shapely polygon of this BB with local coordq
    """
    xmin, ymin, xmax, ymax = CRS.from_epsg(srid).area_of_use.bounds
    bounding_polygon_4326 = Polygon([(xmin, ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax)])
    projection = Transformer.from_crs(CRS(4326), CRS(int(srid)), always_xy=True)
    return transform(projection.transform, bounding_polygon_4326)


def wkt_to_geometry(value):
    try:
        return wkt.loads(value)
    except Exception:
        return None


def xy_to_geometry(x, y):
    try:
        return Point(float(x.replace(",", ".")), float(y.replace(",", ".")))
    except Exception:
        return None


def check_bound(p, bounding_box: Polygon):
    return p.within(bounding_box)


def check_geometry_inside_l_areas(geometry: BaseGeometry, id_area: int, geom_srid: int):
    """
    Like check_wkt_inside_l_areas but with a conversion before
    """
    wkt = geometry.wkt
    return check_wkt_inside_area_id(wkt=wkt, id_area=id_area, wkt_srid=geom_srid)


def check_wkt_inside_area_id(wkt: str, id_area: int, wkt_srid: int):
    """
    Checks if the provided wkt is inside the area defined
    by id_area
    Args:
        wkt(str): geometry to check if inside the area
        id_area(int): id to get the area in ref_geo.l_areas
        wkt_srid(str): srid of the provided wkt
    """
    local_srid = db.session.execute(sa.func.Find_SRID("ref_geo", "l_areas", "geom")).scalar()
    query = LAreas.query.filter(LAreas.id_area == id_area).filter(
        LAreas.geom.ST_Contains(ST_Transform(ST_GeomFromText(wkt, wkt_srid), local_srid))
    )
    data = query.first()

    return data is not None


@dfcheck
def check_geography(
    df,
    file_srid,
    geom_4326_field,
    geom_local_field,
    wkt_field=None,
    latitude_field=None,
    longitude_field=None,
    codecommune_field=None,
    codemaille_field=None,
    codedepartement_field=None,
    id_area: int = None,
):
    """
    What this check do:
    - check there is at least a wkt, a x/y or a code defined for each row
      (report NO-GEOM if there are not, or MULTIPLE_ATTACHMENT_TYPE_CODE if several are defined)
    - set geom_local or geom_4326 or both (depending of file_srid) from wkt or x/y
      - check wkt validity
      - check x/y validity
    - check wkt & x/y bounding box
    What this check does not do (done later in SQL):
    - set geom_4326 & geom_local from code
      - verify code validity
    - set geom_4326 from geom_local, or reciprocally, depending of file_srid
    - set geom_point
    - check geom validity (ST_IsValid)
    FIXME: area from code are never checked in bounding box!
    """

    local_srid = db.session.execute(sa.func.Find_SRID("ref_geo", "l_areas", "geom")).scalar()
    file_srid_bounding_box = get_srid_bounding_box(file_srid)

    wkt_col = wkt_field.source_field if wkt_field else None
    latitude_col = latitude_field.source_field if latitude_field else None
    longitude_col = longitude_field.source_field if longitude_field else None
    codecommune_col = codecommune_field.source_field if codecommune_field else None
    codemaille_col = codemaille_field.source_field if codemaille_field else None
    codedepartement_col = codedepartement_field.source_field if codedepartement_field else None

    geom = pd.Series(name="geom", index=df.index, dtype="object")

    if wkt_col and wkt_col in df:
        wkt_mask = df[wkt_col].notnull()
        if wkt_mask.any():
            geom.loc[wkt_mask] = df[wkt_mask][wkt_col].apply(wkt_to_geometry)
            invalid_wkt = geom[wkt_mask & geom.isnull()]
            if not invalid_wkt.empty:
                yield {
                    "error_code": "INVALID_WKT",
                    "column": "WKT",
                    "invalid_rows": invalid_wkt,
                }
    else:
        wkt_mask = pd.Series(False, index=df.index)
    if latitude_col and latitude_col in df and longitude_col and longitude_col in df:
        # take xy when no wkt and xy are not null
        xy_mask = df[latitude_col].notnull() & df[longitude_col].notnull()
        if xy_mask.any():
            geom.loc[xy_mask] = df[xy_mask].apply(
                lambda row: xy_to_geometry(row[longitude_col], row[latitude_col]), axis=1
            )
            invalid_xy = df[xy_mask & geom.isnull()]
            if not invalid_xy.empty:
                yield {
                    "error_code": "INVALID_GEOMETRY",
                    "column": "longitude",
                    "invalid_rows": invalid_xy,
                }
    else:
        xy_mask = pd.Series(False, index=df.index)

    # Check multiple geo-referencement
    multiple_georef = df[wkt_mask & xy_mask]
    if len(multiple_georef):
        geom[wkt_mask & xy_mask] = None
        yield {
            "error_code": "MULTIPLE_ATTACHMENT_TYPE_CODE",
            "column": "Champs géométriques",
            "invalid_rows": multiple_georef,
        }

    # Check out-of-bound geo-referencement
    for mask, column in [(wkt_mask, "WKT"), (xy_mask, "longitude")]:
        bound = geom[mask & geom.notnull()].apply(
            partial(check_bound, bounding_box=file_srid_bounding_box)
        )
        out_of_bound = df[mask & ~bound]
        if len(out_of_bound):
            geom.loc[mask & ~bound] = None
            yield {
                "error_code": "GEOMETRY_OUT_OF_BOX",
                "column": column,
                "invalid_rows": out_of_bound,
            }

    if codecommune_col and codecommune_col in df:
        codecommune_mask = df[codecommune_col].notnull()
    else:
        codecommune_mask = pd.Series(False, index=df.index)
    if codemaille_col and codemaille_col in df:
        codemaille_mask = df[codemaille_col].notnull()
    else:
        codemaille_mask = pd.Series(False, index=df.index)
    if codedepartement_col and codedepartement_col in df:
        codedepartement_mask = df[codedepartement_col].notnull()
    else:
        codedepartement_mask = pd.Series(False, index=df.index)

    # Check for multiple code when no wkt or xy
    multiple_code = df[
        ~wkt_mask
        & ~xy_mask
        & (
            (codecommune_mask & codemaille_mask)
            | (codecommune_mask & codedepartement_mask)
            | (codemaille_mask & codedepartement_mask)
        )
    ]
    if len(multiple_code):
        yield {
            "error_code": "MULTIPLE_CODE_ATTACHMENT",
            "column": "Champs géométriques",
            "invalid_rows": multiple_code,
        }

    # Rows with no geom
    no_geom = df[
        ~wkt_mask & ~xy_mask & ~codecommune_mask & ~codemaille_mask & ~codedepartement_mask
    ]
    if len(no_geom):
        yield {
            "error_code": "NO-GEOM",
            "column": "Champs géométriques",
            "invalid_rows": no_geom,
        }

    if file_srid == 4326:
        geom_4326_col = geom_4326_field.dest_field
        df[geom_4326_col] = geom[geom.notna()].apply(
            lambda g: ST_GeomFromWKB(g.wkb, file_srid),
        )
        # geom_local will be defined in SQL
        return {geom_4326_col}
    elif file_srid == local_srid:
        geom_local_col = geom_local_field.dest_field
        df[geom_local_col] = geom[geom.notna()].apply(
            lambda g: ST_GeomFromWKB(g.wkb, file_srid),
        )
        # geom_4326 will be defined in SQL
        return {geom_local_col}
    else:
        geom_4326_col = geom_4326_field.dest_field
        geom_local_col = geom_local_field.dest_field
        df[geom_4326_col] = geom[geom.notna()].apply(
            lambda g: ST_Transform(ST_GeomFromWKB(g.wkb, file_srid), 4326),
        )
        df[geom_local_col] = geom[geom.notna()].apply(
            lambda g: ST_Transform(ST_GeomFromWKB(g.wkb, file_srid), local_srid),
        )
        return {geom_4326_col, geom_local_col}
