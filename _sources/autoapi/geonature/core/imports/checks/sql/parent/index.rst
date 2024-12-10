geonature.core.imports.checks.sql.parent
========================================

.. py:module:: geonature.core.imports.checks.sql.parent


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.sql.parent.set_id_parent_from_destination
   geonature.core.imports.checks.sql.parent.set_parent_line_no
   geonature.core.imports.checks.sql.parent.check_no_parent_entity
   geonature.core.imports.checks.sql.parent.check_erroneous_parent_entities


Module Contents
---------------

.. py:function:: set_id_parent_from_destination(imprt: geonature.core.imports.models.TImports, parent_entity: geonature.core.imports.models.Entity, child_entity: geonature.core.imports.models.Entity, id_field: geonature.core.imports.models.BibFields, fields: List[geonature.core.imports.models.BibFields]) -> None

   Complete the id_parent column in the transient table of an import when the parent already exists in the destination table.

   Parameters
   ----------
   imprt : TImports
       The import to update.
   parent_entity : Entity
       The entity of the parent.
   child_entity : Entity
       The entity of the child.
   id_field : BibFields
       The field containing the id of the parent.
   fields : List[BibFields]
       The fields to use for matching the child with its parent in the destination table.


.. py:function:: set_parent_line_no(imprt: geonature.core.imports.models.TImports, parent_entity: geonature.core.imports.models.Entity, child_entity: geonature.core.imports.models.Entity, id_parent: geonature.core.imports.models.BibFields, parent_line_no: geonature.core.imports.models.BibFields, fields: List[geonature.core.imports.models.BibFields]) -> None

   Set parent_line_no on child entities when:
   - no parent entity on same line
   - parent entity is valid
   - looking for parent entity through each given field in fields

   Parameters
   ----------
   imprt : TImports
       The import to update.
   parent_entity : Entity
       The entity of the parent.
   child_entity : Entity
       The entity of the child.
   id_parent : BibFields
       The field containing the id of the parent.
   parent_line_no : BibFields
       The field containing the line number of the parent.
   fields : List[BibFields]
       The fields to use for matching the child with its parent in the destination table.


.. py:function:: check_no_parent_entity(imprt: geonature.core.imports.models.TImports, parent_entity: geonature.core.imports.models.Entity, child_entity: geonature.core.imports.models.Entity, id_parent: geonature.core.imports.models.BibFields, parent_line_no: geonature.core.imports.models.BibFields) -> None

   Station may be referenced:
   - on the same line (station_validity is not None)
   - by id_parent (parent already exists in destination)
   - by parent_line_no (new parent from another line of the imported file - see set_parent_line_no)

   Parameters
   ----------
   imprt : TImports
       The import to check.
   parent_entity : Entity
       The entity of the parent.
   child_entity : Entity
       The entity of the child.
   id_parent : BibFields
       The field containing the id of the parent.
   parent_line_no : BibFields
       The field containing the line number of the parent.


.. py:function:: check_erroneous_parent_entities(imprt: geonature.core.imports.models.TImports, parent_entity: geonature.core.imports.models.Entity, child_entity: geonature.core.imports.models.Entity, parent_line_no: geonature.core.imports.models.BibFields) -> None

   Check for erroneous (not valid) parent entities in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   parent_entity : Entity
       The entity of the parent.
   child_entity : Entity
       The entity of the child.
   parent_line_no : BibFields
       The field containing the line number of the parent.

   Notes
   -----
   # Note: if child entity reference parent entity by id_parent, this means the parent
   # entity is already in destination table so obviously valid.

   The error codes are:
       - ERRONEOUS_PARENT_ENTITY: the parent on the same line is not valid.


