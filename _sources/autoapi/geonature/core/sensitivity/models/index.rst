geonature.core.sensitivity.models
=================================

.. py:module:: geonature.core.sensitivity.models


Attributes
----------

.. autoapisummary::

   geonature.core.sensitivity.models.cor_sensitivity_area
   geonature.core.sensitivity.models.cor_sensitivity_area_type


Classes
-------

.. autoapisummary::

   geonature.core.sensitivity.models.SensitivityRule
   geonature.core.sensitivity.models.CorSensitivityCriteria


Functions
---------

.. autoapisummary::

   geonature.core.sensitivity.models.before_insert_sensitivity_criteria


Module Contents
---------------

.. py:data:: cor_sensitivity_area

.. py:data:: cor_sensitivity_area_type

.. py:class:: SensitivityRule

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_sensitivity_rules'



   .. py:attribute:: __table_args__


   .. py:attribute:: id


   .. py:attribute:: cd_nom


   .. py:attribute:: nom_cite


   .. py:attribute:: id_nomenclature_sensitivity


   .. py:attribute:: nomenclature_sensitivity


   .. py:attribute:: sensitivity_duration


   .. py:attribute:: sensitivity_territory


   .. py:attribute:: id_territory


   .. py:attribute:: date_min


   .. py:attribute:: date_max


   .. py:attribute:: source


   .. py:attribute:: active


   .. py:attribute:: comments


   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: areas


   .. py:attribute:: criterias


.. py:class:: CorSensitivityCriteria(criteria=None, sensitivity_rule=None, nomenclature_type=None)

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'cor_sensitivity_criteria'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_sensitivity_rule


   .. py:attribute:: sensitivity_rule


   .. py:attribute:: id_criteria


   .. py:attribute:: criteria


   .. py:attribute:: id_nomenclature_type


   .. py:attribute:: nomenclature_type


.. py:function:: before_insert_sensitivity_criteria(mapper, connection, target)

