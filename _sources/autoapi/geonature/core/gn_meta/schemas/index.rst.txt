geonature.core.gn_meta.schemas
==============================

.. py:module:: geonature.core.gn_meta.schemas


Classes
-------

.. autoapisummary::

   geonature.core.gn_meta.schemas.DatasetActorSchema
   geonature.core.gn_meta.schemas.DatasetSchema
   geonature.core.gn_meta.schemas.BibliographicReferenceSchema
   geonature.core.gn_meta.schemas.AcquisitionFrameworkActorSchema
   geonature.core.gn_meta.schemas.AcquisitionFrameworkSchema


Module Contents
---------------

.. py:class:: DatasetActorSchema

   Bases: :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: include_fk
         :value: True




   .. py:attribute:: role


   .. py:attribute:: nomenclature_actor_role


   .. py:attribute:: organism


   .. py:method:: make_dataset_actor(data, **kwargs)


.. py:class:: DatasetSchema

   Bases: :py:obj:`geonature.utils.schema.CruvedSchemaMixin`, :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   This mixin add a cruved field which serialize to a dict "{action: boolean}".
       example: {"C": False, "R": True, "U": True, "V": False, "E": True, "D": False}
   The schema must have a __module_code__ property (and optionally a __object_code__property)
   to indicate from which permissions must be verified.
   The model must have an has_instance_permission method which take the scope and retrurn a boolean.
   The cruved field is excluded by default and may be added to serialization with only=["+cruved"].


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: include_fk
         :value: True




   .. py:attribute:: __module_code__
      :value: 'METADATA'



   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: cor_dataset_actor


   .. py:attribute:: modules


   .. py:attribute:: creator


   .. py:attribute:: nomenclature_data_type


   .. py:attribute:: nomenclature_dataset_objectif


   .. py:attribute:: nomenclature_collecting_method


   .. py:attribute:: nomenclature_data_origin


   .. py:attribute:: nomenclature_source_status


   .. py:attribute:: nomenclature_resource_type


   .. py:attribute:: cor_territories


   .. py:attribute:: acquisition_framework


   .. py:attribute:: sources


   .. py:method:: module_input(item, original, many, **kwargs)


   .. py:method:: mobile_app_compat(data, original, many, **kwargs)


.. py:class:: BibliographicReferenceSchema

   Bases: :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: include_fk
         :value: True




   .. py:attribute:: acquisition_framework


   .. py:method:: make_biblio_ref(data, **kwargs)


.. py:class:: AcquisitionFrameworkActorSchema

   Bases: :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: include_fk
         :value: True




   .. py:attribute:: role


   .. py:attribute:: nomenclature_actor_role


   .. py:attribute:: organism


   .. py:attribute:: cor_volets_sinp


   .. py:method:: make_af_actor(data, **kwargs)


.. py:class:: AcquisitionFrameworkSchema

   Bases: :py:obj:`geonature.utils.schema.CruvedSchemaMixin`, :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   This mixin add a cruved field which serialize to a dict "{action: boolean}".
       example: {"C": False, "R": True, "U": True, "V": False, "E": True, "D": False}
   The schema must have a __module_code__ property (and optionally a __object_code__property)
   to indicate from which permissions must be verified.
   The model must have an has_instance_permission method which take the scope and retrurn a boolean.
   The cruved field is excluded by default and may be added to serialization with only=["+cruved"].


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: include_fk
         :value: True




   .. py:attribute:: __module_code__
      :value: 'METADATA'



   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:attribute:: t_datasets


   .. py:attribute:: datasets


   .. py:attribute:: bibliographical_references


   .. py:attribute:: cor_af_actor


   .. py:attribute:: cor_volets_sinp


   .. py:attribute:: cor_objectifs


   .. py:attribute:: cor_territories


   .. py:attribute:: nomenclature_territorial_level


   .. py:attribute:: nomenclature_financing_type


   .. py:attribute:: creator


