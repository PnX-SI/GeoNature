geonature.core.command.main
===========================

.. py:module:: geonature.core.command.main

.. autoapi-nested-parse::

   Entry point for the command line 'geonature'



Attributes
----------

.. autoapisummary::

   geonature.core.command.main.log


Functions
---------

.. autoapisummary::

   geonature.core.command.main.normalize
   geonature.core.command.main.main
   geonature.core.command.main.dev_back
   geonature.core.command.main.generate_frontend_module_config
   geonature.core.command.main.update_configuration
   geonature.core.command.main.default_config
   geonature.core.command.main.get_config


Module Contents
---------------

.. py:data:: log

.. py:function:: normalize(name)

.. py:function:: main(ctx)

.. py:function:: dev_back(ctx, host, port)

   Lance l'api du backend avec flask

   Exemples

   - geonature dev_back

   - geonature dev_back --port=8080 --port=0.0.0.0


.. py:function:: generate_frontend_module_config(module_code, output_file)

   Génère la config frontend d'un module

   Example:

   - geonature generate-frontend-module-config OCCTAX



.. py:function:: update_configuration(modules, build)

   Régénère la configuration du front et lance le rebuild.


.. py:function:: default_config()

   Afficher l’ensemble des paramètres et leur valeur par défaut.


.. py:function:: get_config(key=None)

   Afficher l’ensemble des paramètres


