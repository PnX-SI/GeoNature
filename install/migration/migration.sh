#!/bin/bash

SERVICES=("geonature" "geonature-worker" "taxhub" "usershub")

currentdir="${PWD}"
previousdir="$(dirname ${currentdir})/geonature_old"

echo "Nouveau dossier GeoNature : ${currentdir}"
echo "Ancien dossier GeoNature : ${previousdir}"

if [ ! -d backend ] || [ ! -d frontend ]; then
    echo "Vous ne semblez pas être dans un dossier GeoNature, arrêt."
    exit 1
fi

read -p "Appuyer sur une touche pour quitter. Appuyer sur Y ou y pour continuer. " choice
if [ "$choice" != 'y' ] && [ "$choice" != 'Y' ]; then
    echo "Arrêt de la migration."
    exit
else
    echo "Lancement de la migration..."
fi

echo "Arrêt des services…"
for service in ${SERVICES[@]}; do
    sudo systemctl stop "${service}"
done

echo "Copie des fichiers de configuration…"
# Copy all config files (installation, GeoNature, modules)
cp ${previousdir}/config/*.{ini,toml} config/

echo "Vérification de la robustesse de la SECRET_KEY…"
sk_len=$(grep -E '^SECRET_KEY' config/geonature_config.toml | tail -n 1 | sed 's/SECRET_KEY = ['\''"]\(.*\)['\''"]/\1/' | wc -c)
if [ $sk_len -lt 20 ]; then
    sed -i "s|^SECRET_KEY = .*$|SECRET_KEY = '`openssl rand -hex 32`'|" config/geonature_config.toml
fi

echo "Copie des fichiers existant des composants personnalisables du frontend..."
# custom/custom.scss have been replaced by assets/custom.css
if [ ! -f ${previousdir}/frontend/src/assets/custom.css ]
then
  cp ${previousdir}/frontend/src/custom/custom.scss frontend/src/assets/custom.css
else 
  cp ${previousdir}/frontend/src/assets/custom.css frontend/src/assets/custom.css
fi
cp ${previousdir}/frontend/src/favicon.ico frontend/src/favicon.ico

# Handle frontend custom components
cp -r ${previousdir}/frontend/src/custom/* frontend/src/custom/

echo "Création des fichiers des nouveaux composants personnalisables du frontend..."
custom_component_dir="${currentdir}/frontend/src/custom/components/"
for file in $(find "${custom_component_dir}" -type f -name "*.sample"); do
    if [[ ! -f "${file%.sample}" ]]; then
        cp "${file}" "${file%.sample}"
    fi
done

echo "Mise à jour de node si nécessaire …"
cd "${currentdir}"/frontend
export NVM_DIR="$HOME/.nvm"
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install
nvm use

echo "Installation des dépendances node du frontend …"
npm ci --only=prod

echo "Installation des dépendances node du backend …"
cd ${currentdir}/backend/static
npm ci --only=prod

cd "${currentdir}"/backend
echo "Installation du virtual env..."
if [ -d 'venv' ]; then
  sudo rm -rf venv
fi
python3 -m venv venv

source venv/bin/activate
pip install --upgrade "pip>=19.3" "wheel" # https://www.python.org/dev/peps/pep-0440/#direct-references
pip install -e .. -r requirements.txt
# Installation des dépendances optionnelles
grep -E "^SENTRY_DSN" "${previousdir}/config/geonature_config.toml" > /dev/null && pip install sentry-sdk[flask]

echo "Installation des modules externes …"
if [ -d "${previousdir}/external_modules/" ]; then
    # Modules before 2.11
    cd "${currentdir}/backend"
    for module in ${previousdir}/external_modules/*; do
        if [ ! -L "${module}" ]; then
            echo "N’est pas un lien symbolique, ignore : ${module}"
            continue
        fi
        name=$(basename ${module})
        echo "Installation du module ${name} …"
        target=$(readlink ${module})
        geonature install-gn-module "${target}" "${name^^}" --build=false --upgrade-db=false
    done
fi
cd "${currentdir}/frontend/external_modules"
for module in ${previousdir}/frontend/external_modules/*; do
    if [ ! -L "${module}" ]; then
        echo "N’est pas un lien symbolique, ignore : ${module}"
        continue
    fi
    name=$(basename ${module})
    echo "Installation du module ${name} …"
    target=$(readlink ${module})
    if [ "$(basename ${target})" != "frontend" ]; then
        "Erreur, ne pointe pas vers un dossier frontend : ${module}"
        exit 1
    fi
    module_dir=$(dirname ${target})
    geonature install-gn-module "${module_dir}" "${name^^}" --build=false --upgrade-db=false
done

echo "Mise à jour des scripts systemd…"
cd ${currentdir}/install
./02_configure_systemd.sh
cd ${currentdir}/

if [ -f "/var/log/geonature.log" ]; then
    echo "Déplacement des fichiers de logs /var/log/geonature.log → /var/log/geonature/geonature.log …"
    sudo mkdir -p /var/log/geonature/
    sudo mv /var/log/geonature.log /var/log/geonature/geonature.log
    sudo chown $USER: -R /var/log/geonature/
fi

echo "Mise à jour des fichiers de configuration frontend et rebuild du frontend…"
geonature update-configuration

echo "Mise à jour de la base de données…"
geonature db autoupgrade
geonature upgrade-modules

echo "Redémarrage des services…"
for service in ${SERVICES[@]}; do
    sudo systemctl stop "${service}"
done

deactivate

echo "Migration terminée"
