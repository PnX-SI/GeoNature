geonature.core.imports.checks.dataframe.geometry
================================================

.. py:module:: geonature.core.imports.checks.dataframe.geometry


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.dataframe.geometry.get_srid_bounding_box
   geonature.core.imports.checks.dataframe.geometry.wkt_to_geometry
   geonature.core.imports.checks.dataframe.geometry.xy_to_geometry
   geonature.core.imports.checks.dataframe.geometry.check_bound
   geonature.core.imports.checks.dataframe.geometry.check_geometry_inside_l_areas
   geonature.core.imports.checks.dataframe.geometry.check_wkt_inside_area_id
   geonature.core.imports.checks.dataframe.geometry.check_geometry


Module Contents
---------------

.. py:function:: get_srid_bounding_box(srid)

   Return the local bounding box for a given srid


.. py:function:: wkt_to_geometry(value)

.. py:function:: xy_to_geometry(x, y)

.. py:function:: check_bound(p, bounding_box: shapely.geometry.Polygon)

.. py:function:: check_geometry_inside_l_areas(geometry: shapely.geometry.base.BaseGeometry, id_area: int, geom_srid: int)

   Same as `check_wkt_inside_l_areas` except we use a shapely geometry.


.. py:function:: check_wkt_inside_area_id(wkt: str, id_area: int, wkt_srid: int)

   Checks if the provided wkt is inside the area defined
   by id_area.

   Parameters
   ----------
   wkt : str
       geometry to check if inside the area
   id_area : int
       id to get the area in ref_geo.l_areas
   wkt_srid : str
       srid of the provided wkt


.. py:function:: check_geometry(df: pandas.DataFrame, file_srid: int, geom_4326_field: geonature.core.imports.models.BibFields, geom_local_field: geonature.core.imports.models.BibFields, wkt_field: geonature.core.imports.models.BibFields = None, latitude_field: geonature.core.imports.models.BibFields = None, longitude_field: geonature.core.imports.models.BibFields = None, codecommune_field: geonature.core.imports.models.BibFields = None, codemaille_field: geonature.core.imports.models.BibFields = None, codedepartement_field: geonature.core.imports.models.BibFields = None, id_area: int = None)

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

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check
   file_srid : int
       The srid of the file
   geom_4326_field : BibFields
       The column in the dataframe that contains geometries in SRID 4326
   geom_local_field : BibFields
       The column in the dataframe that contains geometries in the SRID of the area
   wkt_field : BibFields, optional
       The column in the dataframe that contains geometries' WKT
   latitude_field : BibFields, optional
       The column in the dataframe that contains latitudes
   longitude_field : BibFields, optional
       The column in the dataframe that contains longitudes
   codecommune_field : BibFields, optional
       The column in the dataframe that contains commune codes
   codemaille_field : BibFields, optional
       The column in the dataframe that contains maille codes
   codedepartement_field : BibFields, optional
       The column in the dataframe that contains departement codes
   id_area : int, optional
       The id of the area to check if the geometry is inside (Not Implemented)



