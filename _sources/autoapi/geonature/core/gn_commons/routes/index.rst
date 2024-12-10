geonature.core.gn_commons.routes
================================

.. py:module:: geonature.core.gn_commons.routes


Attributes
----------

.. autoapisummary::

   geonature.core.gn_commons.routes.routes


Functions
---------

.. autoapisummary::

   geonature.core.gn_commons.routes.config_route
   geonature.core.gn_commons.routes.list_modules
   geonature.core.gn_commons.routes.get_module
   geonature.core.gn_commons.routes.get_parameters_list
   geonature.core.gn_commons.routes.get_one_parameter
   geonature.core.gn_commons.routes.get_additional_fields
   geonature.core.gn_commons.routes.get_t_mobile_apps
   geonature.core.gn_commons.routes.api_get_id_table_location
   geonature.core.gn_commons.routes.list_places
   geonature.core.gn_commons.routes.add_place
   geonature.core.gn_commons.routes.delete_place


Module Contents
---------------

.. py:data:: routes

.. py:function:: config_route()

   Returns geonature configuration


.. py:function:: list_modules()

   Return the allowed modules of user from its cruved
   .. :quickref: Commons;



.. py:function:: get_module(module_code)

.. py:function:: get_parameters_list()

   Get all parameters from gn_commons.t_parameters

   .. :quickref: Commons;


.. py:function:: get_one_parameter(param_name, id_org=None)

.. py:function:: get_additional_fields()

.. py:function:: get_t_mobile_apps()

   Get all mobile applications

   .. :quickref: Commons;

   :query str app_code: the app code
   :returns: Array<dict<TMobileApps>>


.. py:function:: api_get_id_table_location(schema_dot_table)

.. py:function:: list_places()

.. py:function:: add_place()

.. py:function:: delete_place(id_place)

