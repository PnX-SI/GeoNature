geonature.core.gn_permissions.admin
===================================

.. py:module:: geonature.core.gn_permissions.admin


Classes
-------

.. autoapisummary::

   geonature.core.gn_permissions.admin.RoleFilter
   geonature.core.gn_permissions.admin.ModuleFilter
   geonature.core.gn_permissions.admin.ObjectFilter
   geonature.core.gn_permissions.admin.ActionFilter
   geonature.core.gn_permissions.admin.ScopeFilter
   geonature.core.gn_permissions.admin.OptionSelect2Widget
   geonature.core.gn_permissions.admin.OptionQuerySelectField
   geonature.core.gn_permissions.admin.UserAjaxModelLoader
   geonature.core.gn_permissions.admin.ObjectAdmin
   geonature.core.gn_permissions.admin.PermissionAdmin
   geonature.core.gn_permissions.admin.PermissionAvailableAdmin
   geonature.core.gn_permissions.admin.RolePermAdmin
   geonature.core.gn_permissions.admin.GroupPermAdmin
   geonature.core.gn_permissions.admin.UserPermAdmin


Functions
---------

.. autoapisummary::

   geonature.core.gn_permissions.admin.filters_formatter
   geonature.core.gn_permissions.admin.modules_formatter
   geonature.core.gn_permissions.admin.groups_formatter
   geonature.core.gn_permissions.admin.role_formatter
   geonature.core.gn_permissions.admin.permissions_formatter
   geonature.core.gn_permissions.admin.permissions_count_formatter


Module Contents
---------------

.. py:class:: RoleFilter

   Bases: :py:obj:`geonature.core.admin.utils.DynamicOptionsMixin`, :py:obj:`flask_admin.contrib.sqla.filters.FilterEqual`


   .. py:method:: get_dynamic_options(view)


.. py:class:: ModuleFilter

   Bases: :py:obj:`geonature.core.admin.utils.DynamicOptionsMixin`, :py:obj:`flask_admin.contrib.sqla.filters.FilterEqual`


   .. py:method:: get_dynamic_options(view)


.. py:class:: ObjectFilter

   Bases: :py:obj:`geonature.core.admin.utils.DynamicOptionsMixin`, :py:obj:`flask_admin.contrib.sqla.filters.FilterEqual`


   .. py:method:: get_dynamic_options(view)


.. py:class:: ActionFilter

   Bases: :py:obj:`geonature.core.admin.utils.DynamicOptionsMixin`, :py:obj:`flask_admin.contrib.sqla.filters.FilterEqual`


   .. py:method:: get_dynamic_options(view)


.. py:class:: ScopeFilter

   Bases: :py:obj:`geonature.core.admin.utils.DynamicOptionsMixin`, :py:obj:`flask_admin.contrib.sqla.filters.FilterEqual`


   .. py:method:: apply(query, value, alias=None)


   .. py:method:: get_dynamic_options(view)


.. py:function:: filters_formatter(v, c, m, p)

.. py:function:: modules_formatter(view, context, model, name)

.. py:function:: groups_formatter(view, context, model, name)

.. py:function:: role_formatter(view, context, model, name)

.. py:function:: permissions_formatter(view, context, model, name)

.. py:function:: permissions_count_formatter(view, context, model, name)

.. py:class:: OptionSelect2Widget

   Bases: :py:obj:`flask_admin.form.widgets.Select2Widget`


   .. py:method:: render_option(value, label, options)
      :classmethod:



.. py:class:: OptionQuerySelectField(*args, **kwargs)

   Bases: :py:obj:`flask_admin.contrib.sqla.fields.QuerySelectField`


   Overrides the QuerySelectField class from flask admin to allow
   other attributes on a select option.

   options_additional_values is added in form_args, it is a list of
   strings, each element is the name of the attribute in the model
   which will be added on the option


   .. py:attribute:: widget


   .. py:attribute:: options_additional_values


   .. py:method:: iter_choices()


.. py:class:: UserAjaxModelLoader

   Bases: :py:obj:`flask_admin.contrib.sqla.ajax.QueryAjaxModelLoader`


   .. py:method:: format(user)


   .. py:method:: get_query()


