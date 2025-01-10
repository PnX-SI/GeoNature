geonature.core.imports.utils
============================

.. py:module:: geonature.core.imports.utils


Attributes
----------

.. autoapisummary::

   geonature.core.imports.utils.generated_fields


Classes
-------

.. autoapisummary::

   geonature.core.imports.utils.ImportStep


Functions
---------

.. autoapisummary::

   geonature.core.imports.utils.clean_import
   geonature.core.imports.utils.get_file_size
   geonature.core.imports.utils.detect_encoding
   geonature.core.imports.utils.detect_separator
   geonature.core.imports.utils.preprocess_value
   geonature.core.imports.utils.insert_import_data_in_transient_table
   geonature.core.imports.utils.build_fieldmapping
   geonature.core.imports.utils.load_transient_data_in_dataframe
   geonature.core.imports.utils.update_transient_data_from_dataframe
   geonature.core.imports.utils.generate_pdf_from_template
   geonature.core.imports.utils.get_mapping_data
   geonature.core.imports.utils.get_required
   geonature.core.imports.utils.compute_bounding_box


Module Contents
---------------

.. py:class:: ImportStep

   Bases: :py:obj:`enum.IntEnum`


   Enum where members are also (and must be) ints


   .. py:attribute:: UPLOAD
      :value: 1



   .. py:attribute:: DECODE
      :value: 2



   .. py:attribute:: LOAD
      :value: 3



   .. py:attribute:: PREPARE
      :value: 4



   .. py:attribute:: IMPORT
      :value: 5



.. py:data:: generated_fields

.. py:function:: clean_import(imprt: geonature.core.imports.models.TImports, step: ImportStep) -> None

   Clean an import at a specific step.

   Parameters
   ----------
   imprt : TImports
       The import to clean.
   step : ImportStep
       The step at which to clean the import.



.. py:function:: get_file_size(file_: IO) -> int

   Get the size of a file in bytes.

   Parameters
   ----------
   file_ : IO
       The file to get the size of.

   Returns
   -------
   int
       The size of the file in bytes.



.. py:function:: detect_encoding(file_: IO) -> str

   Detects the encoding of a file.

   Parameters
   ----------
   file_ : IO
       The file to detect the encoding of.

   Returns
   -------
   str
       The detected encoding. If no encoding is detected, then "UTF-8" is returned.



.. py:function:: detect_separator(file_: IO, encoding: str) -> Optional[str]

   Detects the delimiter used in a CSV file.

   Parameters
   ----------
   file_ : IO
       The file object to detect the delimiter of.
   encoding : str
       The encoding of the file.

   Returns
   -------
   Optional[str]
       The delimiter used in the file, or None if no delimiter is detected.

   Raises
   ------
   BadRequest
       If the file starts with no column names.



.. py:function:: preprocess_value(dataframe: pandas.DataFrame, field: geonature.core.imports.models.BibFields, source_col: str) -> pandas.Series

   Preprocesses values in a DataFrame depending if the field contains multiple values (e.g. additional_data) or not.

   Parameters
   ----------
   dataframe : pd.DataFrame
       The DataFrame to preprocess the value of.
   field : BibFields
       The field to preprocess.
   source_col : str
       The column to preprocess.

   Returns
   -------
   pd.Series
       The preprocessed value.



.. py:function:: insert_import_data_in_transient_table(imprt: geonature.core.imports.models.TImports) -> int

   Insert the data from the import file into the transient table.

   Parameters
   ----------
   imprt : TImports
       current import

   Returns
   -------
   int
       The last line number of the import file that was inserted.


.. py:function:: build_fieldmapping(imprt: geonature.core.imports.models.TImports, columns: Iterable[Any]) -> Tuple[Dict[str, Dict[str, Any]], List[str]]

   Build a dictionary that maps the source column names to the corresponding field and values.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   columns : Iterable[Any]
       The columns to map.

   Returns
   -------
   tuple
       A tuple containing a dictionary that maps the source column names to the corresponding field and values,
       and a list of the used columns.



.. py:function:: load_transient_data_in_dataframe(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, source_cols: list, offset: int = None, limit: int = None)

   Load data from the transient table into a pandas dataframe.

   Parameters
   ----------
   imprt : TImports
       The import to load.
   entity : Entity
       The entity to load.
   source_cols : list
       The columns to load from the transient table.
   offset : int, optional
       The number of rows to skip.
   limit : int, optional
       The maximum number of rows to load.

   Returns
   -------
   pandas.DataFrame
       The dataframe containing the loaded data.


.. py:function:: update_transient_data_from_dataframe(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, updated_cols: Set[str], dataframe: pandas.DataFrame)

   Update the transient table with the data from the dataframe.

   Parameters
   ----------
   imprt : TImports
       The import to update.
   entity : Entity
       The entity to update.
   updated_cols : list
       The columns to update.
   df : pandas.DataFrame
       The dataframe to use for the update.

   Notes
   -----
   The dataframe must have the columns 'id_import' and 'line_no'.


.. py:function:: generate_pdf_from_template(template: str, data: Any) -> bytes

   Generate a PDF document from a template.

   Parameters
   ----------
   template : str
       The name of the template file to use.
   data : Any
       The data to pass to the template.

   Returns
   -------
   bytes
       The PDF document as bytes.


.. py:function:: get_mapping_data(import_: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity)

   Get the mapping data for a given import and entity.

   Parameters
   ----------
   import_ : TImports
       The import to get the mapping data for.
   entity : Entity
       The entity to get the mapping data for.

   Returns
   -------
   fields : dict
       A dictionary with the all fields associated with an entity (check gn_imports.bib_fields). This dictionary is keyed by the name field and valued by the corresponding BibField object.
   selected_fields : dict
       In the same format as fields, but only the fields contained in the mapping.
   source_cols : list
       List of fields to load in dataframe, mainly source column of non-nomenclature fields


.. py:function:: get_required(import_: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity)

.. py:function:: compute_bounding_box(imprt: geonature.core.imports.models.TImports, geom_entity_code: str, geom_4326_field_name: str, *, child_entity_code: str = None, transient_where_clause=None, destination_where_clause=None)

   Compute the bounding box of an entity with a geometry in the given import, based on its
   entities tree (e.g. Station -> Habitat; Site -> Visite -> Observation).

   Parameters
   ----------
   imprt : TImports
       The import to get the bounding box of.
   geom_entity_code : str
       The code of the entity that contains the geometry.
   geom_4326_field_name : str
       The name of the column in the geom entity table that contains the geometry.
   child_entity_code : str, optional
       The code of the last child entity (of the geom entity) to consider when computing the bounding box. If not given,
       bounding-box will be computed only on the geom entity.
   transient_where_clause : sqlalchemy.sql.elements.BooleanClauseList, optional
       A where clause to apply to the query when computing the bounding box of a processed import.
   destination_where_clause : sqlalchemy.sql.elements.BooleanClauseList, optional
       A where clause to apply to the query when computing the bounding box of a finished import.

   Returns
   -------
   valid_bbox : dict
       The bounding box of all entities in the given import, in GeoJSON format.


