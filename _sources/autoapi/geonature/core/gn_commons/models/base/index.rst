geonature.core.gn_commons.models.base
=====================================

.. py:module:: geonature.core.gn_commons.models.base

.. autoapi-nested-parse::

   Modèles du schéma gn_commons



Attributes
----------

.. autoapisummary::

   geonature.core.gn_commons.models.base.cor_module_dataset
   geonature.core.gn_commons.models.base.last_validation_query
   geonature.core.gn_commons.models.base.last_validation
   geonature.core.gn_commons.models.base.cor_field_object
   geonature.core.gn_commons.models.base.cor_field_module
   geonature.core.gn_commons.models.base.cor_field_dataset


Classes
-------

.. autoapisummary::

   geonature.core.gn_commons.models.base.BibTablesLocation
   geonature.core.gn_commons.models.base.CorModuleDataset
   geonature.core.gn_commons.models.base.TModules
   geonature.core.gn_commons.models.base.TMedias
   geonature.core.gn_commons.models.base.TParameters
   geonature.core.gn_commons.models.base.TValidations
   geonature.core.gn_commons.models.base.VLatestValidations
   geonature.core.gn_commons.models.base.THistoryActions
   geonature.core.gn_commons.models.base.TMobileApps
   geonature.core.gn_commons.models.base.TPlaces
   geonature.core.gn_commons.models.base.BibWidgets


Functions
---------

.. autoapisummary::

   geonature.core.gn_commons.models.base._resolve_import_cor_object_module


Module Contents
---------------

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

