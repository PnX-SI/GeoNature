geonature.utils.utilsmails
==========================

.. py:module:: geonature.utils.utilsmails


Attributes
----------

.. autoapisummary::

   geonature.utils.utilsmails.log
   geonature.utils.utilsmails.name_address_email_regex


Functions
---------

.. autoapisummary::

   geonature.utils.utilsmails.send_mail
   geonature.utils.utilsmails.clean_recipients
   geonature.utils.utilsmails.split_name_address


Module Contents
---------------

.. py:data:: log

.. py:data:: name_address_email_regex

.. py:function:: send_mail(recipients, subject, msg_html)

   Envoi d'un email à l'aide de Flask_mail.

   .. :quickref:  Fonction générique d'envoi d'email.

   Parameters
   ----------
   recipients : str or [str]
       Chaine contenant des emails séparés par des virgules ou liste
       contenant des emails. Un email encadré par des chevrons peut être
       précédé d'un libellé qui sera utilisé lors de l'envoi.

   subject : str
       Sujet de l'email.
   msg_html : str
       Contenu de l'eamil au format HTML.

   Returns
   -------
   void
       L'email est envoyé. Aucun retour.


.. py:function:: clean_recipients(recipients)

   Retourne une liste contenant des emails (str) ou des tuples
   contenant un libelé et l'email correspondant.

   Parameters
   ----------
   recipients : str or [str]
       Chaine contenant des emails séparés par des virgules ou liste
       contenant des emails. Un email encadré par des chevrons peut être
       précédé d'un libellé qui sera utilisé lors de l'envoi.

   Returns
   -------
   [str or tuple]
       Liste contenant des chaines (email) ou des tuples (libellé, email).


.. py:function:: split_name_address(email)

   Sépare le libellé de l'email. Le libellé doit précéder l'email qui
   doit être encadré par des chevons. Format : `libellé <email>`. Ex. :
   `Carl von LINNÉ <c.linnaeus@linnaeus.se>`.

   Parameters
   ----------
   email : str
       Chaine contenant un email avec ou sans libellé.

   Returns
   -------
   str or tuple
       L'email simple ou un tuple contenant ("libellé", "email").


