geonature.core.gn_permissions.routes
====================================

.. py:module:: geonature.core.gn_permissions.routes

.. autoapi-nested-parse::

   Routes of the gn_permissions blueprint



Attributes
----------

.. autoapisummary::

   geonature.core.gn_permissions.routes.routes


Functions
---------

.. autoapisummary::

   geonature.core.gn_permissions.routes.logout


Module Contents
---------------

.. py:data:: routes

.. py:function:: logout()

   Route to logout with cruved

   .. :quickref: Permissions;

   To avoid multiples server call, we store the cruved in the session
   when the user logout we need clear the session to get the new cruved session


