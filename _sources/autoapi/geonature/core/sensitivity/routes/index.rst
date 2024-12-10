geonature.core.sensitivity.routes
=================================

.. py:module:: geonature.core.sensitivity.routes


Attributes
----------

.. autoapisummary::

   geonature.core.sensitivity.routes.routes


Functions
---------

.. autoapisummary::

   geonature.core.sensitivity.routes.info
   geonature.core.sensitivity.routes.add_referential
   geonature.core.sensitivity.routes.remove_referential
   geonature.core.sensitivity.routes.refresh_rules_cache
   geonature.core.sensitivity.routes.update_synthese


Module Contents
---------------

.. py:data:: routes

.. py:function:: info()

   Affiche différentes statistiques sur les règles de sensibilitées


.. py:function:: add_referential(source_name, csvfile, url, zipfile, encoding)

   Ajoute les règles pour une source données


.. py:function:: remove_referential(source)

   Supprime les règles d’une source données


.. py:function:: refresh_rules_cache()

   Rafraichie la vue matérialisée extrapolant les règles aux taxons enfants.


.. py:function:: update_synthese()

   Recalcule la sensibilité des observations de la synthèse.


