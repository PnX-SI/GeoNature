geonature.core.gn_synthese.models
=================================

.. py:module:: geonature.core.gn_synthese.models


Attributes
----------

.. autoapisummary::

   geonature.core.gn_synthese.models.sortable_columns
   geonature.core.gn_synthese.models.filterable_columns
   geonature.core.gn_synthese.models.cor_observer_synthese
   geonature.core.gn_synthese.models.corAreaSynthese
   geonature.core.gn_synthese.models.source_subquery


Classes
-------

.. autoapisummary::

   geonature.core.gn_synthese.models.TSources
   geonature.core.gn_synthese.models.CorObserverSynthese
   geonature.core.gn_synthese.models.SyntheseLogEntryQuery
   geonature.core.gn_synthese.models.SyntheseQuery
   geonature.core.gn_synthese.models.CorAreaSynthese
   geonature.core.gn_synthese.models.Synthese
   geonature.core.gn_synthese.models.DefaultsNomenclaturesValue
   geonature.core.gn_synthese.models.BibReportsTypes
   geonature.core.gn_synthese.models.TReport
   geonature.core.gn_synthese.models.VSyntheseForWebApp
   geonature.core.gn_synthese.models.VColorAreaTaxon
   geonature.core.gn_synthese.models.SyntheseLogEntry


Functions
---------

.. autoapisummary::

   geonature.core.gn_synthese.models.synthese_export_serialization


Module Contents
---------------

.. py:data:: sortable_columns
   :value: ['meta_last_action_date']


.. py:data:: filterable_columns
   :value: ['id_synthese', 'last_action', 'meta_last_action_date']


.. py:class:: TSources

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_sources'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_source


   .. py:attribute:: name_source


   .. py:attribute:: desc_source


   .. py:attribute:: entity_source_pk_field


   .. py:attribute:: url_source


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: id_module


   .. py:attribute:: module


   .. py:property:: module_url


.. py:data:: cor_observer_synthese

.. py:class:: CorObserverSynthese

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'cor_observer_synthese'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_synthese


   .. py:attribute:: id_role


.. py:data:: corAreaSynthese

.. py:class:: SyntheseLogEntryQuery

   Bases: :py:obj:`flask_sqlalchemy.query.Query`


   .. py:attribute:: sortable_columns
      :value: ['meta_last_action_date']



   .. py:attribute:: filterable_columns
      :value: ['id_synthese', 'last_action', 'meta_last_action_date']



   .. py:method:: filter_by_params(params)


   .. py:method:: filter_by_datetime(col, dt: str = None)

      Filter on date only with operator among "<,>,=<,>="

      Parameters
      ----------
      filters_with_operator : dict
          params filters from url only

      Returns
      -------
      Query




   .. py:method:: sort(columns: List[str])


.. py:class:: SyntheseQuery

   Bases: :py:obj:`utils_flask_sqla_geo.mixins.GeoFeatureCollectionMixin`, :py:obj:`flask_sqlalchemy.query.Query`


   .. py:method:: join_nomenclatures()


   .. py:method:: lateraljoin_last_validation()


   .. py:method:: filter_by_scope(scope, user=None)


.. py:class:: CorAreaSynthese

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'cor_area_synthese'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_synthese


   .. py:attribute:: id_area


