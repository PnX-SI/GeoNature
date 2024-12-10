geonature.core.imports.checks.dataframe.cast
============================================

.. py:module:: geonature.core.imports.checks.dataframe.cast


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.dataframe.cast.convert_to_datetime
   geonature.core.imports.checks.dataframe.cast.convert_to_uuid
   geonature.core.imports.checks.dataframe.cast.convert_to_integer
   geonature.core.imports.checks.dataframe.cast.check_datetime_field
   geonature.core.imports.checks.dataframe.cast.check_uuid_field
   geonature.core.imports.checks.dataframe.cast.check_integer_field
   geonature.core.imports.checks.dataframe.cast.check_numeric_field
   geonature.core.imports.checks.dataframe.cast.check_unicode_field
   geonature.core.imports.checks.dataframe.cast.check_boolean_field
   geonature.core.imports.checks.dataframe.cast.check_anytype_field
   geonature.core.imports.checks.dataframe.cast.check_types


Module Contents
---------------

.. py:function:: convert_to_datetime(value_raw)

   Try to convert a date string to a datetime object.
   If the input string does not match any of compatible formats, it will return
   None.

   Parameters
   ----------
   value_raw : str
       The input string to convert

   Returns
   -------
   converted_date : datetime or None
       The converted datetime object or None if the conversion failed


.. py:function:: convert_to_uuid(value)

.. py:function:: convert_to_integer(value)

.. py:function:: check_datetime_field(df: pandas.DataFrame, source_field: str, target_field: str, required: bool) -> Set[str]

   Check if a column is a datetime and convert it to datetime type.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   source_field : str
       The name of the column to check.
   target_field : str
       The name of the column where to store the result.
   required : bool
       Whether the column is mandatory or not.

   Yields
   ------
   dict
       A dictionary containing an error code, the column name, and the invalid rows.

   Returns
   -------
   set
       Set containing the name of the target field.

   Notes
   -----
   The error codes are:
       - INVALID_DATE: the value is not of datetime type.


.. py:function:: check_uuid_field(df: pandas.DataFrame, source_field: str, target_field: str, required: bool) -> Set[str]

   Check if a column is a UUID and convert it to UUID type.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   source_field : str
       The name of the column to check.
   target_field : str
       The name of the column where to store the result.
   required : bool
       Whether the column is mandatory or not.

   Yields
   ------
   dict
       A dictionary containing an error code, the column name, and the invalid rows.

   Returns
   -------
   set
       Set containing the name of the target field.

   Notes
   -----
   The error codes are:
       - INVALID_UUID: the value is not a valid UUID.


.. py:function:: check_integer_field(df: pandas.DataFrame, source_field: str, target_field: str, required: bool) -> Set[str]

   Check if a column is an integer and convert it to integer type.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   source_field : str
       The name of the column to check.
   target_field : str
       The name of the column where to store the result.
   required : bool
       Whether the column is mandatory or not.

   Yields
   ------
   dict
       A dictionary containing an error code, the column name, and the invalid rows.

   Returns
   -------
   set
       Set containing the name of the target field.

   Notes
   -----
   The error codes are:
       - INVALID_INTEGER: the value is not of integer type.


.. py:function:: check_numeric_field(df: pandas.DataFrame, source_field: str, target_field: str, required: bool) -> Set[str]

   Check if column string values are numerics and convert it to numeric type.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   source_field : str
       The name of the column to check.
   target_field : str
       The name of the column where to store the result.
   required : bool
       Whether the column is mandatory or not.

   Yields
   ------
   dict
       A dictionary containing an error code, the column name, and the invalid rows.

   Returns
   -------
   set
       Set containing the name of the target field.

   Notes
   -----
   The error codes are:
       - INVALID_NUMERIC: the value is not of numeric type.


.. py:function:: check_unicode_field(df: pandas.DataFrame, field: str, field_length: Optional[int]) -> Iterator[Dict[str, Any]]

   Check if column values have the right length.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   field : str
       The name of the column to check.
   field_length : Optional[int]
       The maximum length of the column.

   Yields
   ------
   dict
       A dictionary containing an error code, the column name, and the invalid rows.
   Notes
   -----
   The error codes are:
       - INVALID_CHAR_LENGTH: the string is too long.


.. py:function:: check_boolean_field(df, source_col, dest_col, required)

   Check a boolean field in a dataframe.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   source_col : str
       The name of the column to check.
   dest_col : str
       The name of the column where to store the result.
   required : bool
       Whether the column is mandatory or not.

   Yields
   ------
   dict
       A dictionary containing an error code and the rows with errors.

   Notes
   -----
   The error codes are:
       - MISSING_VALUE: the value is mandatory but it's missing (null).
       - INVALID_BOOL: the value is not a boolean.



.. py:function:: check_anytype_field(df: pandas.DataFrame, field_type: sqlalchemy.sql.sqltypes.TypeEngine, source_col: str, dest_col: str, required: bool) -> Set[str]

   Check a field in a dataframe according to its type.

   Parameters
   ----------
   df : pandas.DataFrame
       The dataframe to check.
   field_type : sqlalchemy.TypeEngine
       The type of the column to check.
   source_col : str
       The name of the column to check.
   dest_col : str
       The name of the column where to store the result.
   required : bool
       Whether the column is mandatory or not.

   Yields
   ------
   dict
       A dictionary containing an error code and the rows with errors.

   Returns
   -------
   set
       Set containing the name of columns updated in the dataframe.


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


