#!/usr/bin/env bash

set -eo pipefail

echo "Installation de nvm"

NVM_VERSION="${NVM_VERSION:-v0.39.1}"
NVM_DIR="${NVM_DIR:-/usr/local/nvm}"

if [ ! -s "${NVM_DIR}/nvm.sh" ]; then
    sudo mkdir -p "${NVM_DIR}"
    if [ ! -d "${NVM_DIR}/.git" ]; then
        sudo git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}"
    fi
    sudo git -C "${NVM_DIR}" fetch --tags --force
    sudo git -C "${NVM_DIR}" checkout "${NVM_VERSION}"
fi

sudo tee /etc/profile.d/geonature-nvm.sh >/dev/null << EOF
export NVM_DIR="${NVM_DIR}"
[ -s "\${NVM_DIR}/nvm.sh" ] && . "\${NVM_DIR}/nvm.sh"
EOF
sudo chmod 0644 /etc/profile.d/geonature-nvm.sh

export NVM_DIR

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
NODE_VERSION=$(cat "$SCRIPT_DIR/../frontend/.nvmrc")
sudo bash -lc "export NVM_DIR='${NVM_DIR}'; . '${NVM_DIR}/nvm.sh'; nvm install '${NODE_VERSION}'"
