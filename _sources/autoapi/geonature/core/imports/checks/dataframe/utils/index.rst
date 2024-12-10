geonature.core.imports.checks.dataframe.utils
=============================================

.. py:module:: geonature.core.imports.checks.dataframe.utils


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.dataframe.utils.dataframe_check
   geonature.core.imports.checks.dataframe.utils.error_replace
   geonature.core.imports.checks.dataframe.utils.report_error


Module Contents
---------------

.. py:function:: dataframe_check(check_function)

   Decorator for check functions.
   Check functions must yield errors, and return updated_cols
   (or None if no column have been modified).


.. py:function:: error_replace(old_code, old_columns, new_code, new_column=None)

   For rows which trigger old_code error on all old_columns, these errors are replaced
   by new_code error on new_column.
   Usage example:
       @dataframe_check
       @error_replace(ImportCodeError.MISSING_VALUE, {"WKT","latitude","longitude"}, ImportCodeError.NO_GEOM, "Champs géométriques")
       def check_required_values:
           …
       => MISSING_VALUE on WKT, latitude and longitude are replaced by NO-GEOM on "Champs géométrique"
   If new_code is None, error is deleted


.. py:function:: report_error(imprt, entity, df, error)

   Reports an error found in the dataframe, updates the validity column and insert
   the error in the `t_user_errors` table.

   Parameters
   ----------
   imprt : Import
       The import entity.
   entity : Entity
       The entity to check.
   df : pandas.DataFrame
       The dataframe containing the data.
   error : dict
       The error to report. It should have the following keys:
       - invalid_rows : DataFrame
           The rows with errors.
       - error_code : str
           The name of the error code.
       - column : str
           The column with errors.
       - comment : str, optional
           A comment to add to the error.

   Returns
   -------
   set
       set containing the name of the entity validity column.

   Raises
   ------
   Exception
       If the error code is not found.


