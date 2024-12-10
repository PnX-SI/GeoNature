geonature.core.imports.checks.sql.geo
=====================================

.. py:module:: geonature.core.imports.checks.sql.geo


Functions
---------

.. autoapisummary::

   geonature.core.imports.checks.sql.geo.set_geom_point
   geonature.core.imports.checks.sql.geo.convert_geom_columns
   geonature.core.imports.checks.sql.geo.check_is_valid_geometry
   geonature.core.imports.checks.sql.geo.check_geometry_outside


Module Contents
---------------

.. py:function:: set_geom_point(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, geom_4326_field: geonature.core.imports.models.BibFields, geom_point_field: geonature.core.imports.models.BibFields) -> None

   Set the_geom_point as the centroid of the geometry in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to update.
   entity : Entity
       The entity to update.
   geom_4326_field : BibFields
       Field containing the geometry in the transient table.
   geom_point_field : BibFields
       Field to store the centroid of the geometry in the transient table.

   Returns
   -------
   None


.. py:function:: convert_geom_columns(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, geom_4326_field: geonature.core.imports.models.BibFields, geom_local_field: geonature.core.imports.models.BibFields) -> None

   Convert the geometry from the file SRID to the local SRID in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to update.
   entity : Entity
       The entity to update.
   geom_4326_field : BibFields
       Field representing the geometry in the transient table in SRID 4326.
   geom_local_field : BibFields
       Field representing the geometry in the transient table in the local SRID.


.. py:function:: check_is_valid_geometry(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, wkt_field: geonature.core.imports.models.BibFields, geom_field: geonature.core.imports.models.BibFields) -> None

   Check if the geometry is valid in the transient table of an import.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   wkt_field : BibFields
       Field containing the source WKT of the geometry.
   geom_field : BibFields
       Field containing the geometry from the WKT in `wkt_field` to be validated.



.. py:function:: check_geometry_outside(imprt: geonature.core.imports.models.TImports, entity: geonature.core.imports.models.Entity, geom_local_field: geonature.core.imports.models.BibFields, id_area: int) -> None

   For an import, check if one or more geometries in the transient table are outside a defined area.

   Parameters
   ----------
   imprt : TImports
       The import to check.
   entity : Entity
       The entity to check.
   geom_local_field : BibFields
       Field containing the geometry in the local SRID of the area.
   id_area : int
       The id of the area to check if the geometry is inside.



