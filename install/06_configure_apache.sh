#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"

cd "${BASE_DIR}"

export GEONATURE_DIR="${BASE_DIR}"
echo "Configuration Apache"
envsubst '${GEONATURE_DIR}' < "${BASE_DIR}/install/assets/geonature_apache.conf" | sudo tee /etc/apache2/conf-available/geonature.conf || exit 1
sudo a2enmod proxy || exit 1
sudo a2enmod proxy_http || exit 1
sudo a2enmod deflate || exit 1
# you may need to restart apache2 if proxy, proxy_http or deflate was not already enabled
