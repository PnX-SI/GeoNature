geonature.core.gn_synthese.routes
=================================

.. py:module:: geonature.core.gn_synthese.routes


Attributes
----------

.. autoapisummary::

   geonature.core.gn_synthese.routes.routes


Functions
---------

.. autoapisummary::

   geonature.core.gn_synthese.routes.get_observations_for_web
   geonature.core.gn_synthese.routes.get_one_synthese
   geonature.core.gn_synthese.routes.export_taxon_web
   geonature.core.gn_synthese.routes.export_observations_web
   geonature.core.gn_synthese.routes.export_metadata
   geonature.core.gn_synthese.routes.export_status
   geonature.core.gn_synthese.routes.general_stats
   geonature.core.gn_synthese.routes.taxon_stats
   geonature.core.gn_synthese.routes.get_taxon_tree
   geonature.core.gn_synthese.routes.get_autocomplete_taxons_synthese
   geonature.core.gn_synthese.routes.get_sources
   geonature.core.gn_synthese.routes.getDefaultsNomenclatures
   geonature.core.gn_synthese.routes.get_color_taxon
   geonature.core.gn_synthese.routes.get_taxa_count
   geonature.core.gn_synthese.routes.get_observation_count
   geonature.core.gn_synthese.routes.get_bbox
   geonature.core.gn_synthese.routes.observation_count_per_column
   geonature.core.gn_synthese.routes.get_taxa_distribution
   geonature.core.gn_synthese.routes.create_report
   geonature.core.gn_synthese.routes.notify_new_report_change
   geonature.core.gn_synthese.routes.update_content_report
   geonature.core.gn_synthese.routes.list_all_reports
   geonature.core.gn_synthese.routes.list_reports
   geonature.core.gn_synthese.routes.delete_report
   geonature.core.gn_synthese.routes.list_synthese_log_entries


Module Contents
---------------

.. py:data:: routes

.. py:function:: get_observations_for_web(permissions)

   Optimized route to serve data for the frontend with all filters.

   .. :quickref: Synthese; Get filtered observations

   Query filtered by any filter, returning all the fields of the
   view v_synthese_for_export::

       properties = {
           "id": r["id_synthese"],
           "date_min": str(r["date_min"]),
           "cd_nom": r["cd_nom"],
           "nom_vern_or_lb_nom": r["nom_vern"] if r["nom_vern"] else r["lb_nom"],
           "lb_nom": r["lb_nom"],
           "dataset_name": r["dataset_name"],
           "observers": r["observers"],
           "url_source": r["url_source"],
           "unique_id_sinp": r["unique_id_sinp"],
           "entity_source_pk_value": r["entity_source_pk_value"],
       }
       geojson = json.loads(r["st_asgeojson"])
       geojson["properties"] = properties

   :qparam str limit: Limit number of synthese returned. Defaults to NB_MAX_OBS_MAP.
   :qparam str cd_ref_parent: filtre tous les taxons enfants d'un TAXREF cd_ref.
   :qparam str cd_ref: Filter by TAXREF cd_ref attribute
   :qparam str taxonomy_group2_inpn: Filter by TAXREF group2_inpn attribute
   :qparam str taxonomy_id_hab: Filter by TAXREF id_habitat attribute
   :qparam str taxhub_attribut*: filtre générique TAXREF en fonction de l'attribut et de la valeur.
   :qparam str *_red_lists: filtre générique de listes rouges. Filtre sur les valeurs. Voir config.
   :qparam str *_protection_status: filtre générique de statuts (BdC Statuts). Filtre sur les types. Voir config.
   :qparam str observers: Filter on observer
   :qparam str id_organism: Filter on organism
   :qparam str date_min: Start date
   :qparam str date_max: End date
   :qparam str id_acquisition_framework: *tbd*
   :qparam str geoIntersection: Intersect with the geom send from the map
   :qparam str period_start: *tbd*
   :qparam str period_end: *tbd*
   :qparam str area*: Generic filter on area
   :qparam str *: Generic filter, given by colname & value
   :>jsonarr array data: Array of synthese with geojson key, see above
   :>jsonarr int nb_total: Number of observations
   :>jsonarr bool nb_obs_limited: Is number of observations capped


.. py:function:: get_one_synthese(permissions, id_synthese)

   Get one synthese record for web app with all decoded nomenclature


.. py:function:: export_taxon_web(permissions)

   Optimized route for taxon web export.

   .. :quickref: Synthese;

   This view is customisable by the administrator
   Some columns are mandatory: cd_ref

   POST parameters: Use a list of cd_ref (in POST parameters)
        to filter the v_synthese_taxon_for_export_view

   :query str export_format: str<'csv'>



