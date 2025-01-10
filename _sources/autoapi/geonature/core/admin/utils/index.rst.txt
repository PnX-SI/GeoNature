geonature.core.admin.utils
==========================

.. py:module:: geonature.core.admin.utils


Classes
-------

.. autoapisummary::

   geonature.core.admin.utils.CruvedProtectedMixin
   geonature.core.admin.utils.ReloadingIterator
   geonature.core.admin.utils.DynamicOptionsMixin


Module Contents
---------------

.. py:class:: CruvedProtectedMixin

   .. py:method:: is_accessible()


   .. py:method:: _can_action(action)


   .. py:property:: can_create


   .. py:property:: can_edit


   .. py:property:: can_delete


   .. py:property:: can_export


.. py:class:: ReloadingIterator(iterator_factory)

   .. py:attribute:: iterator_factory


   .. py:method:: __iter__()


.. py:class:: DynamicOptionsMixin

   .. py:method:: get_dynamic_options(view)
      :abstractmethod:



   .. py:method:: get_options(view)


