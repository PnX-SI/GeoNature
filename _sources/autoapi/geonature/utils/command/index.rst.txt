geonature.utils.command
=======================

.. py:module:: geonature.utils.command

.. autoapi-nested-parse::

   Fichier de création des commandes geonature
   Ce module ne doit en aucun cas faire appel à des models ou au coeur de geonature
   dans les imports d'entête de fichier pour garantir un bon fonctionnement des fonctions
   d'administration de l'application GeoNature (génération des fichiers de configuration, des
   fichiers de routing du frontend etc...). Ces dernières doivent pouvoir fonctionner même si
   un paquet PIP du requirement GeoNature n'a pas été bien installé



Functions
---------

.. autoapisummary::

   geonature.utils.command.create_frontend_module_config
   geonature.utils.command.nvm_available
   geonature.utils.command.install_frontend_dependencies
   geonature.utils.command.build_frontend


Module Contents
---------------

.. py:function:: create_frontend_module_config(module_code, output_file=None)

   Create the frontend config


.. py:function:: nvm_available()

.. py:function:: install_frontend_dependencies(module_frontend_path)

.. py:function:: build_frontend()

