geonature.middlewares
=====================

.. py:module:: geonature.middlewares


Classes
-------

.. autoapisummary::

   geonature.middlewares.RequestID
   geonature.middlewares.SchemeFix


Package Contents
----------------

.. py:class:: RequestID(app)

   .. py:attribute:: app


   .. py:method:: __call__(environ, start_response)


.. py:class:: SchemeFix(app, scheme=None)

   .. py:attribute:: app


   .. py:attribute:: scheme


   .. py:method:: __call__(environ, start_response)


