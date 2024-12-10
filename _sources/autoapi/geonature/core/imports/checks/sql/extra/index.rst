geonature.core.imports.checks.sql.extra
=======================================

.. py:module:: geonature.core.imports.checks.sql.extra


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.sql.extra.check_referential
   geonature.core.imports.checks.sql.extra.check_cd_nom
   geonature.core.imports.checks.sql.extra.check_cd_hab
   geonature.core.imports.checks.sql.extra.generate_altitudes
   geonature.core.imports.checks.sql.extra.check_duplicate_uuid
   geonature.core.imports.checks.sql.extra.check_existing_uuid
   geonature.core.imports.checks.sql.extra.generate_missing_uuid_for_id_origin
   geonature.core.imports.checks.sql.extra.generate_missing_uuid
   geonature.core.imports.checks.sql.extra.check_duplicate_source_pk
   geonature.core.imports.checks.sql.extra.check_dates
   geonature.core.imports.checks.sql.extra.check_altitudes
   geonature.core.imports.checks.sql.extra.check_depths
   geonature.core.imports.checks.sql.extra.check_digital_proof_urls
   geonature.core.imports.checks.sql.extra.check_entity_data_consistency
   geonature.core.imports.checks.sql.extra.disable_duplicated_rows


Module Contents
---------------

.. py:function:: check_referential(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, field: geonature.core.imports.models.BibFields, reference_field: sqlalchemy.Column, error_type: str, reference_table: Optional[sqlalchemy.Table] = None) -> None

   Check the referential integrity of a column in the transient table.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   field : BibFields
       The field to check.
   reference_field : BibFields
       The reference field to check.
   error_type : str
       The type of error encountered.
   reference_table : Optional[sa.Table], optional
       The reference table to check. If not provided, it will be inferred from the reference_field.


.. py:function:: check_cd_nom(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, field: geonature.core.imports.models.BibFields, list_id: Optional[int] = None) -> None

   Check the existence of a cd_nom in the Taxref referential.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   field : BibFields
       The field to check.
   list_id : Optional[int], optional
       The list to filter on, by default None.



.. py:function:: check_cd_hab(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, field: geonature.core.imports.models.BibFields) -> None

   Check the existence of a cd_hab in the Habref referential.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   field : BibFields
       The field to check.



.. py:function:: generate_altitudes(imprt: geonature.core.imports.models.TImports, geom_local_field: geonature.core.imports.models.BibFields, alt_min_field: geonature.core.imports.models.BibFields, alt_max_field: geonature.core.imports.models.BibFields) -> None

   Generate the altitudes based on geomatries, and given altitues in an import.

   Parameters
   ----------
   imprt : TImports
       The import to generate altitudes for.
   geom_local_field : BibFields
       The field representing the geometry in the destination import's transient table.
   alt_min_field : BibFields
       The field representing the minimum altitude in the destination import's transient table.
   alt_max_field : BibFields
       The field representing the maximum altitude in the destination import's transient table.



.. py:function:: check_duplicate_uuid(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, uuid_field: geonature.core.imports.models.BibFields)

   Check if there is already a record with the same uuid in the transient table. Include an error in the report for each entry with a uuid dupplicated.

   Parameters
   ----------
   imprt : Import
       The import to check.
   entity : Entity
       The entity to check.
   uuid_field : BibFields
       The field to check.


.. py:function:: check_existing_uuid(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, uuid_field: geonature.core.imports.models.BibFields, whereclause: Any = sa.true(), skip=False)

   Check if there is already a record with the same uuid in the destination table.
   Include an error in the report for each existing uuid in the destination table.
   Parameters
   ----------
   imprt : Import
       The import to check.
   entity : Entity
       The entity to check.
   uuid_field : BibFields
       The field to check.
   whereclause : BooleanClause
       The WHERE clause to apply to the check.
   skip: Boolean
       Raise SKIP_EXISTING_UUID instead of EXISTING_UUID and set row validity to None (do not import)


.. py:function:: generate_missing_uuid_for_id_origin(imprt: geonature.core.imports.models.TImports, uuid_field: geonature.core.imports.models.BibFields, id_origin_field: geonature.core.imports.models.BibFields)

   Update records in the transient table where the uuid is None
   with a new UUID.
   Generate UUID in transient table when there are no UUID yet, but
   there are a id_origin.
   Ensure rows with same id_origin get the same UUID.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   uuid_field : BibFields
       The field to check.
   id_origin_field : BibFields
       Field used to generate the UUID


.. py:function:: generate_missing_uuid(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, uuid_field: geonature.core.imports.models.BibFields, whereclause: Any = None)

   Update records in the transient table where the UUID is None
   with a new UUID.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   uuid_field : BibFields
       The field to check.


.. py:function:: check_duplicate_source_pk(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, field: geonature.core.imports.models.BibFields) -> None

   Check for duplicate source primary keys in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   field : BibFields
       The field to check.


.. py:function:: check_dates(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, date_min_field: geonature.core.imports.models.BibFields = None, date_max_field: geonature.core.imports.models.BibFields = None) -> None

   Check the validity of dates in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : TEntity
       The entity to check.
   date_min_field : BibFields, optional
       The field representing the minimum date.
   date_max_field : BibFields, optional
       The field representing the maximum date.



.. py:function:: check_altitudes(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, alti_min_field: geonature.core.imports.models.BibFields = None, alti_max_field: geonature.core.imports.models.BibFields = None) -> None

   Check the validity of altitudes in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : TEntity
       The entity to check.
   alti_min_field : BibFields, optional
       The field representing the minimum altitude.
   alti_max_field : BibFields, optional
       The field representing the maximum altitude.



.. py:function:: check_depths(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, depth_min_field: geonature.core.imports.models.BibFields = None, depth_max_field: geonature.core.imports.models.BibFields = None) -> None

   Check the validity of depths in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : TEntity
       The entity to check.
   depth_min_field : BibFields, optional
       The field representing the minimum depth.
   depth_max_field : BibFields, optional
       The field representing the maximum depth.



.. py:function:: check_digital_proof_urls(imprt, entity, digital_proof_field)

   Checks for valid URLs in a given column of a transient table.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : TEntity
       The entity to check.
   digital_proof_field : TField
       The field containing the URLs to check.


.. py:function:: check_entity_data_consistency(imprt, entity, fields, grouping_field)

   Checks for rows with the same uuid, but different contents,
   in the same entity. Used mainely for parent entities.
   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   fields : BibFields
       The fields to check.
   grouping_field : BibFields
       The field to group identical rows.


.. py:function:: disable_duplicated_rows(imprt, entity, fields, grouping_field)

   When several rows have the same value in grouping field (typically UUID) field,
   first one is untouched but following rows have validity set to None (do not import).


