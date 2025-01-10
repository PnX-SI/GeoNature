geonature.utils.module
======================

.. py:module:: geonature.utils.module


Functions
---------

.. autoapisummary::

   geonature.utils.module.iter_modules_dist
   geonature.utils.module.get_module_config_path
   geonature.utils.module.get_module_config
   geonature.utils.module.get_dist_from_code
   geonature.utils.module.iterate_revisions
   geonature.utils.module.alembic_branch_in_use
   geonature.utils.module.module_db_upgrade


Module Contents
---------------

.. py:function:: iter_modules_dist()

.. py:function:: get_module_config_path(module_code)

.. py:function:: get_module_config(module_dist)

.. py:function:: get_dist_from_code(module_code)

.. py:function:: iterate_revisions(script, base_revision)

   Iterate revisions without following depends_on directive.
   Useful to find all revisions of a given branch.


.. py:function:: alembic_branch_in_use(branch_name, directory, x_arg)

   Return true if at least one revision of the given branch is applied.


.. py:function:: module_db_upgrade(module_dist, directory=None, sql=False, tag=None, x_arg=[])

