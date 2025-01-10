geonature.core.gn_synthese.utils.blurring
=========================================

.. py:module:: geonature.core.gn_synthese.utils.blurring


Functions
---------

.. autoapisummary::

   geonature.core.gn_synthese.utils.blurring.split_blurring_precise_permissions
   geonature.core.gn_synthese.utils.blurring.build_sensitive_unsensitive_filters
   geonature.core.gn_synthese.utils.blurring.build_blurred_precise_geom_queries
   geonature.core.gn_synthese.utils.blurring.build_allowed_geom_cte
   geonature.core.gn_synthese.utils.blurring.build_synthese_obs_query


Module Contents
---------------

.. py:function:: split_blurring_precise_permissions(permissions)

   Return permissions respectively with and without sensitivity filter.


.. py:function:: build_sensitive_unsensitive_filters()

   Return where clauses for sensitive and non-sensitive observations.


.. py:function:: build_blurred_precise_geom_queries(filters, where_clauses: list = [], select_size_hierarchy=False)

.. py:function:: build_allowed_geom_cte(blurring_permissions, precise_permissions, blurred_geom_query, precise_geom_query, limit)

.. py:function:: build_synthese_obs_query(observations, allowed_geom_cte, limit)