.. py:function:: export_observations_web(permissions)

   Optimized route for observations web export.

   .. :quickref: Synthese;

   This view is customisable by the administrator
   Some columns are mandatory: id_synthese, geojson and geojson_local to generate the exported files

   POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view

   :query str export_format: str<'csv', 'geojson', 'shapefiles', 'gpkg'>
   :query str export_format: str<'csv', 'geojson', 'shapefiles', 'gpkg'>



.. py:function:: export_metadata(permissions)

   Route to export the metadata in CSV

   .. :quickref: Synthese;

   The table synthese is join with gn_synthese.v_metadata_for_export
   The column jdd_id is mandatory in the view gn_synthese.v_metadata_for_export

   TODO: Remove the following comment line ? or add the where clause for id_synthese in id_list ?
   POST parameters: Use a list of id_synthese (in POST parameters) to filter the v_synthese_for_export_view


.. py:function:: export_status(permissions)

   Route to get all the protection status of a synthese search

   .. :quickref: Synthese;

   Get the CRUVED from 'R' action because we don't give observations X/Y but only statuts
   and to be consistent with the data displayed in the web interface.

   Parameters:
       - HTTP-GET: the same that the /synthese endpoint (all the filter in web app)


.. py:function:: general_stats(permissions)

   Return stats about synthese.

   .. :quickref: Synthese;

       - nb of observations
       - nb of distinct species
       - nb of distinct observer
       - nb of datasets


.. py:function:: taxon_stats(scope, cd_nom)

   Return stats for a specific taxon


.. py:function:: get_taxon_tree()

   Get taxon tree.

   .. :quickref: Synthese;


.. py:function:: get_autocomplete_taxons_synthese()

   Autocomplete taxon for web search (based on all taxon in Synthese).

   .. :quickref: Synthese;

   The request use trigram algorithm to get relevent results

   :query str search_name: the search name (use sql ilike statement and puts "%" for spaces)
   :query str regne: filter with kingdom
   :query str group2_inpn : filter with INPN group 2


.. py:function:: get_sources()

   Get all sources.

   .. :quickref: Synthese;


.. py:function:: getDefaultsNomenclatures()

   Get default nomenclatures

   .. :quickref: Synthese;

   :query str group2_inpn:
   :query str regne:
   :query int organism:


.. py:function:: get_color_taxon()

   Get color of taxon in areas (vue synthese.v_color_taxon_area).

   .. :quickref: Synthese;

   :query str code_area_type: Type area code (ref_geo.bib_areas_types.type_code)
   :query int id_area: Id of area (ref_geo.l_areas.id_area)
   :query int cd_nom: taxon code (taxonomie.taxref.cd_nom)
   Those three parameters can be multiples
   :returns: Array<dict<VColorAreaTaxon>>


.. py:function:: get_taxa_count()

   Get taxa count in synthese filtering with generic parameters

   .. :quickref: Synthese;

   Parameters
   ----------
   id_dataset: `int` (query parameter)

   Returns
   -------
   count: `int`:
       the number of taxon


.. py:function:: get_observation_count()

   Get observations found in a given dataset

   .. :quickref: Synthese;

   Parameters
   ----------
   id_dataset: `int` (query parameter)

   Returns
   -------
   count: `int`:
       the number of observation



.. py:function:: get_bbox()

   Get bbox of observations

   .. :quickref: Synthese;

   Parameters
   -----------
   id_dataset: int: (query parameter)

   Returns
   -------
       bbox: `geojson`:
           the bounding box in geojson


.. py:function:: observation_count_per_column(column)

   Get observations count group by a given column

   This function was used to count observations per dataset,
   but this usage have been replaced by
   TDatasets.synthese_records_count.
   Remove this function as it is very inefficient?


.. py:function:: get_taxa_distribution()

   Get taxa distribution for a given dataset or acquisition framework
   and grouped by a certain taxa rank


.. py:function:: create_report(permissions)

   Create a report (e.g report) for a given synthese id

   Returns
   -------
       report: `json`:
           Every occurrence's report


.. py:function:: notify_new_report_change(synthese, user, id_roles, content)

.. py:function:: update_content_report(id_report)

   Modify a report (e.g report) for a given synthese id

   Returns
   -------
       report: `json`:
           Every occurrence's report


.. py:function:: list_all_reports(permissions)

.. py:function:: list_reports(permissions, id_synthese)

.. py:function:: delete_report(id_report)

.. py:function:: list_synthese_log_entries() -> dict

   Get log history from synthese

   Parameters
   ----------

   Returns
   -------
   dict
       log action list


