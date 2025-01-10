geonature.core.taxonomie.admin
==============================

.. py:module:: geonature.core.taxonomie.admin


Classes
-------

.. autoapisummary::

   geonature.core.taxonomie.admin.CruvedProtectedBibListesView
   geonature.core.taxonomie.admin.CruvedProtectedTaxrefView
   geonature.core.taxonomie.admin.CruvedProtectedTMediasView
   geonature.core.taxonomie.admin.CruvedProtectedBibAttributsView
   geonature.core.taxonomie.admin.CruvedProtectedBibThemes


Functions
---------

.. autoapisummary::

   geonature.core.taxonomie.admin.load_admin_views


Module Contents
---------------

.. py:class:: CruvedProtectedBibListesView

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`apptax.admin.admin_view.BibListesView`


   .. py:attribute:: module_code
      :value: 'TAXHUB'



   .. py:attribute:: object_code
      :value: 'LISTES'



   .. py:attribute:: extra_actions_perm


.. py:class:: CruvedProtectedTaxrefView

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`apptax.admin.admin_view.TaxrefView`


   .. py:attribute:: module_code
      :value: 'TAXHUB'



   .. py:attribute:: object_code
      :value: 'TAXONS'



.. py:class:: CruvedProtectedTMediasView

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`apptax.admin.admin_view.TMediasView`


   .. py:attribute:: module_code
      :value: 'TAXHUB'



   .. py:attribute:: object_code
      :value: 'TAXONS'



.. py:class:: CruvedProtectedBibAttributsView

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`apptax.admin.admin_view.BibAttributsView`


   .. py:attribute:: module_code
      :value: 'TAXHUB'



   .. py:attribute:: object_code
      :value: 'ATTRIBUTS'



.. py:class:: CruvedProtectedBibThemes

   Bases: :py:obj:`geonature.core.admin.utils.CruvedProtectedMixin`, :py:obj:`apptax.admin.admin_view.BibThemesView`


   .. py:attribute:: module_code
      :value: 'TAXHUB'



   .. py:attribute:: object_code
      :value: 'THEMES'



.. py:function:: load_admin_views(app, admin)

