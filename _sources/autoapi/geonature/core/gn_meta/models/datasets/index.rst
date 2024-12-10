geonature.core.gn_meta.models.datasets
======================================

.. py:module:: geonature.core.gn_meta.models.datasets


Classes
-------

.. autoapisummary::

   geonature.core.gn_meta.models.datasets.TDatasets


Module Contents
---------------

.. py:class:: TDatasets

   Bases: :py:obj:`geonature.core.gn_meta.models.commons.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_datasets'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_dataset


   .. py:attribute:: unique_dataset_id


   .. py:attribute:: id_acquisition_framework


   .. py:attribute:: acquisition_framework


   .. py:attribute:: dataset_name


   .. py:attribute:: dataset_shortname


   .. py:attribute:: dataset_desc


   .. py:attribute:: id_nomenclature_data_type


   .. py:attribute:: keywords


   .. py:attribute:: marine_domain


   .. py:attribute:: terrestrial_domain


   .. py:attribute:: id_nomenclature_dataset_objectif


   .. py:attribute:: bbox_west


   .. py:attribute:: bbox_east


   .. py:attribute:: bbox_south


   .. py:attribute:: bbox_north


   .. py:attribute:: id_nomenclature_collecting_method


   .. py:attribute:: id_nomenclature_data_origin


   .. py:attribute:: id_nomenclature_source_status


   .. py:attribute:: id_nomenclature_resource_type


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: active


   .. py:attribute:: validable


   .. py:attribute:: id_digitizer


   .. py:attribute:: digitizer


   .. py:attribute:: creator


   .. py:attribute:: id_taxa_list


   .. py:attribute:: modules


   .. py:attribute:: nomenclature_data_type


   .. py:attribute:: nomenclature_dataset_objectif


   .. py:attribute:: nomenclature_collecting_method


   .. py:attribute:: nomenclature_data_origin


   .. py:attribute:: nomenclature_source_status


   .. py:attribute:: nomenclature_resource_type


   .. py:attribute:: cor_territories


   .. py:attribute:: cor_dataset_actor


   .. py:attribute:: additional_fields


   .. py:method:: user_actors()


   .. py:method:: organism_actors()


   .. py:method:: is_deletable()


   .. py:method:: has_instance_permission(scope, _through_af=True)

      _through_af prevent infinite recursion



   .. py:method:: __str__()


   .. py:method:: get_id(uuid_dataset)
      :staticmethod:



   .. py:method:: get_uuid(id_dataset)
      :staticmethod:



   .. py:method:: _get_read_scope(user=None)
      :classmethod:



   .. py:method:: _get_create_scope(module_code, user=None, object_code=None)
      :classmethod:



   .. py:method:: filter_by_scope(scope, *, query, user=None)


   .. py:method:: filter_by_params(params={}, *, _af_search=True, query=None)


   .. py:method:: filter_by_readable(query, user=None)

      Return the datasets where the user has autorization via its CRUVED



   .. py:method:: filter_by_creatable(module_code, *, query, user=None, object_code=None)

      Return all dataset where user have read rights minus those who user to not have
      create rigth



   .. py:method:: filter_by_areas(areas, *, query)


