geonature.core.gn_commons.medias.routes
=======================================

.. py:module:: geonature.core.gn_commons.medias.routes

.. autoapi-nested-parse::

   Route permettant de manipuler les fichiers
   contenus dans gn_media



Functions
---------

.. autoapisummary::

   geonature.core.gn_commons.medias.routes.get_medias
   geonature.core.gn_commons.medias.routes.get_media
   geonature.core.gn_commons.medias.routes.insert_or_update_media
   geonature.core.gn_commons.medias.routes.delete_media
   geonature.core.gn_commons.medias.routes.get_media_thumb


Module Contents
---------------

.. py:function:: get_medias(uuid_attached_row)

   Retourne des medias
   .. :quickref: Commons;


.. py:function:: get_media(id_media)

   Retourne un media
   .. :quickref: Commons;


.. py:function:: insert_or_update_media(id_media=None)

   Insertion ou mise à jour d'un média
   avec prise en compte des fichiers joints

   .. :quickref: Commons;


.. py:function:: delete_media(id_media)

   Suppression d'un media

   .. :quickref: Commons;


.. py:function:: get_media_thumb(id_media, size)

   Retourne le thumbnail d'un media
   .. :quickref: Commons;


