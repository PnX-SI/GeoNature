geonature.core.gn_commons.admin
===============================

.. py:module:: geonature.core.gn_commons.admin


Attributes
----------

.. autoapisummary::

   geonature.core.gn_commons.admin.log


Classes
-------

.. autoapisummary::

   geonature.core.gn_commons.admin.TAdditionalFieldsForm
   geonature.core.gn_commons.admin.BibFieldAdmin
   geonature.core.gn_commons.admin.TMobileAppsAdmin
   geonature.core.gn_commons.admin.TModulesAdmin


Module Contents
---------------

.. py:data:: log

.. py:class:: TAdditionalFieldsForm

   Bases: :py:obj:`flask_admin.form.BaseForm`


   .. py:method:: validate(extra_validators=None)


.. py:class:: BibFieldAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'ADDITIONAL_FIELDS'



   .. py:attribute:: form_base_class


   .. py:attribute:: form_columns
      :value: ('field_name', 'field_label', 'type_widget', 'modules', 'objects', 'datasets', 'required',...



   .. py:attribute:: column_exclude_list
      :value: ('field_values', 'additional_attributes', 'key_label', 'key_value', 'multiselect', 'api',...



   .. py:attribute:: column_display_all_relations
      :value: True



   .. py:attribute:: form_args


   .. py:attribute:: column_descriptions


.. py:class:: TMobileAppsAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'MOBILE_APPS'



   .. py:attribute:: column_list
      :value: ('app_code', 'relative_path_apk', 'url_apk', 'package', 'version_code')



   .. py:attribute:: column_labels


   .. py:attribute:: form_columns
      :value: ('app_code', 'relative_path_apk', 'url_apk', 'package', 'version_code')



   .. py:attribute:: column_exclude_list
      :value: 'id_mobile_app'



.. py:class:: TModulesAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'MODULES'



   .. py:attribute:: can_view_details
      :value: True



   .. py:attribute:: action_disallowed_list
      :value: ['delete']



   .. py:attribute:: can_create
      :value: False



   .. py:attribute:: can_delete
      :value: False



   .. py:attribute:: column_searchable_list
      :value: ('module_code', 'module_label')



   .. py:attribute:: column_default_sort
      :value: [('module_order', False), ('id_module', False)]



   .. py:attribute:: column_sortable_list
      :value: ('module_order', 'module_code', 'module_label')



   .. py:attribute:: column_list
      :value: ('module_code', 'module_label', 'module_picto', 'module_order')



   .. py:attribute:: column_details_list
      :value: ('module_code', 'module_label', 'module_desc', 'module_comment', 'module_picto',...



   .. py:attribute:: form_columns
      :value: ('module_label', 'module_desc', 'module_comment', 'module_picto', 'module_doc_url', 'module_order')



   .. py:attribute:: column_labels


