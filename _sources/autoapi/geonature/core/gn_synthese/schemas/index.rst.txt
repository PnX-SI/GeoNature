geonature.core.gn_synthese.schemas
==================================

.. py:module:: geonature.core.gn_synthese.schemas


Classes
-------

.. autoapisummary::

   geonature.core.gn_synthese.schemas.ReportTypeSchema
   geonature.core.gn_synthese.schemas.ReportSchema
   geonature.core.gn_synthese.schemas.SourceSchema
   geonature.core.gn_synthese.schemas.SyntheseConverter
   geonature.core.gn_synthese.schemas.SyntheseSchema


Module Contents
---------------

.. py:class:: ReportTypeSchema

   Bases: :py:obj:`geonature.utils.env.ma.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model



.. py:class:: ReportSchema

   Bases: :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`geonature.utils.env.ma.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model



   .. py:attribute:: report_type


   .. py:attribute:: user


.. py:class:: SourceSchema

   Bases: :py:obj:`geonature.utils.env.ma.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True




   .. py:attribute:: module_url


.. py:class:: SyntheseConverter

   Bases: :py:obj:`pypnnomenclature.utils.NomenclaturesConverter`, :py:obj:`utils_flask_sqla_geo.schema.GeoModelConverter`


.. py:class:: SyntheseSchema

   Bases: :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`utils_flask_sqla_geo.schema.GeoAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: exclude
         :value: ('the_geom_4326_geojson',)



      .. py:attribute:: include_fk
         :value: True



      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: sqla_session


      .. py:attribute:: feature_id
         :value: 'id_synthese'



      .. py:attribute:: feature_geometry
         :value: 'the_geom_4326'



      .. py:attribute:: model_converter



   .. py:attribute:: the_geom_4326


   .. py:attribute:: the_geom_authorized


   .. py:attribute:: source


   .. py:attribute:: module


   .. py:attribute:: dataset


   .. py:attribute:: habitat


   .. py:attribute:: digitiser


   .. py:attribute:: cor_observers


   .. py:attribute:: medias


   .. py:attribute:: areas


   .. py:attribute:: area_attachment


   .. py:attribute:: validations


   .. py:attribute:: last_validation


   .. py:attribute:: reports


