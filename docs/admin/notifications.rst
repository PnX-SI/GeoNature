.. _notifications:

Gestion des notifications
-------------------------

GeoNature inclut un mécanisme de notifications permettant de notifier les utilisateurs par e-mail, ou directement dans l’application, lorsqu’un évènement se produit.

Ce mécanisme est construit autour de 3 composants :

- Les catégories de notifications (exemple : ``VALIDATION-STATUS-CHANGED``, ``IMPORT-DONE``, …)
- Les méthodes de notifications (exemple : ``DB`` (notifications affichées dans l’interface web), ``EMAIL``)
- Les templates de notifications : défini, pour chaque catégorie et chaque méthode, le contenu de la notification à envoyer

Les utilisateurs peuvent choisir de souscrire ou non à chaque catégorie et chaque méthode manuellement.

L’administrateur peut définir des règles de souscriptions aux notifications par défaut, pour notifier automatiquement les utilisateurs pour certaines catégories/méthodes sans souscription préalable de leur part. Les utilisateurs peuvent toutefois se désinscrire.

Tables
""""""

- ``gn_notifications.bib_notifications_categories`` : les catégories
- ``gn_notifications.bib_notifications_methods`` : les méthodes
- ``gn_notifications.bib_notifications_templates`` : les templates
- ``gn_notifications.t_notifications_rules`` : les règles de souscription aux notifications (par utilisateur, par groupe, ou par défaut)
- ``gn_notifications.t_notifications`` : les notifications pour la méthode ``DB`` sont sauvegardées dans cette table.

Visibilité des catégories de notifications
""""""""""""""""""""""""""""""""""""""""""

Les catégories de notifications peuvent être associées à un module et/ou un objet et/ou une action.
Dans ce cas, l’utilisateur ne peut souscrire à la catégorie que s’il possède des permissions sur le module / l’objet / l’action.
Ceci permet d’alléger l’interface de gestion des notifications pour les utilisateurs n’ayant pas accès à un module donné.


Règles de notifications
"""""""""""""""""""""""

La table ``gn_notifications.t_notifications_rules`` indique pour chaque tuple (rôle, catégorie, méthode) si une notification doit être envoyée (colonne ``subscribed``).

La colonne rôle peut contenir un utilisateur, un groupe, ou alors la valeur spéciale ``NULL`` signifiant qu’il s’agit de la règle de notification par défaut.
Pour déterminer si un utilisateur a souscrit à un tuple (catégorie, méthode), on cherche par ordre de priorité :

- règle portant sur l’utilisateur
- règle portant sur un groupe de l’utilisateur
- règle par défaut

En l’absence de règle, aucune notifications n’est envoyée.

.. note::

  Si un utilisateur appartient à plusieurs groupes et que plusieurs règles s’appliquent, sera appliqué la règle la plus permissive (``subscribed=TRUE``).

Templates
"""""""""

Les templates utilisent le language `jinja <https://jinja.palletsprojects.com/en/stable/>`_. Il est ainsi possible de générer le contenu des notifications en fonction de données provenant de l’évènement et de l’utilisateur destinataire.
Ainsi, le contexte jinja donne accès aux variables suivantes :

- ``role`` : le destinataire de la notification (instance de ``User``)
- ``title`` : le titre de la notification (``str``). Dans le cas d’une notification ``EMAIL``, il s’agit du sujet de celui-ci.
- ``url`` : l’url de redirection de la notification tel que définie par le module envoyant la notification. Dans le cas d’une notification ``DB`` s’affichant dans GeoNature, il s’agit de l’URL vers lequel l’utilisateur est redirigé lorsqu’il clique sur la notification.
- autres variables de contexte définies par le module envoyant la notification

S’il n’existe pas de template pour un couple (catégorie, méthode), la notification n’est pas envoyée. Par ailleurs, si l’évaluation du template produit une chaine de caractères vide, la notification n’est pas envoyée également.

.. note::

   Il est possible d’utiliser cette dernière propriété pour créer des notifications conditionnelles.
   Par exemple, notifier la modification du statut de validation d’une observation que si le validateur est différent du *digitizer*.
   Dans le cas où ils sont égaux, le template suivant donne une chaîne vide et aucune notification n’est envoyée :

   .. code:: jinja

    {% if synthese.digitizer != validation.validator_role %}...{% endif %}


