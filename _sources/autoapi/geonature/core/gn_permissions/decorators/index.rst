geonature.core.gn_permissions.decorators
========================================

.. py:module:: geonature.core.gn_permissions.decorators

.. autoapi-nested-parse::

   Decorators to protects routes with permissions



Functions
---------

.. autoapisummary::

   geonature.core.gn_permissions.decorators._forbidden_message
   geonature.core.gn_permissions.decorators.check_cruved_scope
   geonature.core.gn_permissions.decorators.permissions_required


Module Contents
---------------

.. py:function:: _forbidden_message(action, module_code, object_code)

.. py:function:: check_cruved_scope(action, module_code=None, object_code=None, *, get_scope=False)

   Decorator to protect routes with SCOPE CRUVED
   The decorator first check if the user is connected
   and then return the max user SCOPE permission for the action in parameter
   The decorator manages herited CRUVED from user's group and parent module (GeoNature)

   Parameters
   ----------
   action : str
       the requested action of the route <'C', 'R', 'U', 'V', 'E', 'D'>
   module_code : str, optional
       the code of the module (gn_commons.t_modules) (e.g. 'OCCTAX') for the requested permission, by default None
   object_code : str, optional
       the code of the object (gn_permissions.t_object) for the requested permission (e.g. 'PERMISSIONS'), by default None
   get_scope : bool, optional
       does the decorator should add the scope to view kwargs, by default False


.. py:function:: permissions_required(action, module_code=None, object_code=None)

