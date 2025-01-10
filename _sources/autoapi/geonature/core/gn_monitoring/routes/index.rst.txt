geonature.core.gn_monitoring.routes
===================================

.. py:module:: geonature.core.gn_monitoring.routes


Attributes
----------

.. autoapisummary::

   geonature.core.gn_monitoring.routes.routes


Functions
---------

.. autoapisummary::

   geonature.core.gn_monitoring.routes.get_list_sites
   geonature.core.gn_monitoring.routes.get_onelist_site
   geonature.core.gn_monitoring.routes.get_site_areas


Module Contents
---------------

.. py:data:: routes

.. py:function:: get_list_sites()

   Return the sites list for an application in a dict {id_base_site, nom site}
   .. :quickref: Monitoring;

   :param id_base_site: id of base site
   :param module_code: code of the module
   :param id_module: id of the module
   :param base_site_name: part of the name of the site
   :param type: int


.. py:function:: get_onelist_site(id_site)

   Get minimal information for a site {id_base_site, nom site}
   .. :quickref: Monitoring;

   :param id_site: id of base site
   :param type: int


.. py:function:: get_site_areas(id_site)

   Get areas of a site from cor_site_area as geojson

   .. :quickref: Monitoring;

   :param id_module: int
   :type id_module: int
   :param id_area_type:
   :type id_area_type: int


