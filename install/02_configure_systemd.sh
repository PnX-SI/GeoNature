#!/bin/bash


set -eo pipefail


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"


if [[ "${MODE}" != "prod" ]]; then
    echo "Skip configuration of systemd as not in prod mode"
    exit 0
fi

echo "Installation de la configuration systemd-tmpfiles…"
envsubst '${USER}' < "${BASE_DIR}/install/assets/tmpfiles-geonature.conf" | sudo tee /etc/tmpfiles.d/geonature.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/geonature.conf

echo "Installation du service-file systemd…"
envsubst '${USER} ${BASE_DIR}' < "${BASE_DIR}/install/assets/geonature.service" | sudo tee /etc/systemd/system/geonature.service
sudo systemctl daemon-reload

echo "Activation de geonature au démarrage…"
sudo systemctl enable geonature || exit 1

echo "Installation de la configuration logrotate…"
envsubst '${USER}' < "${BASE_DIR}/install/assets/log_rotate" | sudo tee /etc/logrotate.d/geonature

echo "Vous pouvez maintenant démarrer GeoNature avec la commande : sudo systemctl start geonature"
