geonature.core.admin.admin
==========================

.. py:module:: geonature.core.admin.admin


Attributes
----------

.. autoapisummary::

   geonature.core.admin.admin.admin
   geonature.core.admin.admin.flask_admin


Classes
-------

.. autoapisummary::

   geonature.core.admin.admin.MyHomeView
   geonature.core.admin.admin.ProtectedBibNomenclaturesTypesAdmin
   geonature.core.admin.admin.ProtectedTNomenclaturesAdmin


Module Contents
---------------

.. py:class:: MyHomeView

   Bases: :py:obj:`flask_admin.AdminIndexView`


   .. py:method:: is_accessible()


.. py:class:: ProtectedBibNomenclaturesTypesAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`pypnnomenclature.admin.BibNomenclaturesTypesAdmin`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'NOMENCLATURES'



.. py:class:: ProtectedTNomenclaturesAdmin

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`pypnnomenclature.admin.TNomenclaturesAdmin`


   .. py:attribute:: module_code
      :value: 'ADMIN'



   .. py:attribute:: object_code
      :value: 'NOMENCLATURES'



.. py:data:: admin

.. py:data:: flask_admin

