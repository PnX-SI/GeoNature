geonature.core.imports.checks.sql.nomenclature
==============================================

.. py:module:: geonature.core.imports.checks.sql.nomenclature


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.sql.nomenclature.do_nomenclatures_mapping
   geonature.core.imports.checks.sql.nomenclature.check_nomenclature_exist_proof
   geonature.core.imports.checks.sql.nomenclature.check_nomenclature_blurring
   geonature.core.imports.checks.sql.nomenclature.check_nomenclature_source_status
   geonature.core.imports.checks.sql.nomenclature.check_nomenclature_technique_collect


Module Contents
---------------

.. py:function:: do_nomenclatures_mapping(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, fields: Mapping[str, geonature.core.imports.models.BibFields], fill_with_defaults: bool = False) -> None

   Set nomenclatures using content mapping.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   fields : Mapping[str, BibFields]
       Mapping of field names to BibFields objects.
   fill_with_defaults : bool, optional
       If True, fill empty user fields with default nomenclatures.

   Notes
   -----
   See the following link for explanation on empty fields and default nomenclature handling:
   https://github.com/PnX-SI/gn_module_import/issues/68#issuecomment-1384267087


.. py:function:: check_nomenclature_exist_proof(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, nomenclature_field: geonature.core.imports.models.BibFields, digital_proof_field: Optional[geonature.core.imports.models.BibFields], non_digital_proof_field: Optional[geonature.core.imports.models.BibFields]) -> None

   Check the existence of a nomenclature proof in the transient table.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   nomenclature_field : BibFields
       The field representing the nomenclature to check.
   digital_proof_field : Optional[BibFields]
       The field for digital proof, if any.
   non_digital_proof_field : Optional[BibFields]
       The field for non-digital proof, if any.


.. py:function:: check_nomenclature_blurring(imprt, entity, blurring_field, id_dataset_field, uuid_dataset_field)

   Raise an error if blurring not set.
   Required if the dataset is private.


.. py:function:: check_nomenclature_source_status(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, source_status_field: geonature.core.imports.models.BibFields, ref_biblio_field: geonature.core.imports.models.BibFields) -> None

   Check the nomenclature source status and raise an error if the status is "Lit" (Literature)
   whereas the reference biblio field is empty.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   source_status_field : BibFields
       The field representing the source status.
   ref_biblio_field : BibFields
       The field representing the reference bibliography.

   Notes
   -----
   The error codes are:
       - CONDITIONAL_MANDATORY_FIELD_ERROR: the field is mandatory and not set.


.. py:function:: check_nomenclature_technique_collect(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, source_status_field: geonature.core.imports.models.BibFields, technical_precision_field: geonature.core.imports.models.BibFields) -> None

   Check the nomenclature source status and raise an error if the status is "Autre, préciser"
   whereas technical precision field is empty.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   source_status_field : BibFields
       The field representing the source status.
   technical_precision_field : BibFields
       The field representing the technical precision.

   Notes
   -----
   The error codes are:
       - CONDITIONAL_MANDATORY_FIELD_ERROR: the field is mandatory and not set.


