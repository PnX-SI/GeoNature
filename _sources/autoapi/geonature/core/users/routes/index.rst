geonature.core.users.routes
===========================

.. py:module:: geonature.core.users.routes


Attributes
----------

.. autoapisummary::

   geonature.core.users.routes.routes
   geonature.core.users.routes.log
   geonature.core.users.routes.s
   geonature.core.users.routes.user_fields
   geonature.core.users.routes.organism_fields


Functions
---------

.. autoapisummary::

   geonature.core.users.routes.get_roles_by_menu_id
   geonature.core.users.routes.get_roles_by_menu_code
   geonature.core.users.routes.get_listes
   geonature.core.users.routes.get_role
   geonature.core.users.routes.get_roles
   geonature.core.users.routes.get_organismes
   geonature.core.users.routes.get_organismes_jdd
   geonature.core.users.routes.inscription
   geonature.core.users.routes.login_recovery
   geonature.core.users.routes.confirmation
   geonature.core.users.routes.after_confirmation
   geonature.core.users.routes.update_role
   geonature.core.users.routes.change_password
   geonature.core.users.routes.new_password


Module Contents
---------------

.. py:data:: routes

.. py:data:: log

.. py:data:: s

.. py:data:: user_fields

.. py:data:: organism_fields

.. py:function:: get_roles_by_menu_id(id_menu)

   Retourne la liste des roles associés à un menu

   .. :quickref: User;

   :param id_menu: the id of user list (utilisateurs.bib_list)
   :type id_menu: int
   :query str nom_complet: begenning of complet name of the role


.. py:function:: get_roles_by_menu_code(code_liste)

   Retourne la liste des roles associés à une liste (identifiée par son code)

   .. :quickref: User;

   :param code_liste: the code of user list (utilisateurs.t_lists)
   :type code_liste: string
   :query str nom_complet: begenning of complet name of the role


.. py:function:: get_listes()

.. py:function:: get_role(id_role)

   Get role detail

   .. :quickref: User;

   :param id_role: the id user
   :type id_role: int


.. py:function:: get_roles()

   Get all roles

   .. :quickref: User;


.. py:function:: get_organismes()

   Get all organisms

   .. :quickref: User;


.. py:function:: get_organismes_jdd()

   Get all organisms and the JDD where there are actor and where
   the current user hase autorization with its cruved

   .. :quickref: User;


.. py:function:: inscription()

   Ajoute un utilisateur à utilisateurs.temp_user à partir de l'interface geonature
   Fonctionne selon l'autorisation 'ENABLE_SIGN_UP' dans la config.
   Fait appel à l'API UsersHub


.. py:function:: login_recovery()

   Call UsersHub API to create a TOKEN for a user
   A post_action send an email with the user login and a link to reset its password
   Work only if 'ENABLE_SIGN_UP' is set to True


.. py:function:: confirmation()

   Validate a account after a demande (this action is triggered by the link in the email)
   Create a personnal JDD as post_action if the parameter AUTO_DATASET_CREATION is set to True
   Fait appel à l'API UsersHub


.. py:function:: after_confirmation()

.. py:function:: update_role()

   Modifie le role de l'utilisateur du token en cours


.. py:function:: change_password()

   Modifie le mot de passe de l'utilisateur connecté et de son ancien mdp
   Fait appel à l'API UsersHub


.. py:function:: new_password()

   Modifie le mdp d'un utilisateur apres que celui-ci ai demander un renouvelement
   Necessite un token envoyer par mail a l'utilisateur


