#!/bin/bash

# script <geonature>/install/assert/docker_startup.sh
# ce script fait appel à <geonature>/install/03b_populate_db.sh (renommé  /populate_db.sh dans le docker)
# pour lancer les migrations alembic et les commandes d'ajouts de donneés (taxref, sensibilité)
# sauf si la variable d'environnement GEONATURE_SKIP_POPULATE_DB est définie à True,
# dans ce cas il lance gunicorn directement

set -o errexit
set -o pipefail

# Took from https://github.com/docker-library/postgres/blob/master/19/alpine3.24/docker-entrypoint.sh
# usage: file_env VAR
#    ie: file_env 'XYZ_DB_PASSWORD'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        printf >&2 'error: both %s and %s are set (but are exclusive)\n' "$var" "$fileVar"
        exit 1
    fi
    if [ "${!fileVar:-}" ]; then
        export "$var"="$(<"${!fileVar}")"
        unset "$fileVar"
    fi
}

file_env "GEONATURE_SECRET_KEY"
file_env "GEONATURE_SQLALCHEMY_DATABASE_URI"
file_env "GEONATURE_SENTRY_DSN"
file_env "GEONATURE_MAIL_CONFIG__MAIL_USERNAME"
file_env "GEONATURE_MAIL_CONFIG__MAIL_PASSWORD"

# creer les tables et peupler la base
if [ "${GEONATURE_SKIP_POPULATE_DB}" = true ]; then
    # pass
    :
else
    . /populate_db.sh
    if [ "$usershub" = true ]; then
        geonature db upgrade usershub@head
        if [ "$usershub_samples" = true ]; then
            geonature db upgrade usershub-samples@head
        fi
    fi

    geonature upgrade-modules-db
fi

exec "$@"
