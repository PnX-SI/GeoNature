geonature.core.imports.checks.sql.utils
=======================================

.. py:module:: geonature.core.imports.checks.sql.utils


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.sql.utils.get_duplicates_query
   geonature.core.imports.checks.sql.utils.report_erroneous_rows


Module Contents
---------------

.. py:function:: get_duplicates_query(imprt, dest_field, whereclause=sa.true())

.. py:function:: report_erroneous_rows(imprt, entity, error_type, error_column, whereclause, level_validity_mapping={'ERROR': False})

   This function report errors where whereclause in true.
   But the function also set validity column to False for errors with ERROR level.
   Warning: level of error "ERROR", the entity must be defined

   level_validity_mapping may be used to override default behavior:
     - level does not exist in dict: row validity is untouched
     - level exists in dict: row validity is set accordingly:
       - False: row is marked as erroneous
       - None: row is marked as should not be imported


