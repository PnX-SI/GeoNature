geonature.core.users.models
===========================

.. py:module:: geonature.core.users.models


Classes
-------

.. autoapisummary::

   geonature.core.users.models.VUserslistForallMenu
   geonature.core.users.models.CorRole
   geonature.core.users.models.TApplications
   geonature.core.users.models.UserRigth


Module Contents
---------------

.. py:class:: VUserslistForallMenu

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'v_userslist_forall_menu'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_role


   .. py:attribute:: nom_role


   .. py:attribute:: prenom_role


   .. py:attribute:: nom_complet


   .. py:attribute:: id_menu


.. py:class:: CorRole(id_group, id_role)

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 'cor_roles'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_role_groupe


   .. py:attribute:: id_role_utilisateur


   .. py:attribute:: role


.. py:class:: TApplications

   Bases: :py:obj:`geonature.utils.env.DB.Model`


   .. py:attribute:: __tablename__
      :value: 't_applications'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_application


   .. py:attribute:: nom_application


   .. py:attribute:: desc_application


   .. py:attribute:: id_parent


.. py:class:: UserRigth(id_role=None, id_organisme=None, code_action=None, value_filter=None, module_code=None, nom_role=None, prenom_role=None)

   .. py:attribute:: id_role


   .. py:attribute:: id_organisme


   .. py:attribute:: value_filter


   .. py:attribute:: code_action


   .. py:attribute:: module_code


   .. py:attribute:: nom_role


   .. py:attribute:: prenom_role


