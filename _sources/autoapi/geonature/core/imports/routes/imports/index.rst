geonature.core.imports.routes.imports
=====================================

.. py:module:: geonature.core.imports.routes.imports


Attributes
----------

.. autoapisummary::

   geonature.core.imports.routes.imports.IMPORTS_PER_PAGE


Functions
---------

.. autoapisummary::

   geonature.core.imports.routes.imports.resolve_import
   geonature.core.imports.routes.imports.get_import_list
   geonature.core.imports.routes.imports.get_one_import
   geonature.core.imports.routes.imports.upload_file
   geonature.core.imports.routes.imports.decode_file
   geonature.core.imports.routes.imports.set_import_field_mapping
   geonature.core.imports.routes.imports.load_import
   geonature.core.imports.routes.imports.get_import_columns_name
   geonature.core.imports.routes.imports.get_import_values
   geonature.core.imports.routes.imports.set_import_content_mapping
   geonature.core.imports.routes.imports.prepare_import
   geonature.core.imports.routes.imports.preview_valid_data
   geonature.core.imports.routes.imports.get_import_errors
   geonature.core.imports.routes.imports.get_import_source_file
   geonature.core.imports.routes.imports.get_import_invalid_rows_as_csv
   geonature.core.imports.routes.imports.import_valid_data
   geonature.core.imports.routes.imports.delete_import
   geonature.core.imports.routes.imports.export_pdf
   geonature.core.imports.routes.imports.get_foreign_key_attr
   geonature.core.imports.routes.imports.report_plot


Module Contents
---------------

.. py:data:: IMPORTS_PER_PAGE
   :value: 15


.. py:function:: resolve_import(endpoint, values)

.. py:function:: get_import_list(scope, destination=None)

   .. :quickref: Import; Get all imports.

   Get all imports to which logged-in user has access.


.. py:function:: get_one_import(scope, imprt)

   .. :quickref: Import; Get an import.

   Get an import.


.. py:function:: upload_file(scope, imprt, destination=None)

   .. :quickref: Import; Add an import or update an existing import.

   Add an import or update an existing import.

   :form file: file to import
   :form int datasetId: dataset ID to which import data


.. py:function:: decode_file(scope, imprt)

.. py:function:: set_import_field_mapping(scope, imprt)

.. py:function:: load_import(scope, imprt)

.. py:function:: get_import_columns_name(scope, imprt)

   .. :quickref: Import;

   Return all the columns of the file of an import


.. py:function:: get_import_values(scope, imprt)

   .. :quickref: Import;

   Return all values present in imported file for nomenclated fields


.. py:function:: set_import_content_mapping(scope, imprt)

.. py:function:: prepare_import(scope, imprt)

   Prepare data to be imported: apply all checks and transformations.


.. py:function:: preview_valid_data(scope, imprt)

   Preview valid data for a given import.

   Parameters
   ----------
   scope : int
       The scope of the (C, "IMPORT", "IMPORT") permission for the current user.
   imprt : geonature.core.imports.models.TImports
       The import object.
   Returns
   -------
   flask.wrappers.Response
       A JSON response containing valid data, entities, columns, and data statistics.
   Raises
   ------
   Forbidden
       If the current user has no sufficient permission given the scope and the import object.
   Conflict
       If the import is not processed, i.e. it has not been prepared yet.


.. py:function:: get_import_errors(scope, imprt)

   .. :quickref: Import; Get errors of an import.

   Get errors of an import.


.. py:function:: get_import_source_file(scope, imprt)

.. py:function:: get_import_invalid_rows_as_csv(scope, imprt)

   .. :quickref: Import; Get invalid rows of an import as CSV.

   Export invalid data in CSV.


.. py:function:: import_valid_data(scope, imprt)

   .. :quickref: Import; Import the valid data.

   Import valid data in destination table.


.. py:function:: delete_import(scope, imprt)

   .. :quickref: Import; Delete an import.

   Delete an import.


.. py:function:: export_pdf(scope, imprt)

   Downloads the report in pdf format


.. py:function:: get_foreign_key_attr(obj, field: str)

   Go through a object path to find the class to order on


.. py:function:: report_plot(scope, imprt: geonature.core.imports.models.TImports)

