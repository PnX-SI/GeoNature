geonature.core.gn_permissions.models
====================================

.. py:module:: geonature.core.gn_permissions.models

.. autoapi-nested-parse::

   Models of gn_permissions schema



Attributes
----------

.. autoapisummary::

   geonature.core.gn_permissions.models.cor_object_module
   geonature.core.gn_permissions.models.TObjects


Classes
-------

.. autoapisummary::

   geonature.core.gn_permissions.models.PermFilterType
   geonature.core.gn_permissions.models.PermScope
   geonature.core.gn_permissions.models.PermAction
   geonature.core.gn_permissions.models.PermObject
   geonature.core.gn_permissions.models.PermissionAvailable
   geonature.core.gn_permissions.models.PermFilter
   geonature.core.gn_permissions.models.Permission


Functions
---------

.. autoapisummary::

   geonature.core.gn_permissions.models._nice_order


Module Contents
---------------

.. py:class:: PermFilterType

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_filters_type'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_filter_type


   .. py:attribute:: code_filter_type


   .. py:attribute:: label_filter_type


   .. py:attribute:: description_filter_type


.. py:class:: PermScope

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_filters_scope'



   .. py:attribute:: __table_args__


   .. py:attribute:: value


   .. py:attribute:: label


   .. py:attribute:: description


   .. py:method:: __str__()


.. py:class:: PermAction

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_actions'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_action


   .. py:attribute:: code_action


   .. py:attribute:: description_action


   .. py:method:: __str__()


.. py:data:: cor_object_module

.. py:class:: PermObject

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_objects'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_object


   .. py:attribute:: code_object


   .. py:attribute:: description_object


   .. py:method:: __str__()


.. py:data:: TObjects

.. py:function:: _nice_order(model, qs)

.. py:class:: PermissionAvailable

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_permissions_available'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_module


   .. py:attribute:: id_object


   .. py:attribute:: id_action


   .. py:attribute:: label


   .. py:attribute:: module


   .. py:attribute:: object


   .. py:attribute:: action


   .. py:attribute:: scope_filter


   .. py:attribute:: sensitivity_filter


   .. py:attribute:: filters_fields


   .. py:property:: filters


   .. py:method:: __str__()


   .. py:method:: nice_order(**kwargs)
      :staticmethod:



.. py:class:: PermFilter(name, value)

   .. py:attribute:: name


   .. py:attribute:: value


   .. py:method:: __str__()


.. py:class:: Permission

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_permissions'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_permission


   .. py:attribute:: id_role


   .. py:attribute:: id_action


   .. py:attribute:: id_module


   .. py:attribute:: id_object


   .. py:attribute:: role


   .. py:attribute:: action


   .. py:attribute:: module


   .. py:attribute:: object


   .. py:attribute:: scope_value


   .. py:attribute:: scope


   .. py:attribute:: sensitivity_filter


   .. py:attribute:: availability


   .. py:attribute:: filters_fields


   .. py:method:: __SCOPE_le__(a, b)
      :staticmethod:



   .. py:method:: __SENSITIVITY_le__(a, b)
      :staticmethod:



   .. py:method:: __default_le__(a, b)
      :staticmethod:



   .. py:method:: __le__(other)

      Return True if this permission is supersed by 'other' permission.
      This requires all filters to be supersed by 'other' filters.



   .. py:property:: filters


   .. py:method:: has_other_filters_than(*expected_filters)


   .. py:method:: nice_order(**kwargs)


