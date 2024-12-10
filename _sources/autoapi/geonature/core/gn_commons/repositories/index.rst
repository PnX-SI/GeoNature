geonature.core.gn_commons.repositories
======================================

.. py:module:: geonature.core.gn_commons.repositories


Classes
-------

.. autoapisummary::

   geonature.core.gn_commons.repositories.TMediaRepository
   geonature.core.gn_commons.repositories.TMediumRepository


Functions
---------

.. autoapisummary::

   geonature.core.gn_commons.repositories.get_table_location_id


Module Contents
---------------

.. py:class:: TMediaRepository(data=None, file=None, id_media=None)

   Reposity permettant de manipuler un objet média
   au niveau de la base de données et du système de fichier
   de façon synchrone


   .. py:attribute:: media_data


   .. py:attribute:: data


   .. py:attribute:: file
      :value: None



   .. py:attribute:: media
      :value: None



   .. py:attribute:: new
      :value: False



   .. py:attribute:: thumbnail_sizes


   .. py:method:: create_or_update_media()

      Création ou modification d'un média :
       - Enregistrement en base de données
       - Stockage du fichier



   .. py:method:: _persist_media_db()

      Enregistrement des données dans la base



   .. py:method:: absolute_file_path(thumbnail_height=None)


   .. py:method:: test_video_link()


   .. py:method:: test_header_content_type(content_type)


   .. py:method:: test_url()


   .. py:method:: file_path(thumbnail_height=None)


   .. py:method:: upload_file()

      Upload des fichiers sur le serveur



   .. py:method:: is_img()


   .. py:method:: media_type()


   .. py:method:: get_image()


   .. py:method:: has_thumbnails()

      Test si la liste des thumbnails
      définis par défaut existe



   .. py:method:: has_thumbnail(size)

      Test si le thumbnail de taille X existe



   .. py:method:: create_thumbnails()

      Creation automatique des thumbnails
      dont les tailles sont spécifiés dans la config



   .. py:method:: create_thumbnail(size, image=None)


   .. py:method:: get_thumbnail_url(size)

      Fonction permettant de récupérer l'url d'un thumbnail
      Si le thumbnail n'existe pas il est créé à la volé



   .. py:method:: delete()


   .. py:method:: _load_from_id(id_media)

      Charge un média de la base à partir de son identifiant



.. py:class:: TMediumRepository

   Classe permettant de manipuler des collections
   d'objet média


   .. py:method:: get_medium_for_entity(entity_uuid)

      Retourne la liste des médias pour un objet
      en fonction de son uuid



   .. py:method:: sync_medias()
      :staticmethod:


      Met à jour les médias
        - supprime les médias sans uuid_attached_row plus vieux que 24h
        - supprime les médias dont l'object attaché n'existe plus



.. py:function:: get_table_location_id(schema_name, table_name)

