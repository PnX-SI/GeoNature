geonature.core.imports.checks.dataframe
=======================================

.. py:module:: geonature.core.imports.checks.dataframe


Submodules
----------

.. toctree::
   :maxdepth: 1

   /autoapi/geonature/core/imports/checks/dataframe/cast/index
   /autoapi/geonature/core/imports/checks/dataframe/core/index
   /autoapi/geonature/core/imports/checks/dataframe/dates/index
   /autoapi/geonature/core/imports/checks/dataframe/geometry/index
   /autoapi/geonature/core/imports/checks/dataframe/utils/index


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.dataframe.check_required_values
   geonature.core.imports.checks.dataframe.check_counts
   geonature.core.imports.checks.dataframe.check_datasets
   geonature.core.imports.checks.dataframe.check_geometry
   geonature.core.imports.checks.dataframe.check_types
   geonature.core.imports.checks.dataframe.concat_dates


Package Contents
----------------

.. py:function:: check_required_values(df: pandas.DataFrame, fields: Dict[str, geonature.core.imports.models.BibFields])

   Check if required values are present in the dataframe.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   fields : Dict[str, BibFields]
       Dictionary of fields to check.

   Yields
   ------
   dict
       Dictionary containing the error code, the column name and the invalid rows.

   Notes
   -----
   Field is mandatory if: ((field.mandatory AND NOT (ANY optional_cond is not NaN)) OR (ANY mandatory_cond is not NaN))
                      <=> ((field.mandatory AND       ALL optional_cond are NaN   ) OR (ANY mandatory_cond is not NaN))


.. py:function:: check_counts(df: pandas.DataFrame, count_min_field: str, count_max_field: str, default_count: int = None)

   Check if the value in the `count_min_field` is lower or equal to the value in the `count_max_field`

   | count_min_field | count_max_field |
   | --------------- | --------------- |
   | 0               | 2               | --> ok
   | 2               | 0               | --> provoke an error

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   count_min_field : BibField
       The field containing the minimum count.
   count_max_field : BibField
       The field containing the maximum count.
   default_count : object, optional
       The default count to use if a count is missing, by default None.

   Yields
   ------
   dict
       Dictionary containing the error code, the column name and the invalid rows.

   Returns
   ------
   set
       Set of columns updated.



.. py:function:: check_datasets(imprt: geonature.core.imports.models.TImports, df: pandas.DataFrame, uuid_field: geonature.core.imports.models.BibFields, id_field: geonature.core.imports.models.BibFields, module_code: str, object_code: Optional[str] = None) -> Set[str]

   Check if datasets exist and are authorized for the user and import.

   Parameters
   ----------
   imprt : TImports
       Import to check datasets for.
   df : pd.DataFrame
       Dataframe to check.
   uuid_field : BibFields
       Field containing dataset UUIDs.
   id_field : BibFields
       Field to fill with dataset IDs.
   module_code : str
       Module code to check datasets for.
   object_code : Optional[str], optional
       Object code to check datasets for, by default None.

   Yields
   ------
   dict
       Dictionary containing error code, column name and invalid rows.

   Returns
   ------
   Set[str]
       Set of columns updated.



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



.. py:function:: check_types(entity: geonature.core.imports.models.Entity, df: pandas.DataFrame, fields: Dict[str, geonature.core.imports.models.BibFields]) -> Set[str]

   Check the types of columns in a dataframe based on the provided fields.

   Parameters
   ----------
   entity : Entity
       The entity to check.
   df : pd.DataFrame
       The dataframe to check.
   fields : Dict[str, BibFields]
       A dictionary mapping column names to their corresponding BibFields.

   Returns
   -------
   Set[str]
       Set containing the names of updated columns.


.. py:function:: concat_dates(df: pandas.DataFrame, datetime_min_col: str, datetime_max_col: str, date_min_col: str, date_max_col: str = None, hour_min_col: str = None, hour_max_col: str = None)

   Concatenates date and time columns to form datetime columns.

   Parameters
   ----------
   df : pandas.DataFrame
       The input DataFrame.
   datetime_min_col : str
       The column name for the minimum datetime.
   datetime_max_col : str
       The column name for the maximum datetime.
   date_min_col : str
       The column name for the minimum date.
   date_max_col : str, optional
       The column name for the maximum date.
   hour_min_col : str, optional
       The column name for the minimum hour.
   hour_max_col : str, optional
       The column name for the maximum hour.



