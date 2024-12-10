geonature.core.imports.routes.mappings
======================================

.. py:module:: geonature.core.imports.routes.mappings


Functions
---------

.. autoapisummary::

   geonature.core.imports.routes.mappings.check_mapping_type
   geonature.core.imports.routes.mappings.list_mappings
   geonature.core.imports.routes.mappings.get_mapping
   geonature.core.imports.routes.mappings.add_mapping
   geonature.core.imports.routes.mappings.update_mapping
   geonature.core.imports.routes.mappings.delete_mapping


Module Contents
---------------

.. py:function:: check_mapping_type(endpoint, values)

.. py:function:: list_mappings(destination, mappingtype, scope)

   .. :quickref: Import; Return all active named mappings.

   Return all active named (non-temporary) mappings.

   :param type: Filter mapping of the given type.
   :type type: str


.. py:function:: get_mapping(mapping, scope)

   .. :quickref: Import; Return a mapping.

   Return a mapping. Mapping has to be active.


.. py:function:: add_mapping(destination, mappingtype, scope)

   .. :quickref: Import; Add a mapping.


.. py:function:: update_mapping(mapping, scope)

   .. :quickref: Import; Update a mapping (label and/or content).


.. py:function:: delete_mapping(mapping, scope)

   .. :quickref: Import; Delete a mapping.


