geonature.core.gn_monitoring.models
===================================

.. py:module:: geonature.core.gn_monitoring.models

.. autoapi-nested-parse::

   Modèles du schéma gn_monitoring
   Correspond a la centralisation des données de base
       relatifs aux protocoles de suivis



Attributes
----------

.. autoapisummary::

   geonature.core.gn_monitoring.models.cor_visit_observer
   geonature.core.gn_monitoring.models.cor_site_module
   geonature.core.gn_monitoring.models.cor_site_area
   geonature.core.gn_monitoring.models.cor_module_type
   geonature.core.gn_monitoring.models.cor_site_type


Classes
-------

.. autoapisummary::

   geonature.core.gn_monitoring.models.BibTypeSite
   geonature.core.gn_monitoring.models.TBaseVisits
   geonature.core.gn_monitoring.models.TBaseSites
   geonature.core.gn_monitoring.models.TObservations


Module Contents
---------------

.. py:data:: cor_visit_observer

.. py:data:: cor_site_module

.. py:data:: cor_site_area

.. py:data:: cor_module_type

.. py:data:: cor_site_type

.. py:class:: BibTypeSite

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_type_site'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_nomenclature_type_site


   .. py:attribute:: config


   .. py:attribute:: nomenclature


   .. py:attribute:: sites


.. py:class:: TBaseVisits

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   Table de centralisation des visites liées à un site


   .. py:attribute:: __tablename__
      :value: 't_base_visits'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_base_visit


   .. py:attribute:: id_base_site


   .. py:attribute:: id_digitiser


   .. py:attribute:: id_dataset


   .. py:attribute:: id_module


   .. py:attribute:: visit_date_min


   .. py:attribute:: visit_date_max


   .. py:attribute:: id_nomenclature_tech_collect_campanule


   .. py:attribute:: id_nomenclature_grp_typ


   .. py:attribute:: comments


   .. py:attribute:: uuid_base_visit


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: digitiser


   .. py:attribute:: observers


   .. py:attribute:: observers_txt


   .. py:attribute:: dataset


.. py:class:: TBaseSites

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   Table centralisant les données élémentaire des sites


   .. py:attribute:: __tablename__
      :value: 't_base_sites'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_base_site


   .. py:attribute:: id_inventor


   .. py:attribute:: id_digitiser


   .. py:attribute:: base_site_name


   .. py:attribute:: base_site_description


   .. py:attribute:: base_site_code


   .. py:attribute:: first_use_date


   .. py:attribute:: geom


   .. py:attribute:: uuid_base_site


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: altitude_min


   .. py:attribute:: altitude_max


   .. py:attribute:: digitiser


   .. py:attribute:: inventor


   .. py:attribute:: t_base_visits


   .. py:attribute:: modules


.. py:class:: TObservations

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_observations'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_observation


   .. py:attribute:: id_base_visit


   .. py:attribute:: id_digitiser


   .. py:attribute:: digitiser


   .. py:attribute:: cd_nom


   .. py:attribute:: comments


   .. py:attribute:: uuid_observation


