#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"

cd "${BASE_DIR}"
source backend/venv/bin/activate

export BACKEND_PREFIX=$(geonature get-config APPLICATION_ROOT)
export MEDIA_FOLDER=$(geonature get-config MEDIA_FOLDER)
export MEDIA_URL=$(geonature get-config MEDIA_URL)
export STATIC_FOLDER=$(geonature get-config STATIC_FOLDER)
export CUSTOM_STATIC_FOLDER=$(geonature get-config CUSTOM_STATIC_FOLDER)
export STATIC_URL=$(geonature get-config STATIC_URL)
export FRONTEND_FOLDER="${BASE_DIR}"/frontend/dist
export FRONTEND_PREFIX=$(geonature get-config URL_APPLICATION | python -c "import sys; from urllib.parse import urlsplit; print(urlsplit(sys.stdin.read()).path)")
export GUNICORN_URL="http://127.0.0.1:${BACKEND_PORT}"
export GEONATURE_APP_NAME="${GEONATURE_APP_NAME:-geonature}"
export BACKEND_PORT="${BACKEND_PORT:-8000}"
export DOMAIN_NAME=${DOMAIN_NAME:-test.geonature.fr}

deactivate

echo "Configuration Apache"
envsubst '${BACKEND_PREFIX} ${MEDIA_FOLDER} ${MEDIA_URL} ${STATIC_FOLDER} ${CUSTOM_STATIC_FOLDER} ${STATIC_URL} ${FRONTEND_FOLDER} ${FRONTEND_PREFIX} ${GUNICORN_URL}' < "${BASE_DIR}/install/assets/geonature_apache.conf" | sudo tee /etc/apache2/conf-available/${GEONATURE_APP_NAME}-geonature.conf || exit 1
envsubst '${DOMAIN_NAME} ${GEONATURE_APP_NAME}' < "${BASE_DIR}/install/assets/vhost_apache.conf" | sudo tee /etc/apache2/sites-available/${GEONATURE_APP_NAME}-geonature.conf || exit 1
sudo a2enmod rewrite || exit 1
sudo a2enmod proxy || exit 1
sudo a2enmod proxy_http || exit 1
sudo a2enmod deflate || exit 1
# you may need to restart apache2 if proxy, proxy_http or deflate was not already enabled
