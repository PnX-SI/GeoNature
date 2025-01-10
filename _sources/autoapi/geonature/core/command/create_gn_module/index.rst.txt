geonature.core.command.create_gn_module
=======================================

.. py:module:: geonature.core.command.create_gn_module


Functions
---------

.. autoapisummary::

   geonature.core.command.create_gn_module.install_gn_module
   geonature.core.command.create_gn_module.upgrade_modules_db


Module Contents
---------------

.. py:function:: install_gn_module(x_arg, module_path, module_code, build, upgrade_db)

   Command definition to install a GeoNature module

   Parameters
   ----------
   x_arg : list
       additional arguments
   module_path : str
       path of the module directory
   module_code : str
       code of the module, deprecated in future release
   build : boolean
       is the frontend rebuild
   upgrade_db : boolean
       migrate the revision associated with the module

   Raises
   ------
   ClickException
       No module found with the given module code
   ClickException
       No module code was detected in the code


.. py:function:: upgrade_modules_db(directory, sql, tag, x_arg, module_codes)

