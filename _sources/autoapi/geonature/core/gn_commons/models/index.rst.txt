geonature.core.gn_commons.models
================================

.. py:module:: geonature.core.gn_commons.models


Submodules
----------

.. toctree::
   :maxdepth: 1

   /autoapi/geonature/core/gn_commons/models/additional_fields/index
   /autoapi/geonature/core/gn_commons/models/base/index


Attributes
----------

.. autoapisummary::

   geonature.core.gn_commons.models.cor_module_dataset
   geonature.core.gn_commons.models.last_validation_query
   geonature.core.gn_commons.models.last_validation
   geonature.core.gn_commons.models.cor_field_object
   geonature.core.gn_commons.models.cor_field_module
   geonature.core.gn_commons.models.cor_field_dataset
   geonature.core.gn_commons.models.cor_field_module
   geonature.core.gn_commons.models.cor_field_object
   geonature.core.gn_commons.models.cor_field_dataset


Classes
-------

.. autoapisummary::

   geonature.core.gn_commons.models.BibTablesLocation
   geonature.core.gn_commons.models.CorModuleDataset
   geonature.core.gn_commons.models.TModules
   geonature.core.gn_commons.models.TMedias
   geonature.core.gn_commons.models.TParameters
   geonature.core.gn_commons.models.TValidations
   geonature.core.gn_commons.models.VLatestValidations
   geonature.core.gn_commons.models.THistoryActions
   geonature.core.gn_commons.models.TMobileApps
   geonature.core.gn_commons.models.TPlaces
   geonature.core.gn_commons.models.BibWidgets
   geonature.core.gn_commons.models.TDatasets
   geonature.core.gn_commons.models.PermObject
   geonature.core.gn_commons.models.TAdditionalFields


Functions
---------

.. autoapisummary::

   geonature.core.gn_commons.models._resolve_import_cor_object_module


Package Contents
----------------

.. py:class:: BibTablesLocation

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_tables_location'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_table_location


   .. py:attribute:: table_desc


   .. py:attribute:: schema_name


   .. py:attribute:: table_name


   .. py:attribute:: pk_field


   .. py:attribute:: uuid_field_name


.. py:data:: cor_module_dataset

.. py:class:: CorModuleDataset

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'cor_module_dataset'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_module


   .. py:attribute:: id_dataset


.. py:function:: _resolve_import_cor_object_module()

.. py:class:: TModules

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_modules'



   .. py:attribute:: __table_args__


   .. py:class:: base_defaultdict

      Bases: :py:obj:`collections.defaultdict`


      Avoid polymorphic error when polymorphic identities are declared
      in database but absent from venv: fallback on base identity.
      Taken from CTFd.


      .. py:method:: __missing__(key)



   .. py:attribute:: type


   .. py:attribute:: __mapper_args__


   .. py:attribute:: id_module


   .. py:attribute:: module_code


   .. py:attribute:: module_label


   .. py:attribute:: module_picto


   .. py:attribute:: module_desc


   .. py:attribute:: module_group


   .. py:attribute:: module_path


   .. py:attribute:: module_external_url


   .. py:attribute:: module_target


   .. py:attribute:: module_comment


   .. py:attribute:: active_frontend


   .. py:attribute:: active_backend


   .. py:attribute:: module_doc_url


   .. py:attribute:: module_order


   .. py:attribute:: ng_module


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: objects


   .. py:method:: __str__()


.. py:class:: TMedias

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_medias'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_media


   .. py:attribute:: id_nomenclature_media_type


   .. py:attribute:: id_table_location


   .. py:attribute:: unique_id_media


   .. py:attribute:: uuid_attached_row


   .. py:attribute:: title_fr


   .. py:attribute:: title_en


   .. py:attribute:: title_it


   .. py:attribute:: title_es


   .. py:attribute:: title_de


   .. py:attribute:: media_url


   .. py:attribute:: media_path


   .. py:attribute:: author


   .. py:attribute:: description_fr


   .. py:attribute:: description_en


   .. py:attribute:: description_it


   .. py:attribute:: description_es


   .. py:attribute:: description_de


   .. py:attribute:: is_public


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:method:: base_dir()
      :staticmethod:



   .. py:method:: __before_commit_delete__()


   .. py:method:: remove_file(move=True)


   .. py:method:: remove_thumbnails()


.. py:class:: TParameters

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_parameters'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_parameter


   .. py:attribute:: id_organism


   .. py:attribute:: parameter_name


   .. py:attribute:: parameter_desc


   .. py:attribute:: parameter_value


   .. py:attribute:: parameter_extra_value


.. py:class:: TValidations

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_validations'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_validation


   .. py:attribute:: uuid_attached_row


   .. py:attribute:: id_nomenclature_valid_status


   .. py:attribute:: nomenclature_valid_status


   .. py:attribute:: id_validator


   .. py:attribute:: validator_role


   .. py:attribute:: validation_auto


   .. py:attribute:: validation_comment


   .. py:attribute:: validation_date


   .. py:attribute:: validation_label


   .. py:method:: auto_validation(fct_auto_validation)
      :staticmethod:



.. py:data:: last_validation_query

.. py:data:: last_validation

.. py:class:: VLatestValidations

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'v_latest_validation'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_validation


   .. py:attribute:: uuid_attached_row


   .. py:attribute:: id_nomenclature_valid_status


   .. py:attribute:: id_validator


   .. py:attribute:: validation_comment


   .. py:attribute:: validation_date


.. py:class:: THistoryActions

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_history_actions'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_history_action


   .. py:attribute:: id_table_location


   .. py:attribute:: uuid_attached_row


   .. py:attribute:: operation_type


   .. py:attribute:: operation_date


   .. py:attribute:: table_content


.. py:class:: TMobileApps

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_mobile_apps'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_mobile_app


   .. py:attribute:: app_code


   .. py:attribute:: relative_path_apk


   .. py:attribute:: url_apk


   .. py:attribute:: url_settings


   .. py:attribute:: package


   .. py:attribute:: version_code


.. py:class:: TPlaces

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_places'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_place


   .. py:attribute:: id_role


   .. py:attribute:: role


   .. py:attribute:: place_name


   .. py:attribute:: place_geom


.. py:class:: BibWidgets

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_widgets'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_widget


   .. py:attribute:: widget_name


   .. py:method:: __str__()


.. py:data:: cor_field_object

.. py:data:: cor_field_module

.. py:data:: cor_field_dataset

.. py:data:: cor_field_module

.. py:data:: cor_field_object

.. py:data:: cor_field_dataset

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


.. py:class:: PermObject

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_objects'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_object


   .. py:attribute:: code_object


   .. py:attribute:: description_object


   .. py:method:: __str__()


.. py:class:: TAdditionalFields

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_additional_fields'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_field


   .. py:attribute:: field_name


   .. py:attribute:: field_label


   .. py:attribute:: required


   .. py:attribute:: description


   .. py:attribute:: quantitative


   .. py:attribute:: unity


   .. py:attribute:: field_values


   .. py:attribute:: code_nomenclature_type


   .. py:attribute:: additional_attributes


   .. py:attribute:: id_widget


   .. py:attribute:: id_list


   .. py:attribute:: exportable


   .. py:attribute:: field_order


   .. py:attribute:: type_widget


   .. py:attribute:: bib_nomenclature_type


   .. py:attribute:: multiselect


   .. py:attribute:: api


   .. py:attribute:: default_value


   .. py:attribute:: modules


   .. py:attribute:: objects


   .. py:attribute:: datasets


   .. py:method:: __str__()