.. py:class:: ObjectAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'PERMISSIONS'



   .. py:attribute:: can_create
      :value: False



   .. py:attribute:: can_edit
      :value: False



   .. py:attribute:: can_delete
      :value: False



   .. py:attribute:: column_list
      :value: ('code_object', 'description_object', 'modules')



   .. py:attribute:: column_labels


   .. py:attribute:: column_default_sort
      :value: 'id_object'



   .. py:attribute:: column_formatters


.. py:class:: PermissionAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'PERMISSIONS'



   .. py:attribute:: column_list
      :value: ('role', 'module', 'object', 'action', 'label', 'filters')



   .. py:attribute:: column_labels


   .. py:attribute:: column_select_related_list
      :value: ('availability',)



   .. py:attribute:: column_searchable_list
      :value: ('role.identifiant', 'role.nom_complet')



   .. py:attribute:: column_formatters


   .. py:attribute:: column_filters


   .. py:attribute:: named_filter_urls
      :value: True



   .. py:attribute:: column_sortable_list
      :value: (('role', 'role.nom_complet'), ('module', 'module.module_code'), ('object',...



   .. py:attribute:: column_default_sort
      :value: [('role.nom_complet', False), ('module.module_code', False), ('object.code_object', False),...



   .. py:attribute:: form_columns
      :value: ('role', 'availability', 'scope', 'sensitivity_filter')



   .. py:attribute:: form_overrides


   .. py:attribute:: form_args


   .. py:attribute:: create_template
      :value: 'admin/hide_select2_options_create.html'



   .. py:attribute:: edit_template
      :value: 'admin/hide_select2_options_edit.html'



   .. py:attribute:: form_ajax_refs


   .. py:method:: render(template, **kwargs)


   .. py:method:: create_form()


.. py:class:: PermissionAvailableAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'PERMISSIONS'



   .. py:attribute:: can_create
      :value: False



   .. py:attribute:: can_delete
      :value: False



   .. py:attribute:: can_export
      :value: False



   .. py:attribute:: column_labels


   .. py:attribute:: column_formatters


   .. py:attribute:: column_sortable_list
      :value: (('module', 'module.module_code'), ('object', 'object.code_object'), ('action', 'action.code_action'))



   .. py:attribute:: column_filters


   .. py:attribute:: column_default_sort
      :value: [('module.module_code', False), ('object.code_object', False), ('id_action', False)]



   .. py:attribute:: form_columns
      :value: ('scope_filter', 'sensitivity_filter')



.. py:class:: RolePermAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'PERMISSIONS'



   .. py:attribute:: can_create
      :value: False



   .. py:attribute:: can_edit
      :value: False



   .. py:attribute:: can_delete
      :value: False



   .. py:attribute:: can_export
      :value: False



   .. py:attribute:: can_view_details
      :value: True



   .. py:attribute:: details_template
      :value: 'role_or_group_detail.html'



   .. py:attribute:: column_select_related_list
      :value: ('permissions',)



   .. py:attribute:: column_labels


   .. py:attribute:: column_searchable_list
      :value: ('identifiant', 'nom_complet')



   .. py:attribute:: column_formatters


   .. py:attribute:: column_formatters_detail


.. py:class:: GroupPermAdmin

   Bases: :py:obj:`RolePermAdmin`


   .. py:attribute:: column_list
      :value: ('nom_role', 'permissions_count')



   .. py:attribute:: column_details_list
      :value: ('nom_role', 'permissions_count', 'permissions')



   .. py:method:: get_query()


   .. py:method:: get_count_query()


.. py:class:: UserPermAdmin

   Bases: :py:obj:`RolePermAdmin`


   .. py:attribute:: column_list
      :value: ('identifiant', 'nom_role', 'prenom_role', 'groups', 'permissions_count')



   .. py:attribute:: column_labels


   .. py:attribute:: column_details_list
      :value: ('identifiant', 'nom_role', 'prenom_role', 'groups', 'permissions_count', 'permissions')



   .. py:method:: get_query()


   .. py:method:: get_count_query()


