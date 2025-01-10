geonature.core.imports.actions
==============================

.. py:module:: geonature.core.imports.actions


Classes
-------

.. autoapisummary::

   geonature.core.imports.actions.ImportStatisticsLabels
   geonature.core.imports.actions.ImportInputUrl
   geonature.core.imports.actions.ImportActions


Module Contents
---------------

.. py:class:: ImportStatisticsLabels

   Bases: :py:obj:`TypedDict`


   dict() -> new empty dictionary
   dict(mapping) -> new dictionary initialized from a mapping object's
       (key, value) pairs
   dict(iterable) -> new dictionary initialized as if via:
       d = {}
       for k, v in iterable:
           d[k] = v
   dict(**kwargs) -> new dictionary initialized with the name=value pairs
       in the keyword argument list.  For example:  dict(one=1, two=2)


   .. py:attribute:: key
      :type:  str


   .. py:attribute:: value
      :type:  str


.. py:class:: ImportInputUrl

   Bases: :py:obj:`TypedDict`


   dict() -> new empty dictionary
   dict(mapping) -> new dictionary initialized from a mapping object's
       (key, value) pairs
   dict(iterable) -> new dictionary initialized as if via:
       d = {}
       for k, v in iterable:
           d[k] = v
   dict(**kwargs) -> new dictionary initialized with the name=value pairs
       in the keyword argument list.  For example:  dict(one=1, two=2)


   .. py:attribute:: url
      :type:  str


   .. py:attribute:: label
      :type:  str


.. py:class:: ImportActions

   .. py:method:: statistics_labels() -> List[ImportStatisticsLabels]
      :staticmethod:

      :abstractmethod:



   .. py:method:: preprocess_transient_data(imprt: geonature.core.imports.models.TImports, df) -> set
      :staticmethod:

      :abstractmethod:



   .. py:method:: check_transient_data(task, logger, imprt: geonature.core.imports.models.TImports) -> None
      :staticmethod:

      :abstractmethod:



   .. py:method:: import_data_to_destination(imprt: geonature.core.imports.models.TImports) -> None
      :staticmethod:

      :abstractmethod:



   .. py:method:: remove_data_from_destination(imprt: geonature.core.imports.models.TImports) -> None
      :staticmethod:

      :abstractmethod:



   .. py:method:: report_plot(imprt: geonature.core.imports.models.TImports) -> bokeh.embed.standalone.StandaloneEmbedJson
      :staticmethod:

      :abstractmethod:



   .. py:method:: compute_bounding_box(imprt: geonature.core.imports.models.TImports) -> None
      :staticmethod:

      :abstractmethod:



