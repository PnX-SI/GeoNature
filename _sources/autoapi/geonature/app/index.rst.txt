geonature.app
=============

.. py:module:: geonature.app

.. autoapi-nested-parse::

   Démarrage de l'application



Classes
-------

.. autoapisummary::

   geonature.app.MyJSONProvider


Functions
---------

.. autoapisummary::

   geonature.app.configure_alembic
   geonature.app.get_locale
   geonature.app.create_app


Module Contents
---------------

.. py:function:: configure_alembic(alembic_config)

   This function add to the 'version_locations' parameter of the alembic config the
   'migrations' entry point value of the 'gn_module' group for all modules having such entry point.
   Thus, alembic will find migrations of all installed geonature modules.


.. py:class:: MyJSONProvider

   Bases: :py:obj:`flask.json.provider.DefaultJSONProvider`


   .. py:method:: default(o)
      :staticmethod:



.. py:function:: get_locale()

.. py:function:: create_app(with_external_mods=True)

