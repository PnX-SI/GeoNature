geonature.core.gn_synthese.imports.plot
=======================================

.. py:module:: geonature.core.gn_synthese.imports.plot


Functions
---------

.. autoapisummary::

   geonature.core.gn_synthese.imports.plot.taxon_distribution_plot


Module Contents
---------------

.. py:function:: taxon_distribution_plot(imprt) -> bokeh.embed.standalone.StandaloneEmbedJson

   Generate a plot of the taxonomic distribution (for each rank) based on the import.
   The following ranks are used:
   - group1_inpn
   - group2_inpn
   - group3_inpn
   - sous_famille
   - tribu
   - classe
   - ordre
   - famille
   - phylum
   - regne

   Parameters
   ----------
   imprt : TImports
       The import object to generate the plot from.

   Returns
   -------
   dict
       Returns a dict containing data required to generate the plot


