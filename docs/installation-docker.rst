Docker
******

Depuis GeoNature 2.12, GeoNature fourni des images Docker pour le backend et le frontend.

.. warning::

    Les images Docker sont encore récentes, non éprouvées et peu documentées.
    Leur utilisation en production n’est de ce fait pas encore recommandée.


Prérequis
---------

* `Docker <https://docs.docker.com/engine/install/>`_


Image backend
-------------

Des images pré-buildées sont présentes sur `github <https://github.com/PnX-SI/GeoNature/pkgs/container/geonature-backend/versions?filters%5Bversion_type%5D=tagged>`_.

Les images tagguées `-wheels` contiennent les wheels Python de GeoNature, de ses dépendances et modules contrib, de manière à pouvoir être enrichie avec vos wheels provenant de vos propres modules (images de type « builder »).

Build manuel de l’image :

.. code-block:: bash

    DOCKER_BUILDKIT=1 docker build . \
            -f backend/Dockerfile \
            --target=prod \
            --tag=ghcr.io/pnx-si/geonature-backend:develop


Fonctionnement de l’image :

* GeoNature attend sa configuration dans le dossier ``/dist/config`` (à monter dans un volume afin de pouvoir la modifier).
  L’emplacement du fichier de configuration peut également être précisé via la variable d’environnement ``GEONATURE_CONFIG_FILE``.
* Il est également possible de fournir une configuration Python via la variable d’environnement ``GEONATURE_SETTINGS``.
* Les médias seront stocké dans le dossier ``/dist/media`` (à monter dans un volume afin de les sauvegarder).
* Toute variable d’environnement préfixée par ``GEONATURE_`` se verra traduit par un paramètre de configuration homonyme
  (`documentation Flask <https://flask.palletsprojects.com/en/2.2.x/api/#flask.Config.from_prefixed_env>`_).
  Si vous souhaitez définir une variable de configuration se trouvant dans une section, utilisé deux *underscore*.
  Par exemple, pour définir le paramètre ``NB_LAST_OBS`` de la section ``[SYNTHESE]``, on définira une variable d’environnement ``GEONATURE_SYNTHESE__NB_LAST_OBS``.
* Pour peupler la base de données, référez vous au script ``install/03_create_db.sh``.


Image frontend
--------------

Des images pré-buildées sont présentes sur `github <https://github.com/PnX-SI/GeoNature/pkgs/container/geonature-frontend/versions?filters%5Bversion_type%5D=tagged>`_.

Les images tagguées `-source` contiennent uniquement les sources de GeoNature et des modules contrib, et attendent d’être enrichie avec les sources de vos propres modules tandis que les images tagguées `-nginx` contiennent la configuration nginx prête à l’emploi pour GeoNature (images de type « builder »).

Build manuel de l’image :

.. code-block:: bash

    DOCKER_BUILDKIT=1 docker build . \
            -f frontend/Dockerfile \
            --target=prod \
            --tag=ghcr.io/pnx-si/geonature-frontend:develop


Fonctionnement de l’image :

* La configuration nginx de l’image est généré dynamiquement à son démarrage à partir des variables d’environnement suivantes :

  * ``NGINX_PORT`` (défaut : 80)
  * ``NGINX_HOST`` (défaut : localhost)
  * ``NGINX_LOCATION`` (défaut : /, à modifier pour servir GeoNature sur un préfixe)

* La variable d’environnement ``API_ENDPOINT`` est lue au démarrage de l’image afin de mettre à jour le fichier de configuration du frontend ``assets/config.json``.


Docker Compose
--------------

Une configuration Docker Compose est en cours de mise au point dans `la branche *docker-compose* du dépôt GeoNature-Docker-services <https://github.com/PnX-SI/Geonature-Docker-services/tree/docker-compose>`_.
