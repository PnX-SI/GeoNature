geonature.utils.schema
======================

.. py:module:: geonature.utils.schema


Classes
-------

.. autoapisummary::

   geonature.utils.schema.CruvedSchemaMixin


Module Contents
---------------

.. py:class:: CruvedSchemaMixin

   This mixin add a cruved field which serialize to a dict "{action: boolean}".
       example: {"C": False, "R": True, "U": True, "V": False, "E": True, "D": False}
   The schema must have a __module_code__ property (and optionally a __object_code__property)
   to indicate from which permissions must be verified.
   The model must have an has_instance_permission method which take the scope and retrurn a boolean.
   The cruved field is excluded by default and may be added to serialization with only=["+cruved"].


   .. py:attribute:: cruved


   .. py:method:: get_cruved(obj)


