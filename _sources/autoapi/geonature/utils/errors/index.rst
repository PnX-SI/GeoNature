geonature.utils.errors
======================

.. py:module:: geonature.utils.errors


Attributes
----------

.. autoapisummary::

   geonature.utils.errors.log


Exceptions
----------

.. autoapisummary::

   geonature.utils.errors.GeoNatureError
   geonature.utils.errors.ConfigError
   geonature.utils.errors.GeonatureApiError
   geonature.utils.errors.AuthentificationError
   geonature.utils.errors.CasAuthentificationError


Module Contents
---------------

.. py:data:: log

   Erreurs propres à GN


.. py:exception:: GeoNatureError

   Bases: :py:obj:`Exception`


   Common base class for all non-exit exceptions.


.. py:exception:: ConfigError(file, value)

   Bases: :py:obj:`GeoNatureError`


   Configuration error class
   Quand un fichier de configuration n'est pas conforme aux attentes


   .. py:attribute:: value


   .. py:attribute:: file


   .. py:method:: __str__()

      Return str(self).



.. py:exception:: GeonatureApiError(message, status_code=500)

   Bases: :py:obj:`Exception`


   Common base class for all non-exit exceptions.


   .. py:attribute:: message


   .. py:attribute:: status_code


   .. py:method:: to_dict()


   .. py:method:: __str__()

      Return str(self).



.. py:exception:: AuthentificationError(message, status_code=500)

   Bases: :py:obj:`GeonatureApiError`


   Common base class for all non-exit exceptions.


.. py:exception:: CasAuthentificationError(message, status_code=500)

   Bases: :py:obj:`GeonatureApiError`


   Common base class for all non-exit exceptions.


