#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"

if [[ "${MODE}" = "dev" ]]; then
    echo "Skip configuration of systemd as not in prod mode"
    exit 0
fi

# Définir le nom de l'application (par défaut "geonature" si non défini)
export GEONATURE_APP_NAME="${GEONATURE_APP_NAME:-geonature}"
export BACKEND_PORT="${BACKEND_PORT:-8000}"
export BASE_DIR

echo "Installation de la configuration systemd-tmpfiles…"
envsubst '${USER} ${GEONATURE_APP_NAME}' < "${BASE_DIR}/install/assets/tmpfiles-geonature.conf" | sudo tee "/etc/tmpfiles.d/${GEONATURE_APP_NAME}.conf"
sudo systemd-tmpfiles --create "/etc/tmpfiles.d/${GEONATURE_APP_NAME}.conf"

echo "Installation des fichiers de service systemletestd…"
envsubst '${USER} ${BASE_DIR} ${GEONATURE_APP_NAME} ${BACKEND_PORT}' < "${BASE_DIR}/install/assets/geonature.service" | cat
envsubst '${USER} ${BASE_DIR} ${GEONATURE_APP_NAME} ${BACKEND_PORT}' < "${BASE_DIR}/install/assets/geonature.service" | sudo tee "/etc/systemd/system/${GEONATURE_APP_NAME}.service"
envsubst '${USER} ${BASE_DIR} ${GEONATURE_APP_NAME}' < "${BASE_DIR}/install/assets/geonature-worker.service" | sudo tee "/etc/systemd/system/${GEONATURE_APP_NAME}-worker.service"
envsubst '${GEONATURE_APP_NAME}' < "${BASE_DIR}/install/assets/geonature-reload.service" | sudo tee "/etc/systemd/system/${GEONATURE_APP_NAME}-reload.service"
envsubst '${BASE_DIR} ${GEONATURE_APP_NAME}' < "${BASE_DIR}/install/assets/geonature-reload@.path" | sudo tee "/etc/systemd/system/${GEONATURE_APP_NAME}-reload@.path"
sudo mkdir -p /etc/systemd/system-generators/
envsubst '${BASE_DIR} ${GEONATURE_APP_NAME}' < "${BASE_DIR}/install/assets/geonature-generator" | sudo tee "/etc/systemd/system-generators/${GEONATURE_APP_NAME}-generator"
sudo chmod +x "/etc/systemd/system-generators/${GEONATURE_APP_NAME}-generator"
sudo systemctl daemon-reload

echo "Installation de la configuration logrotate…"
envsubst '${USER} ${GEONATURE_APP_NAME}' < "${BASE_DIR}/install/assets/log_rotate" | sudo tee "/etc/logrotate.d/${GEONATURE_APP_NAME}"

echo "Activation de ${GEONATURE_APP_NAME} au démarrage…"
sudo systemctl enable "${GEONATURE_APP_NAME}.service"
sudo systemctl enable "${GEONATURE_APP_NAME}-worker.service"

echo "Vous pouvez maintenant démarrer ${GEONATURE_APP_NAME} avec la commande : sudo systemctl start ${GEONATURE_APP_NAME}"
echo "Vous pouvez maintenant démarrer le worker ${GEONATURE_APP_NAME} avec la commande : sudo systemctl start ${GEONATURE_APP_NAME}-worker"