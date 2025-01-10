geonature.core.gn_meta.models.aframework
========================================

.. py:module:: geonature.core.gn_meta.models.aframework


Classes
-------

.. autoapisummary::

   geonature.core.gn_meta.models.aframework.TAcquisitionFramework


Module Contents
---------------

.. py:class:: TAcquisitionFramework

   Bases: :py:obj:`geonature.core.gn_meta.models.commons.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_acquisition_frameworks'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_acquisition_framework


   .. py:attribute:: unique_acquisition_framework_id


   .. py:attribute:: acquisition_framework_name


   .. py:attribute:: acquisition_framework_desc


   .. py:attribute:: id_nomenclature_territorial_level


   .. py:attribute:: territory_desc


   .. py:attribute:: keywords


   .. py:attribute:: id_nomenclature_financing_type


   .. py:attribute:: target_description


   .. py:attribute:: ecologic_or_geologic_target


   .. py:attribute:: acquisition_framework_parent_id


   .. py:attribute:: is_parent


   .. py:attribute:: opened


   .. py:attribute:: id_digitizer


   .. py:attribute:: acquisition_framework_start_date


   .. py:attribute:: acquisition_framework_end_date


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: initial_closing_date


   .. py:attribute:: creator


   .. py:attribute:: nomenclature_territorial_level


   .. py:attribute:: nomenclature_financing_type


   .. py:attribute:: cor_af_actor


   .. py:attribute:: cor_objectifs


   .. py:attribute:: cor_volets_sinp


   .. py:attribute:: cor_territories


   .. py:attribute:: bibliographical_references


   .. py:attribute:: t_datasets


   .. py:attribute:: datasets


   .. py:method:: user_actors()


   .. py:method:: organism_actors()


   .. py:method:: has_datasets()


   .. py:method:: has_child_acquisition_framework()


   .. py:method:: has_instance_permission(scope, _through_ds=True)


   .. py:method:: get_id(uuid_af)
      :staticmethod:


      return the acquisition framework's id
      from its UUID if exist or None



   .. py:method:: get_user_af(user, only_query=False, only_user=False)
      :staticmethod:


      get the af(s) where the user is actor (himself or with its organism - only himelsemf id only_use=True) or digitizer
      param:
        - user from TRole model
        - only_query: boolean (return the query not the id_datasets allowed if true)
        - only_user: boolean: return only the dataset where user himself is actor (not with its organoism)

      return: a list of id_dataset or a query



   .. py:method:: _get_read_scope(user=None)
      :classmethod:



   .. py:method:: filter_by_scope(scope, *, query, user=None)


   .. py:method:: filter_by_readable(*, query, user=None)

      Return the afs where the user has autorization via its CRUVED



   .. py:method:: filter_by_areas(areas, *, query)

      Filter meta by areas



   .. py:method:: filter_by_params(params={}, *, _ds_search=True, query=None)


