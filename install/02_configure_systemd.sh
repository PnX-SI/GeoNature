#!/usr/bin/env bash


set -eo pipefail


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"


if [[ "${MODE}" = "dev" ]]; then
    echo "Skip configuration of systemd as not in prod mode"
    exit 0
fi

echo "Installation de la configuration systemd-tmpfiles…"
envsubst '${USER}' < "${BASE_DIR}/install/assets/tmpfiles-geonature.conf" | sudo tee /etc/tmpfiles.d/geonature.conf
sudo systemd-tmpfiles --create /etc/tmpfiles.d/geonature.conf

echo "Installation des fichiers de service systemd…"
envsubst '${USER} ${BASE_DIR}' < "${BASE_DIR}/install/assets/geonature.service" | sudo tee /etc/systemd/system/geonature.service
envsubst '${USER} ${BASE_DIR}' < "${BASE_DIR}/install/assets/geonature-worker.service" | sudo tee /etc/systemd/system/geonature-worker.service
cat "${BASE_DIR}/install/assets/geonature-reload.service" | sudo tee /etc/systemd/system/geonature-reload.service
envsubst '${BASE_DIR}' < "${BASE_DIR}/install/assets/geonature-reload@.path" | sudo tee /etc/systemd/system/geonature-reload@.path
sudo mkdir -p /etc/systemd/system-generators/
envsubst '${BASE_DIR}' < "${BASE_DIR}/install/assets/geonature-generator" | sudo tee /etc/systemd/system-generators/geonature-generator
sudo chmod +x /etc/systemd/system-generators/geonature-generator
sudo systemctl daemon-reload

echo "Installation de la configuration logrotate…"
envsubst '${USER}' < "${BASE_DIR}/install/assets/log_rotate" | sudo tee /etc/logrotate.d/geonature

echo "Activation de geonature au démarrage…"
sudo systemctl enable geonature.service
sudo systemctl enable geonature-worker.service

echo "Vous pouvez maintenant démarrer GeoNature avec la commande : sudo systemctl start geonature"
echo "Vous pouvez maintenant démarrer le worker GeoNature avec la commande : sudo systemctl start geonature-worker"
