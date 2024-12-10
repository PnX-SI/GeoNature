geonature.core.imports.checks.dataframe.core
============================================

.. py:module:: geonature.core.imports.checks.dataframe.core


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.dataframe.core.check_required_values
   geonature.core.imports.checks.dataframe.core.check_counts
   geonature.core.imports.checks.dataframe.core.check_datasets


Module Contents
---------------

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



