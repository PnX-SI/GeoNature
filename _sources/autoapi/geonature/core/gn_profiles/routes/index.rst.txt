geonature.core.gn_profiles.routes
=================================

.. py:module:: geonature.core.gn_profiles.routes


Attributes
----------

.. autoapisummary::

   geonature.core.gn_profiles.routes.routes


Functions
---------

.. autoapisummary::

   geonature.core.gn_profiles.routes.get_phenology
   geonature.core.gn_profiles.routes.get_profile
   geonature.core.gn_profiles.routes.get_consistancy_data
   geonature.core.gn_profiles.routes.get_observation_score
   geonature.core.gn_profiles.routes.update


Module Contents
---------------

.. py:data:: routes

.. py:function:: get_phenology(cd_ref)

   .. :quickref: Profiles;

   Get phenoliques periods for a given taxon



.. py:function:: get_profile(cd_ref)

   .. :quickref: Profiles;

   Return the profile for a cd_ref


.. py:function:: get_consistancy_data(id_synthese)

   .. :quickref: Profiles;

   Return the validation score for a synthese data


.. py:function:: get_observation_score()

   .. :quickref: Profiles;

   Check an observation with the related profile
   Return alert when the observation do not match the profile


.. py:function:: update()

