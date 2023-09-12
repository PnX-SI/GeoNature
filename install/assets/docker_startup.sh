#!/bin/bash

# script <geonature>/install/assert/docker_startup.sh
# ce script fait appel à <geonature>/install/03b_populate_db.sh (renommé  /populate_db.sh dans le docker)
# pour lancer les migrations alembic et les commandes d'ajouts de donneés (taxref, sensibilité)
# sauf si la variable d'environnement GEONATURE_SKIP_POPULATE_DB est définie à True,
# dans ce cas il lance gunicorn directement

set -o errexit
set -o pipefail


# creer les tables et peupler la base
if [ "${GEONATURE_SKIP_POPULATE_DB}" = true ]; then
    # pass
    :
else
    . /populate_db.sh
    if [ "$usershub" = true ];
    then
        geonature db upgrade usershub@head
        if [ "$usershub_samples" = true ];
        then
            geonature db upgrade usershub-samples@head
        fi
    fi

    if [ "$taxhub" = true ];
    then
        geonature db upgrade taxhub@head
        if [ "$taxhub_samples" = true ];
        then
            geonature db upgrade taxhub-admin@head
        fi
    fi

    geonature upgrade-modules-db
fi

# lancement de l'application
gunicorn "geonature:create_app()" \
    --name=geonature \
    --workers=2 \
    --threads=2 \
    --bind=0.0.0.0:8000 \
    --reload --reload-extra-file="${GEONATURE_CONFIG_FILE}"