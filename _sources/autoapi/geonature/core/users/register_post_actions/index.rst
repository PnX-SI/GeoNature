geonature.core.users.register_post_actions
==========================================

.. py:module:: geonature.core.users.register_post_actions

.. autoapi-nested-parse::

   Action triggered after register action (create temp user, change password etc...)



Attributes
----------

.. autoapisummary::

   geonature.core.users.register_post_actions.function_dict


Functions
---------

.. autoapisummary::

   geonature.core.users.register_post_actions.validators_emails
   geonature.core.users.register_post_actions.validate_temp_user
   geonature.core.users.register_post_actions.execute_actions_after_validation
   geonature.core.users.register_post_actions.create_dataset_user
   geonature.core.users.register_post_actions.inform_user
   geonature.core.users.register_post_actions.send_email_for_recovery


Module Contents
---------------

.. py:function:: validators_emails()

   On souhaite récupérer une liste de mails


.. py:function:: validate_temp_user(data)

   Send an email after the action of account creation.

   :param admin_validation_required: if True an admin will receive an
   email to validate the account creation else the user himself
   receive the email.
   :type admin_validation_required: bool


.. py:function:: execute_actions_after_validation(data)

.. py:function:: create_dataset_user(user)

   After dataset validation, add a personnal AF and JDD so the user
   can add new user.


.. py:function:: inform_user(user)

   Send an email to inform the user that his account was validate.


.. py:function:: send_email_for_recovery(data)

   Send an email with the login of the role and the possibility to reset
   its password


.. py:data:: function_dict

