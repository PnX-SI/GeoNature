Installation de GeoNature avec Docker
*************************************

Prérequis
---------

* Docker
* Docker Compose


Installation
------------

* Build de l’image du backend ::

    docker compose build api

* Installation / mise-à-jour de la base de données ::

    docker compose run --rm api update.sh

* Génération des fichiers du frontend ::

    docker compose run --rm api geonature generate-frontend-config
    docker compose run --rm api geonature generate-frontend-modules-route
    docker compose run --rm api geonature generate-frontend-tsconfig
    docker compose run --rm api geonature generate-frontend-tsconfig-app

* Build de l’image du frontend ::

    docker compose build web

* Démarrage ::

    docker compose up -d


Installation en mode développement
----------------------------------

* Activer la configuration Docker Compose de développement ::

    ln -s docker-compose.dev.yml docker-compose.override.yml

* Dans ``backend/Dockerfile``, remplacer ``requirements.txt`` par ``requirements-dev.txt``
* Rebuilder l’image du backend ::

    docker compose build api

* Relancer les conteneurs ::

    docker compose restart


⚠ Les modifications des fichiers du frontend nécessite le rebuild et redémarrage de l’image du front ::

    docker compose build web
    docker compose restart web


Modification de la configuration
--------------------------------

Après modification de la configuration (``config/docker_config.toml`` par défaut), il faut :

* Re-générer la configuration du frontend ::

    docker compose run api geonature generate-frontend-config

* Re-builder l’image du frontend ::

    docker compose build web

* Redémarrer les conteneurs ::

    docker compose restart
