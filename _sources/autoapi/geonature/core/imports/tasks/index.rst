geonature.core.imports.tasks
============================

.. py:module:: geonature.core.imports.tasks


Attributes
----------

.. autoapisummary::

   geonature.core.imports.tasks.logger


Functions
---------

.. autoapisummary::

   geonature.core.imports.tasks.do_import_checks
   geonature.core.imports.tasks.do_import_in_destination
   geonature.core.imports.tasks.notify_import_done


Module Contents
---------------

.. py:data:: logger

.. py:function:: do_import_checks(self, import_id)

   Verify the import data.

   Parameters
   ----------
   import_id : int
       The ID of the import to verify.


.. py:function:: do_import_in_destination(self, import_id)

   Insert valid transient data into the destination of an import.

   Parameters
   ----------
   import_id : int
       The ID of the import to insert data into the destination.


.. py:function:: notify_import_done(imprt: geonature.core.imports.models.TImports)

   Notify the authors of an import that it has finished.

   Parameters
   ----------
   imprt : TImports
       The import that has finished.



