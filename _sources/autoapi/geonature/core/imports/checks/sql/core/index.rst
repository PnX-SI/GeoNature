geonature.core.imports.checks.sql.core
======================================

.. py:module:: geonature.core.imports.checks.sql.core


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.sql.core.init_rows_validity
   geonature.core.imports.checks.sql.core.check_orphan_rows


Module Contents
---------------

.. py:function:: init_rows_validity(imprt: geonature.core.imports.models.TImports, dataset_name_field: str = 'id_dataset')

   Validity columns are three-states:
     - None: the row does not contains data for the given entity
     - False: the row contains data for the given entity, but data are erroneous
     - True: the row contains data for the given entity, and data are valid


.. py:function:: check_orphan_rows(imprt)

