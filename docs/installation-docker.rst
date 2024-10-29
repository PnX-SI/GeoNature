Docker
******

L'installation de GeoNature avec Docker est la manière la plus simple de déployer GeoNature, ses 4 modules externes principaux (Import, Export, Dashboard, Monitoring) et UsersHub, mais aussi de les mettre à jour, avec seulement quelques lignes de commandes.

Elle permet aussi d'installer GeoNature sur différents systèmes, et pas uniquement sur Debian, comme c'est le cas avec l'installation classique.

Elle peut néanmoins nécessiter de connaitre le fonctionnement de Docker pour ceux qui souhaitent aller plus loin et mettre en place une installation plus spécifique.

Docker Compose
--------------

Pour déployer facilement GeoNature avec Docker, utilisez le Docker Compose proposé et documenté dans le dépôt `GeoNature-Docker-services <https://github.com/PnX-SI/Geonature-Docker-services/>`_.

Pour des déploiements Docker plus avancés et spécifiques, des images Docker des différents outils (GeoNature, UsersHub, GeoNature et ses 4 modules externes principaux) sont automatiquement construites et publiées à chaque nouvelle version publiée.

Image backend
-------------

Des images pré-construites automatiquement sont présentes sur `Github <https://github.com/PnX-SI/GeoNature/pkgs/container/geonature-backend/versions?filters%5Bversion_type%5D=tagged>`_.

Les images tagguées `-wheels` contiennent les wheels Python de GeoNature, de ses dépendances et modules contrib, de manière à pouvoir être enrichies avec vos wheels provenant de vos propres modules (images de type « builder »).

Construction manuelle de l’image :

.. code-block:: bash

    DOCKER_BUILDKIT=1 docker build . \
            -f backend/Dockerfile \
            --target=prod \
            --tag=ghcr.io/pnx-si/geonature-backend:develop

Fonctionnement de l’image :

* GeoNature attend sa configuration dans le dossier ``/dist/config`` (à monter dans un volume afin de pouvoir la modifier).
  L’emplacement du fichier de configuration peut également être précisé via la variable d’environnement ``GEONATURE_CONFIG_FILE``.
* Il est également possible de fournir une configuration Python via la variable d’environnement ``GEONATURE_SETTINGS``.
* Les médias seront stockés dans le dossier ``/dist/media`` (à monter dans un volume afin de les sauvegarder).
* Toute variable d’environnement préfixée par ``GEONATURE_`` se verra traduite par un paramètre de configuration homonyme
  (`documentation Flask <https://flask.palletsprojects.com/en/2.2.x/api/#flask.Config.from_prefixed_env>`_).
  Si vous souhaitez définir une variable de configuration se trouvant dans une section, utilisez deux *underscore*.
  Par exemple, pour définir le paramètre ``NB_LAST_OBS`` de la section ``[SYNTHESE]``, on définira une variable d’environnement ``GEONATURE_SYNTHESE__NB_LAST_OBS``.
* Pour peupler la base de données, référez-vous au script ``install/03_create_db.sh``.

Image frontend
--------------

Des images pré-construites automatiquement sont présentes sur `Github <https://github.com/PnX-SI/GeoNature/pkgs/container/geonature-frontend/versions?filters%5Bversion_type%5D=tagged>`_.

Les images tagguées `-source` contiennent uniquement les sources de GeoNature et des modules contrib, et attendent d’être enrichies avec les sources de vos propres modules tandis que les images tagguées `-nginx` contiennent la configuration NGINX prête à l’emploi pour GeoNature (images de type « builder »).

Construction manuelle de l’image :

.. code-block:: bash

    DOCKER_BUILDKIT=1 docker build . \
            -f frontend/Dockerfile \
            --target=prod \
            --tag=ghcr.io/pnx-si/geonature-frontend:develop


Fonctionnement de l’image :

* La configuration NGINX de l’image est générée dynamiquement à son démarrage, à partir des variables d’environnement suivantes :

  * ``NGINX_PORT`` (défaut : 80)
  * ``NGINX_HOST`` (défaut : localhost)
  * ``NGINX_LOCATION`` (défaut : /, à modifier pour servir GeoNature sur un préfixe)

* La variable d’environnement ``API_ENDPOINT`` est lue au démarrage de l’image afin de mettre à jour le fichier de configuration du frontend ``assets/config.json``.
