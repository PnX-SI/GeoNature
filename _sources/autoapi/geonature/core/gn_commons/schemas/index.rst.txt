geonature.core.gn_commons.schemas
=================================

.. py:module:: geonature.core.gn_commons.schemas


Attributes
----------

.. autoapisummary::

   geonature.core.gn_commons.schemas.log


Classes
-------

.. autoapisummary::

   geonature.core.gn_commons.schemas.ModuleSchema
   geonature.core.gn_commons.schemas.MediaSchema
   geonature.core.gn_commons.schemas.TValidationSchema
   geonature.core.gn_commons.schemas.BibWidgetSchema
   geonature.core.gn_commons.schemas.LabelValueDict
   geonature.core.gn_commons.schemas.CastableField
   geonature.core.gn_commons.schemas.TAdditionalFieldsSchema


Module Contents
---------------

.. py:data:: log

.. py:class:: ModuleSchema

   Bases: :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: exclude
         :value: ('module_picto', 'module_desc', 'module_group', 'module_external_url', 'module_target',...




.. py:class:: MediaSchema

   Bases: :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: include_fk
         :value: True



      .. py:attribute:: unknown



   .. py:attribute:: meta_create_date


   .. py:attribute:: meta_update_date


   .. py:method:: make_media(data, **kwargs)


.. py:class:: TValidationSchema

   Bases: :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True



      .. py:attribute:: include_fk
         :value: True




   .. py:attribute:: validation_label


   .. py:attribute:: validator_role


.. py:class:: BibWidgetSchema

   Bases: :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True




.. py:class:: LabelValueDict

   Bases: :py:obj:`marshmallow.Schema`


   .. py:attribute:: label


   .. py:attribute:: value


.. py:class:: CastableField

   Bases: :py:obj:`marshmallow.fields.Field`


   A field which tries to cast the value to int or float before returning it.
   If the value is not castable, the default value is returned.


   .. py:method:: _serialize(value, attr, obj, **kwargs)


.. py:class:: TAdditionalFieldsSchema

   Bases: :py:obj:`utils_flask_sqla.schema.SmartRelationshipsMixin`, :py:obj:`geonature.utils.env.MA.SQLAlchemyAutoSchema`


   .. py:class:: Meta

      .. py:attribute:: model


      .. py:attribute:: load_instance
         :value: True




   .. py:attribute:: default_value


   .. py:attribute:: code_nomenclature_type


   .. py:attribute:: modules


   .. py:attribute:: objects


   .. py:attribute:: type_widget


   .. py:attribute:: datasets


   .. py:attribute:: bib_nomenclature_type


   .. py:method:: load(data, *, many=None, **kwargs)


