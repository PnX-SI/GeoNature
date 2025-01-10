geonature.core.gn_permissions.tools
===================================

.. py:module:: geonature.core.gn_permissions.tools


Attributes
----------

.. autoapisummary::

   geonature.core.gn_permissions.tools.log


Functions
---------

.. autoapisummary::

   geonature.core.gn_permissions.tools._get_user_permissions
   geonature.core.gn_permissions.tools.get_user_permissions
   geonature.core.gn_permissions.tools._get_permissions
   geonature.core.gn_permissions.tools.get_permissions
   geonature.core.gn_permissions.tools.get_scope
   geonature.core.gn_permissions.tools.get_scopes_by_action
   geonature.core.gn_permissions.tools.has_any_permissions
   geonature.core.gn_permissions.tools.has_any_permissions_by_action


Module Contents
---------------

.. py:data:: log

.. py:function:: _get_user_permissions(id_role)

.. py:function:: get_user_permissions(id_role=None)

.. py:function:: _get_permissions(id_role, module_code, object_code, action_code)

.. py:function:: get_permissions(action_code, id_role=None, module_code=None, object_code=None)

   This function returns a set of all the permissions that match (action_code, id_role, module_code, object_code).
   If module_code is None, it is set as the code of the current module or as "GEONATURE" if no current module found.
   If object_code is None, it is set as the code of the current object or as "ALL" if no current object found.

   :returns : the list of permissions that match, and an empty list if no match


.. py:function:: get_scope(action_code, id_role=None, module_code=None, object_code=None, bypass_warning=False)

   This function gets the final scope permission.

   It takes the maximum for all the permissions that match (action_code, id_role, module_code, object_code) and with
   of a "SCOPE" filter type.

   :returns : (int) The scope computed for specified arguments


.. py:function:: get_scopes_by_action(id_role=None, module_code=None, object_code=None)

   This function gets the scopes permissions for each one of the 6 actions in "CRUVED",
   that match (id_role, module_code, object_code)

   :returns : (dict) A dict of the scope for each one of the 6 actions (the char in "CRUVED")


.. py:function:: has_any_permissions(action_code, id_role=None, module_code=None, object_code=None) -> bool

   This function return the scope for an action, a module and an object as a Boolean
   Use for frontend


.. py:function:: has_any_permissions_by_action(id_role=None, module_code=None, object_code=None)

   This function gets the scopes permissions for each one of the 6 actions in "CRUVED",
   that match (id_role, module_code, object_code)

   :returns : (dict) A dict of the boolean for each one of the 6 actions (the char in "CRUVED")


