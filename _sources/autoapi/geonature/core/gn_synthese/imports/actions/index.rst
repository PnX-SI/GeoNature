geonature.core.gn_synthese.imports.actions
==========================================

.. py:module:: geonature.core.gn_synthese.imports.actions


Classes
-------

.. autoapisummary::

   geonature.core.gn_synthese.imports.actions.SyntheseImportActions


Module Contents
---------------

.. py:class:: SyntheseImportActions

   Bases: :py:obj:`geonature.core.imports.actions.ImportActions`


   .. py:method:: statistics_labels() -> List[geonature.core.imports.actions.ImportStatisticsLabels]
      :staticmethod:



   .. py:method:: preprocess_transient_data(imprt: geonature.core.imports.models.TImports, df) -> set
      :staticmethod:



   .. py:method:: check_transient_data(task, logger, imprt: geonature.core.imports.models.TImports)
      :staticmethod:



   .. py:method:: import_data_to_destination(imprt: geonature.core.imports.models.TImports) -> None
      :staticmethod:



   .. py:method:: remove_data_from_destination(imprt: geonature.core.imports.models.TImports) -> None
      :staticmethod:



   .. py:method:: report_plot(imprt: geonature.core.imports.models.TImports) -> bokeh.embed.standalone.StandaloneEmbedJson
      :staticmethod:



   .. py:method:: compute_bounding_box(imprt: geonature.core.imports.models.TImports)
      :staticmethod:



