geonature.core.notifications.models
===================================

.. py:module:: geonature.core.notifications.models

.. autoapi-nested-parse::

   Models of gn_notifications schema



Classes
-------

.. autoapisummary::

   geonature.core.notifications.models.NotificationMethod
   geonature.core.notifications.models.NotificationCategory
   geonature.core.notifications.models.NotificationTemplate
   geonature.core.notifications.models.Notification
   geonature.core.notifications.models.NotificationRule


Module Contents
---------------

.. py:class:: NotificationMethod

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_notifications_methods'



   .. py:attribute:: __table_args__


   .. py:attribute:: code


   .. py:attribute:: label


   .. py:attribute:: description


   .. py:property:: display


   .. py:method:: __str__()


.. py:class:: NotificationCategory

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_notifications_categories'



   .. py:attribute:: __table_args__


   .. py:attribute:: code


   .. py:attribute:: label


   .. py:attribute:: description


   .. py:property:: display


   .. py:method:: __str__()


.. py:class:: NotificationTemplate

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 'bib_notifications_templates'



   .. py:attribute:: __table_args__


   .. py:attribute:: code_category


   .. py:attribute:: code_method


   .. py:attribute:: content


   .. py:attribute:: category


   .. py:attribute:: method


   .. py:method:: __str__()


.. py:class:: Notification

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_notifications'



   .. py:attribute:: __table_args__


   .. py:attribute:: id_notification


   .. py:attribute:: id_role


   .. py:attribute:: title


   .. py:attribute:: content


   .. py:attribute:: url


   .. py:attribute:: code_status


   .. py:attribute:: creation_date


   .. py:attribute:: user


.. py:class:: NotificationRule

   Bases: :py:obj:`geonature.utils.env.db.Model`


   .. py:attribute:: __tablename__
      :value: 't_notifications_rules'



   .. py:attribute:: __table_args__


   .. py:attribute:: id


   .. py:attribute:: id_role


   .. py:attribute:: code_method


   .. py:attribute:: code_category


   .. py:attribute:: subscribed


   .. py:attribute:: method


   .. py:attribute:: category


   .. py:attribute:: user


   .. py:method:: filter_by_role_with_defaults(*, query, id_role=None)


