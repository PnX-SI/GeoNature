geonature.core.gn_synthese.utils.process
========================================

.. py:module:: geonature.core.gn_synthese.utils.process

.. autoapi-nested-parse::

   functions to insert update or delete data in table gn_synthese.synthese



Functions
---------

.. autoapisummary::

   geonature.core.gn_synthese.utils.process.import_from_table


Module Contents
---------------

.. py:function:: import_from_table(schema_name, table_name, field_name, value, limit=50)

   insert and/or update data in table gn_synthese.synthese
   from table <schema_name>.<table_name>
   for all rows satisfying the condition : <field_name> = <value>


