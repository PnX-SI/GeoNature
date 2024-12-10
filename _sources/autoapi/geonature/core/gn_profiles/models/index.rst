geonature.core.gn_profiles.models
=================================

.. py:module:: geonature.core.gn_profiles.models


Classes
-------

.. autoapisummary::

   geonature.core.gn_profiles.models.VmCorTaxonPhenology
   geonature.core.gn_profiles.models.VmValidProfiles
   geonature.core.gn_profiles.models.VConsistancyData
   geonature.core.gn_profiles.models.VSyntheseForProfiles
   geonature.core.gn_profiles.models.TParameters
   geonature.core.gn_profiles.models.CorTaxonParameters


Module Contents
---------------

.. py:class:: VmCorTaxonPhenology

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'vm_cor_taxon_phenology'



   .. py:attribute:: __table_args__


   .. py:attribute:: cd_ref


   .. py:attribute:: doy_min


   .. py:attribute:: doy_max


   .. py:attribute:: id_nomenclature_life_stage


   .. py:attribute:: extreme_altitude_min


   .. py:attribute:: calculated_altitude_min


   .. py:attribute:: extreme_altitude_max


   .. py:attribute:: calculated_altitude_max


   .. py:attribute:: nomenclature_life_stage


.. py:class:: VmValidProfiles

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'vm_valid_profiles'



   .. py:attribute:: __table_args__


   .. py:attribute:: cd_ref


   .. py:attribute:: valid_distribution


   .. py:attribute:: altitude_min


   .. py:attribute:: altitude_max


   .. py:attribute:: first_valid_data


   .. py:attribute:: last_valid_data


   .. py:attribute:: count_valid_data


   .. py:attribute:: active_life_stage


.. py:class:: VConsistancyData

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'v_consistancy_data'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_synthese


   .. py:attribute:: synthese


   .. py:attribute:: id_sinp


   .. py:attribute:: cd_ref


   .. py:attribute:: valid_name


   .. py:attribute:: valid_distribution


   .. py:attribute:: valid_phenology


   .. py:attribute:: valid_altitude


   .. py:attribute:: valid_status


   .. py:method:: score()


.. py:class:: VSyntheseForProfiles

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'v_synthese_for_profiles'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_synthese


   .. py:attribute:: synthese


   .. py:attribute:: cd_nom


   .. py:attribute:: nom_cite


   .. py:attribute:: cd_ref


   .. py:attribute:: nom_valide


   .. py:attribute:: id_rang


   .. py:attribute:: date_min


   .. py:attribute:: date_max


   .. py:attribute:: the_geom_local


   .. py:attribute:: the_geom_4326


   .. py:attribute:: altitude_min


   .. py:attribute:: altitude_max


   .. py:attribute:: id_nomenclature_life_stage


   .. py:attribute:: nomenclature_life_stage


   .. py:attribute:: id_nomenclature_valid_status


   .. py:attribute:: nomenclature_valid_status


   .. py:attribute:: spatial_precision


   .. py:attribute:: temporal_precision_days


   .. py:attribute:: active_life_stage


   .. py:attribute:: distance


.. py:class:: TParameters

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_parameters'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_parameter


   .. py:attribute:: name


   .. py:attribute:: desc


   .. py:attribute:: value


.. py:class:: CorTaxonParameters

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'cor_taxons_parameters'



   .. py:attribute:: __table_args__


   .. py:attribute:: cd_nom


   .. py:attribute:: spatial_precision


   .. py:attribute:: temporal_precision_days


   .. py:attribute:: active_life_stage


