geonature.core.gn_meta.routes
=============================

.. py:module:: geonature.core.gn_meta.routes

.. autoapi-nested-parse::

   Routes for gn_meta



Attributes
----------

.. autoapisummary::

   geonature.core.gn_meta.routes.routes
   geonature.core.gn_meta.routes.log


Functions
---------

.. autoapisummary::

   geonature.core.gn_meta.routes.get_datasets
   geonature.core.gn_meta.routes.get_af_from_id
   geonature.core.gn_meta.routes.get_dataset
   geonature.core.gn_meta.routes.delete_dataset
   geonature.core.gn_meta.routes.uuid_report
   geonature.core.gn_meta.routes.sensi_report
   geonature.core.gn_meta.routes.my_csv_resp
   geonature.core.gn_meta.routes.datasetHandler
   geonature.core.gn_meta.routes.create_dataset
   geonature.core.gn_meta.routes.update_dataset
   geonature.core.gn_meta.routes.get_export_pdf_dataset
   geonature.core.gn_meta.routes.get_acquisition_frameworks
   geonature.core.gn_meta.routes.get_acquisition_frameworks_list
   geonature.core.gn_meta.routes.get_export_pdf_acquisition_frameworks
   geonature.core.gn_meta.routes.get_acquisition_framework
   geonature.core.gn_meta.routes.delete_acquisition_framework
   geonature.core.gn_meta.routes.acquisitionFrameworkHandler
   geonature.core.gn_meta.routes.create_acquisition_framework
   geonature.core.gn_meta.routes.updateAcquisitionFramework
   geonature.core.gn_meta.routes.get_acquisition_framework_stats
   geonature.core.gn_meta.routes.get_acquisition_framework_bbox
   geonature.core.gn_meta.routes.publish_acquisition_framework_mail
   geonature.core.gn_meta.routes.publish_acquisition_framework


Module Contents
---------------

.. py:data:: routes

.. py:data:: log

.. py:function:: get_datasets()

   Get datasets list

   .. :quickref: Metadata;

   :query boolean active: filter on active fiel
   :query string create: filter on C permission for the module_code specified
       (we can specify the object_code by adding a . between both)
   :query int id_acquisition_framework: get only dataset of given AF
   :returns:  `list<TDatasets>`


.. py:function:: get_af_from_id(id_af, af_list)

.. py:function:: get_dataset(scope, id_dataset)

   Get one dataset

   .. :quickref: Metadata;

   :param id_dataset: the id_dataset
   :param type: int
   :returns: dict<TDataset>


.. py:function:: delete_dataset(scope, ds_id)

   Delete a dataset

   .. :quickref: Metadata;


.. py:function:: uuid_report()

   get the UUID report of a dataset

   .. :quickref: Metadata;


.. py:function:: sensi_report(ds_id=None)

   get the UUID report of a dataset

   .. :quickref: Metadata;


.. py:function:: my_csv_resp(filename, data, columns, _header, separator=';')

.. py:function:: datasetHandler(dataset, data)

.. py:function:: create_dataset()

   Post one Dataset data
   .. :quickref: Metadata;


.. py:function:: update_dataset(id_dataset, scope)

   Post one Dataset data for update dataset
   .. :quickref: Metadata;


.. py:function:: get_export_pdf_dataset(id_dataset, scope)

   Get a PDF export of one dataset


.. py:function:: get_acquisition_frameworks()

   Get a simple list of AF without any nested relationships
   Use for AF select in form
   Get the GeoNature CRUVED


.. py:function:: get_acquisition_frameworks_list(scope)

   Get all AF with their datasets
   Use in metadata module for list of AF and DS
   Add the CRUVED permission for each row (Dataset and AD)

   DEPRECATED use get_acquisition_frameworks instead

   .. :quickref: Metadata;

   :qparam list excluded_fields: fields excluded from serialization
   :qparam boolean nested: Default False - serialized relationships. If false: remove add all relationships in excluded_fields



.. py:function:: get_export_pdf_acquisition_frameworks(id_acquisition_framework)

   Get a PDF export of one acquisition


.. py:function:: get_acquisition_framework(scope, id_acquisition_framework)

   Get one AF with nomenclatures
   .. :quickref: Metadata;

   :param id_acquisition_framework: the id_acquisition_framework
   :param type: int
   :returns: dict<TAcquisitionFramework>


.. py:function:: delete_acquisition_framework(scope, af_id)

   Delete an acquisition framework
   .. :quickref: Metadata;


.. py:function:: acquisitionFrameworkHandler(request, *, acquisition_framework)

.. py:function:: create_acquisition_framework()

   Post one AcquisitionFramework data
   .. :quickref: Metadata;


.. py:function:: updateAcquisitionFramework(id_acquisition_framework, scope)

   Post one AcquisitionFramework data for update acquisition_framework
   .. :quickref: Metadata;


.. py:function:: get_acquisition_framework_stats(id_acquisition_framework)

   Get stats from one AF
   .. :quickref: Metadata;
   :param id_acquisition_framework: the id_acquisition_framework
   :param type: int


.. py:function:: get_acquisition_framework_bbox(id_acquisition_framework)

   Get BBOX from one AF
   .. :quickref: Metadata;
   :param id_acquisition_framework: the id_acquisition_framework
   :param type: int


.. py:function:: publish_acquisition_framework_mail(af)

   Method for sending a mail during the publication process


.. py:function:: publish_acquisition_framework(af_id)

   Publish an acquisition framework
   .. :quickref: Metadata;


