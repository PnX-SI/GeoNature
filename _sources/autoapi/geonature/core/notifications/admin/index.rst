geonature.core.notifications.admin
==================================

.. py:module:: geonature.core.notifications.admin


Classes
-------

.. autoapisummary::

   geonature.core.notifications.admin.NotificationTemplateAdmin
   geonature.core.notifications.admin.NotificationCategoryAdmin
   geonature.core.notifications.admin.NotificationMethodAdmin


Module Contents
---------------

.. py:class:: NotificationTemplateAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'NOTIFICATIONS'



   .. py:attribute:: column_list
      :value: ('code_category', 'code_method', 'content')



   .. py:attribute:: column_labels


   .. py:attribute:: form_columns
      :value: ('category', 'method', 'content')



   .. py:attribute:: form_args


.. py:class:: NotificationCategoryAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'NOTIFICATIONS'



   .. py:attribute:: column_list
      :value: ('code', 'label', 'description')



   .. py:attribute:: form_columns
      :value: ('code', 'label', 'description')



   .. py:attribute:: form_args


.. py:class:: NotificationMethodAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`flask_admin.contrib.sqla.ModelView`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'NOTIFICATIONS'



   .. py:attribute:: column_list
      :value: ('code', 'label', 'description')



   .. py:attribute:: form_columns
      :value: ('code', 'label', 'description')



   .. py:attribute:: form_args