Catégories de notifications
"""""""""""""""""""""""""""

Synthèse - commentaire
``````````````````````

Lors de l’ajout d’un commentaire sur une observation, une notification de la catégorie ``OBSERVATION-COMMENT`` est envoyé au *digitizer*, aux observateurs et aux commentateurs de l’observation.

Règles de notifications par défaut : ``DB``, ``EMAIL``

Contexte jinja :

- ``synthese`` : l’observation (instance de ``Synthese``)
- ``user`` : l’utilisateur ayant commenté (instance de ``User``)
- ``content`` : le contenu du commentaire (``str``)

Synthèse - création et modification d’observations
``````````````````````````````````````````````````

Lorsque des observations sont ajoutées (resp. modifiées) à la synthèse, une notification de la catégorie ``SYNTHESE-OBS-CREATED`` (resp. ``SYNTHESE-OBS-MODIFIED``) est envoyée à tous les utilisateurs ayant souscrit.

.. note::

  Par défaut, seule les catégories susmentionnées existent, mais toute catégorie de notifications utilisant le même préfixe est également notifiée, vous permettant de rajouter vos propres catégories.

Règles de notification par défaut : ∅

.. note::

   Il est déconseillé d’activer une règle de notification par défaut, sans quoi l’ensemble des utilisateurs de GeoNature sera notifié à chaque observation ajoutée ou modifiée, ce qui est peut être très lourd.

Ces notifications sont envoyées par une tâche asynchrone `celery-beat` dont la fréquence est contrôlée par le paramètre de configuration ``NOTIFICATIONS_CRONTAB`` de la section ``[SYNTHESE]`` (valeur par défaut : chaque nuit à 2h).
Ce fonctionnement permet de notifier la création / la modification d’observation, peu importe le module source, incluant par exemple *GN2PG*.

Contexte jinja :

- ``obs_ids`` : Liste des id_synthese créées / modifiées (liste d’integer).
- ``get_obs(obs_ids, permissions=None)`` : Utilitaire permettant d’obtenir les objets ``Synthese`` associés à la liste d’ID ``obs_ids``. Il est possible de passer une liste de permissions afin de filtrer la liste des objets synthèse à récupérer.
- ``get_permissions`` : La fonction ``geonature.core.get_permissions.utils.get_permissions`` (l’``id_role`` est automatiquement passé), pour usage avec ``get_obs``.
- ``observations`` : Liste des observations créées / modifiées, filtrée suivant les permissions ``R`` / ``SYNTHESE`` de l’utilisateur.

**Cas d’usage :** Notifier les validateurs

Nos validateurs ont des spécialitées !
Certains peuvent valider la faune tandis que d’autres peuvent valider la flore.
On souhaite donc notifier les validateurs en fonction de leur droit de validation.

- Créer une catégorie de notifications ``SYNTHESE-OBS-CREATED-TO-VALIDATE``
- Ajouter un groupe ``validateurs`` et y ajouter les utilisateurs validateurs.
- Ajouter une règles de notifications pour souscrire le groupe des validateurs à la catégorie précédement créée.
- S’inspirer d’un template existant et l’adapter ainsi :

  .. code:: jinja
  
    {%- set permissions = get_permissions(action_code="C", module_code="VALIDATION")
    {%- set observations = get_obs(obs_ids, permissions=permissions) %}
    {%- if observations -%}
    ...
    {%- endif -%}

**Cas d’usage :** Permettre de suivre uniquement les observations d'oiseaux 🐦

On veut permettre aux utilisateurs de souscrire à une notification de création d’observations d’oiseaux.

- Ajouter une catégorie de notifications ``SYNTHESE-OBS-CREATED-BIRDS``
- S’inspirer d’un template existant, et l’adapter ainsi :

  .. code:: jinja
  
    {%- set observations = observations | selectattr('taxref_tree', 'le', 185961) | list -%}
    {%- if observations -%}
    ...
    {%- endif -%}

Ceci permet de filtrer la liste des observations en ne retenant que ceux qui decendent de 185961 (Arves / Oiseaux).

**Cas d’usage :** Notifier uniquement le gestionnaire d’un territoire

On veut notifier les gestionnaires lorsqu’une observation est créé sur son territoire.
À noter qu’ici, c’est l’administrateur qui décide qui administre quel territoire, et non les utilisateurs qui souscrivent à un territoire (bien que ce cas soit réalisable facilement en transposant l’exemple des oiseaux).

.. note::

   Si les gestionnaires n’ont pas accès en lecture (``R SYNTHESE``) aux observations en dehors de son territoire, alors le comportement de filtrage par défaut est suffisant.

- Ajouter une catégorie de notifications ``SYNTHESE-OBS-CREATED-MANAGER``

  .. note::

    Les personnes non gestionnaires peuvent souscrire à cette catégorie dans l’interface de gestion de leur notifications.
    Bien que cela soit sans conséquence, il est possible d’empêcher cela en associant la catégorie à une permission que seul les gestionnaires possèdent (possiblement le module d’admin).

- Ajouter les gestionnaires à un groupe dédié
- Ajouter une règle de notification pour souscrire le groupe des gestionnaires à la catégorie ainsi créée
- S’inspirer d’un template existant, et l’adapter ainsi :

  .. code:: jinja

    {%- set users_area = {
        "user 1": 24,
        "user 2": 37,
    } -%}
    {%- set my_observations = [] -%}
    {%- for obs in observations -%}
    {%- if users_area[role.identifiant] in (obs.areas | map(attribute='id_area') | list) -%}
    {%- set _ = my_observations.append(obs) -%}
    {%- endif -%}
    {%- endfor -%}
    {%- if my_observations %} {{ my_observations | map(attribute="id_synthese") | join(",") }} {% endif -%}

Ainsi, pour chaque utilisateurs, on peuple une liste ``my_observations`` avec uniquement les observations qui sont attaché à un zonage propre à chacun.

Validation
``````````

Lors de la modification d’un statut de validation d’une observation, une notification de la catégorie ``VALIDATION-STATUS-CHANGED`` est envoyée au *digitizer* de l’observation.

.. note::

  Par défaut, seule la catégorie ``VALIDATION-STATUS-CHANGED`` existe, mais toutes les catégories de notifications correspondant au pattern SQL ``VALIDATION-STATUS-CHANGED%`` sont en réalité notifiées, vous permettant de rajouter vos propres catégories.

Règles de notifications par défaut : ``DB``, ``EMAIL``

Contexte jinja :

- ``synthese`` : l’observation (instance de ``Synthese``)
- ``validation`` : la validation (instance de ``TValidations``)
- ``status`` : le statut de validation (instance de ``TNomenclatures``)

Exemple de template :

.. code:: jinja

  Passage au statut <b>{{ status.mnemonique }}</b> pour votre observation <b>n°{{ synthese.id_synthese }}</b>

**Cas d’usage :** permettre aux utilisateurs de souscrire à un statut de validation spécifique

- Remplacer la catégorie de notification ``VALIDATION-STATUS-CHANGED`` par des catégories spécifiques :

  - ``VALIDATION-STATUS-CHANGED-TRES-PROBABLE``
  - ``VALIDATION-STATUS-CHANGED-PROBABLE``
  - ``VALIDATION-STATUS-CHANGED-DOUTEUX``
  - ...

- Rajouter des templates pour chaque catégorie, et pour chaque type de notifications (``DB`` & ``EMAIL``), exemple de template pour la catégorie ``VALIDATION-STATUS-CHANGED-TRES-PROBABLE`` :

.. code:: jinja

  {% if status.mnemonique == 'Certain - très probable' %}Passage au statut <b>{{ status.mnemonique }}</b> pour l'observation <b>n°{{ synthese.id_synthese }}</b>{% endif %}


Les utilisateurs peuvent alors souscrire à chaque catégorie indépendament.
Le module de validation envoie, par l’utilisation du caractère ``%``, la notification à toutes les catégories.
Mais, par exemple pour la catégorie ``VALIDATION-STATUS-CHANGED-TRES-PROBABLE``, lorsque le statut est différent de *très probable*, en raison de la condition `if` globale, l’évaluation du template donne une chaîne vide et la notification n’est donc pas envoyée.

Import
``````

Lorsqu’un import se termine, une notification de la catégorie ``IMPORT-DONE`` est envoyée à l’auteur de l’import.

Règles de notifications par défaut : ``DB``, ``EMAIL``

Permmissions nécessaires : module ``IMPORT``, objet ``IMPORT``

Contexte jinja :

- ``import`` : l’import (instance de ``TImports``)
- ``destination`` : la destination (instance de ``Destination``) (exemple : Synthèse, OccHab)
- ``url_notification_rules`` : URL de gestion des souscriptions aux notifications

.. note::

   Il serait pertinent de déplacer ``url_notification_rules`` dans le contexte par défaut car non spécifique à import.

Export
``````

Lorsque la génération d’un export se termine, une notification de la catégorie ``EXPORT-DONE`` est envoyée à la personne ayant demandé l’export.

Règles de notifications par défaut : ``DB``, ``EMAIL``

Permmissions nécessaires : ∅

.. note::

   Il serait pertinent de subordonner cette catégorie de notifications à l’accès au module d’import.

Contexte jinja :

- ``export`` : l’export (instance de ``Export``)
- ``nb_keep_day`` : valeur du paramètre de configuration ``nb_days_keep_file``
- ``export_failed`` : est-ce que l’export a réussi ? (``bool``)