.. py:class:: Synthese

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'synthese'



   .. py:attribute:: __table_args__


   .. py:attribute:: query_class


   .. py:attribute:: nomenclature_fields
      :value: ['nomenclature_geo_object_nature', 'nomenclature_grp_typ', 'nomenclature_obs_technique',...



   .. py:attribute:: id_synthese


   .. py:attribute:: unique_id_sinp


   .. py:attribute:: unique_id_sinp_grp


   .. py:attribute:: id_source


   .. py:attribute:: source


   .. py:attribute:: id_module


   .. py:attribute:: id_import


   .. py:attribute:: module


   .. py:attribute:: entity_source_pk_value


   .. py:attribute:: id_dataset


   .. py:attribute:: dataset


   .. py:attribute:: grp_method


   .. py:attribute:: id_nomenclature_geo_object_nature


   .. py:attribute:: nomenclature_geo_object_nature


   .. py:attribute:: id_nomenclature_grp_typ


   .. py:attribute:: nomenclature_grp_typ


   .. py:attribute:: id_nomenclature_obs_technique


   .. py:attribute:: nomenclature_obs_technique


   .. py:attribute:: id_nomenclature_bio_status


   .. py:attribute:: nomenclature_bio_status


   .. py:attribute:: id_nomenclature_bio_condition


   .. py:attribute:: nomenclature_bio_condition


   .. py:attribute:: id_nomenclature_naturalness


   .. py:attribute:: nomenclature_naturalness


   .. py:attribute:: id_nomenclature_valid_status


   .. py:attribute:: nomenclature_valid_status


   .. py:attribute:: id_nomenclature_exist_proof


   .. py:attribute:: nomenclature_exist_proof


   .. py:attribute:: id_nomenclature_diffusion_level


   .. py:attribute:: nomenclature_diffusion_level


   .. py:attribute:: id_nomenclature_life_stage


   .. py:attribute:: nomenclature_life_stage


   .. py:attribute:: id_nomenclature_sex


   .. py:attribute:: nomenclature_sex


   .. py:attribute:: id_nomenclature_obj_count


   .. py:attribute:: nomenclature_obj_count


   .. py:attribute:: id_nomenclature_type_count


   .. py:attribute:: nomenclature_type_count


   .. py:attribute:: id_nomenclature_sensitivity


   .. py:attribute:: nomenclature_sensitivity


   .. py:attribute:: id_nomenclature_observation_status


   .. py:attribute:: nomenclature_observation_status


   .. py:attribute:: id_nomenclature_blurring


   .. py:attribute:: nomenclature_blurring


   .. py:attribute:: id_nomenclature_source_status


   .. py:attribute:: nomenclature_source_status


   .. py:attribute:: id_nomenclature_info_geo_type


   .. py:attribute:: nomenclature_info_geo_type


   .. py:attribute:: id_nomenclature_behaviour


   .. py:attribute:: nomenclature_behaviour


   .. py:attribute:: id_nomenclature_biogeo_status


   .. py:attribute:: nomenclature_biogeo_status


   .. py:attribute:: id_nomenclature_determination_method


   .. py:attribute:: nomenclature_determination_method


   .. py:attribute:: reference_biblio


   .. py:attribute:: count_min


   .. py:attribute:: count_max


   .. py:attribute:: cd_nom


   .. py:attribute:: taxref


   .. py:attribute:: cd_hab


   .. py:attribute:: habitat


   .. py:attribute:: nom_cite


   .. py:attribute:: meta_v_taxref


   .. py:attribute:: sample_number_proof


   .. py:attribute:: digital_proof


   .. py:attribute:: non_digital_proof


   .. py:attribute:: altitude_min


   .. py:attribute:: altitude_max


   .. py:attribute:: depth_min


   .. py:attribute:: depth_max


   .. py:attribute:: place_name


   .. py:attribute:: the_geom_4326


   .. py:attribute:: the_geom_4326_geojson


   .. py:attribute:: the_geom_point


   .. py:attribute:: the_geom_local


   .. py:attribute:: the_geom_authorized


   .. py:attribute:: precision


   .. py:attribute:: id_area_attachment


   .. py:attribute:: date_min


   .. py:attribute:: date_max


   .. py:attribute:: validator


   .. py:attribute:: validation_comment


   .. py:attribute:: observers


   .. py:attribute:: determiner


   .. py:attribute:: id_digitiser


   .. py:attribute:: digitiser


   .. py:attribute:: comment_context


   .. py:attribute:: comment_description


   .. py:attribute:: additional_data


   .. py:attribute:: meta_validation_date


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: last_action


   .. py:attribute:: areas


   .. py:attribute:: area_attachment


   .. py:attribute:: validations


   .. py:attribute:: last_validation


   .. py:attribute:: medias


   .. py:attribute:: cor_observers


   .. py:method:: _has_scope_grant(scope)


   .. py:method:: _has_permissions_grant(permissions)


   .. py:method:: has_instance_permission(permissions)


   .. py:method:: join_nomenclatures(**kwargs)


   .. py:method:: lateraljoin_last_validation(**kwargs)


   .. py:method:: filter_by_scope(scope, user=None, **kwargs)


.. py:class:: DefaultsNomenclaturesValue

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'defaults_nomenclatures_value'



   .. py:attribute:: __table_args__


   .. py:attribute:: mnemonique_type


   .. py:attribute:: id_organism


   .. py:attribute:: regne


   .. py:attribute:: group2_inpn


   .. py:attribute:: id_nomenclature


.. py:class:: BibReportsTypes

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_reports_types'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_type


   .. py:attribute:: type


.. py:class:: TReport

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_reports'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_report


   .. py:attribute:: id_synthese


   .. py:attribute:: id_role


   .. py:attribute:: id_type


   .. py:attribute:: content


   .. py:attribute:: creation_date


   .. py:attribute:: deleted


   .. py:attribute:: synthese


   .. py:attribute:: report_type


   .. py:attribute:: user


.. py:class:: VSyntheseForWebApp

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'v_synthese_for_web_app'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_synthese


   .. py:attribute:: unique_id_sinp


   .. py:attribute:: unique_id_sinp_grp


   .. py:attribute:: id_source


   .. py:attribute:: id_import


   .. py:attribute:: id_module


   .. py:attribute:: entity_source_pk_value


   .. py:attribute:: id_dataset


   .. py:attribute:: dataset_name


   .. py:attribute:: id_acquisition_framework


   .. py:attribute:: count_min


   .. py:attribute:: count_max


   .. py:attribute:: cd_nom


   .. py:attribute:: cd_ref


   .. py:attribute:: nom_cite


   .. py:attribute:: nom_valide


   .. py:attribute:: nom_vern


   .. py:attribute:: lb_nom


   .. py:attribute:: meta_v_taxref


   .. py:attribute:: group1_inpn


   .. py:attribute:: group2_inpn


   .. py:attribute:: group3_inpn


   .. py:attribute:: sample_number_proof


   .. py:attribute:: digital_proof


   .. py:attribute:: non_digital_proof


   .. py:attribute:: altitude_min


   .. py:attribute:: altitude_max


   .. py:attribute:: depth_min


   .. py:attribute:: depth_max


   .. py:attribute:: place_name


   .. py:attribute:: precision


   .. py:attribute:: the_geom_4326


   .. py:attribute:: date_min


   .. py:attribute:: date_max


   .. py:attribute:: validator


   .. py:attribute:: validation_comment


   .. py:attribute:: observers


   .. py:attribute:: determiner


   .. py:attribute:: id_digitiser


   .. py:attribute:: comment_context


   .. py:attribute:: comment_description


   .. py:attribute:: meta_validation_date


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: last_action


   .. py:attribute:: id_nomenclature_geo_object_nature


   .. py:attribute:: id_nomenclature_info_geo_type


   .. py:attribute:: id_nomenclature_grp_typ


   .. py:attribute:: grp_method


   .. py:attribute:: id_nomenclature_obs_technique


   .. py:attribute:: id_nomenclature_bio_status


   .. py:attribute:: id_nomenclature_bio_condition


   .. py:attribute:: id_nomenclature_naturalness


   .. py:attribute:: id_nomenclature_exist_proof


   .. py:attribute:: id_nomenclature_valid_status


   .. py:attribute:: id_nomenclature_diffusion_level


   .. py:attribute:: id_nomenclature_life_stage


   .. py:attribute:: id_nomenclature_sex


   .. py:attribute:: id_nomenclature_obj_count


   .. py:attribute:: id_nomenclature_type_count


   .. py:attribute:: id_nomenclature_sensitivity


   .. py:attribute:: id_nomenclature_observation_status


   .. py:attribute:: id_nomenclature_blurring


   .. py:attribute:: id_nomenclature_source_status


   .. py:attribute:: id_nomenclature_determination_method


   .. py:attribute:: id_nomenclature_behaviour


   .. py:attribute:: reference_biblio


   .. py:attribute:: name_source


   .. py:attribute:: url_source


   .. py:attribute:: st_asgeojson


   .. py:attribute:: medias


   .. py:attribute:: reports


.. py:function:: synthese_export_serialization(cls)

   Décorateur qui definit une serialisation particuliere pour la vue v_synthese_for_export
   Il rajoute la fonction as_dict_ordered qui conserve l'ordre des attributs tel que definit dans le model
   (fonctions utilisees pour les exports) et qui redefinit le nom des colonnes tel qu'ils sont nommes en configuration


.. py:class:: VColorAreaTaxon

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'v_color_taxon_area'



   .. py:attribute:: __table_args__


   .. py:attribute:: cd_nom


   .. py:attribute:: id_area


   .. py:attribute:: nb_obs


   .. py:attribute:: last_date


   .. py:attribute:: color


.. py:class:: SyntheseLogEntry

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   Log synthese table, populated with Delete Triggers on gn_synthes.synthese
   Parameters
   ----------
   DB:
       Flask SQLAlchemy controller


   .. py:attribute:: __tablename__
      :value: 't_log_synthese'



   .. py:attribute:: __table_args__


   .. py:attribute:: query_class


   .. py:attribute:: id_synthese


   .. py:attribute:: last_action


   .. py:attribute:: meta_last_action_date


   .. py:method:: filter_by_params(params, **kwargs)


   .. py:method:: filter_by_datetime(col, dt: str = None, **kwargs)

      Filter on date only with operator among "<,>,=<,>="

      Parameters
      ----------
      filters_with_operator : dict
          params filters from url only

      Returns
      -------
      Query




   .. py:method:: sort(columns: List[str], *, query)


.. py:data:: source_subquery

