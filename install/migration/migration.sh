#!/usr/bin/env bash



SERVICES=("geonature" "geonature-worker" "usershub")

newdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../.." &> /dev/null && pwd )"
if (($# > 0)); then
    if [ -d "$1" ]; then
        olddir="$(realpath "$1")"
    else
        echo "Usage: $0 [OLD_GEONATURE_DIR]"
        exit 1
    fi
else
    olddir="$(dirname -- "${newdir}")/geonature_old"
fi

if [ ! -d "${newdir}/backend" ] || [ ! -d "${newdir}/frontend" ] || [ ! -f "${newdir}/VERSION" ]; then
    echo "Le nouveau dossier '${newdir}' ne semble pas contenir une installation GeoNature, arrêt."
    exit 1
fi
if [ ! -d "${olddir}/backend" ] || [ ! -d "${olddir}/frontend" ] || [ ! -f "${olddir}/VERSION" ]; then
    echo "L’ancien dossier '${olddir}' ne semble pas contenir une installation GeoNature, arrêt."
    exit 1
fi

# before 2.15 : suppression de l'application TaxHub - Rapatriement des médias TaxHub nécessite de connaitre l'emplacement de TaxHub
if [ ! -d "${newdir}/backend/media/taxhub" ];then
    TAXHUB_DIR="${HOME}/taxhub"
    if (($# > 1)); then
        TAXHUB_DIR="$(realpath "$2")"
    fi
    if [ ! -d "${TAXHUB_DIR}/apptax" ];then
        echo $2
        echo "Le dossier ${TAXHUB_DIR} ne semble pas contenir une installation de TaxHub. Veuillez spécifier le chemin vers TaxHub et celui de GeoNature : ./install/migration/migration.sh [OLD_GeoNature_dir] [OLD_TaxHub_dir]"
    fi
fi


echo "Nouveau dossier GeoNature : ${newdir} ($(cat "${newdir}/VERSION"))"
echo "Ancien dossier GeoNature : ${olddir} ($(cat "${olddir}/VERSION"))"


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
cp -n ${olddir}/config/*.{ini,toml} ${newdir}/config/
if [ -f "${olddir}/environ" ]; then
  cp -n "${olddir}/environ" "${newdir}/environ"
fi

if [ -d "${olddir}/custom" ]; then
    echo "Copie de la customisation…"
    mkdir -p "${newdir}"/custom/
    cp -n -r "${olddir}"/custom/* "${newdir}"/custom/
fi

echo "Vérification de la robustesse de la SECRET_KEY…"
sk_len=$(grep -E '^SECRET_KEY' "${newdir}/config/geonature_config.toml" | tail -n 1 | sed 's/SECRET_KEY = ['\''"]\(.*\)['\''"]/\1/' | wc -c)
if [ $sk_len -lt 20 ]; then
    sed -i "s|^SECRET_KEY = .*$|SECRET_KEY = '`openssl rand -hex 32`'|" "${newdir}/config/geonature_config.toml"
fi

echo "Déplacement des anciens fichiers personnalisés ..."
# before 2.12
if [ ! -f "${newdir}/custom/css/frontend.css" ] && [ -f "${olddir}/frontend/src/assets/custom.css" ] \
    && ! cmp -s "${olddir}/frontend/src/assets/custom.css" "${newdir}/backend/static/css/frontend.css"; then
  mkdir -p "${newdir}/custom/css/"
  cp "${olddir}/frontend/src/assets/custom.css" "${newdir}/custom/css/frontend.css"
fi
# before 2.7
if [ ! -f "${newdir}/custom/css/frontend.css" ] && [ -f "${olddir}/frontend/src/custom/custom.scss" ] \
    && ! cmp -s "${olddir}/frontend/src/custom/custom.scss" "${newdir}/backend/static/css/frontend.css"; then
  mkdir -p "${newdir}/custom/css/"
  cp "${olddir}/frontend/src/custom/custom.scss" "${newdir}/custom/css/frontend.css"
fi
# before 2.12
for img in login_background.jpg logo_sidebar.jpg logo_structure.png; do
  if [ ! -f "${newdir}/custom/images/${img}" ] && [ -f "${olddir}/frontend/src/custom/images/${img}" ] \
    && ! cmp -s "${olddir}/frontend/src/custom/images/${img}" "${newdir}/backend/static/images/${img}"; then
    mkdir -p "${newdir}/custom/images/"
    cp "${olddir}/frontend/src/custom/images/${img}" "${newdir}/custom/images/${img}"
  fi
done
# before 2.12
if [ ! -f "${newdir}/custom/images/favicon.ico" ] && [ -f "${olddir}/frontend/src/favicon.ico" ] \
    && ! cmp -s "${olddir}/frontend/src/favicon.ico" "${newdir}/backend/static/images/favicon.ico"; then
  mkdir -p "${newdir}/custom/images/"
  cp "${olddir}/frontend/src/favicon.ico" "${newdir}/custom/images/favicon.ico"
fi
# before 2.12
if [ ! -f "${newdir}/custom/css/metadata_pdf_custom.css" ] && [ -f "${olddir}/backend/static/css/custom.css" ] \
    && ! cmp -s "${olddir}/backend/static/css/custom.css" "${newdir}/backend/static/css/metadata_pdf_custom.css"; then
  mkdir -p "${newdir}/custom/css/"
  cp "${olddir}/backend/static/css/custom.css" "${newdir}/custom/css/metadata_pdf_custom.css"
fi



echo "Mise à jour de node si nécessaire …"
cd "${newdir}"/install
./00_install_nvm.sh
export NVM_DIR="$HOME/.nvm"
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

cd "${newdir}/frontend"
nvm use

echo "Installation des dépendances node du frontend …"
cd "${newdir}/frontend"
npm ci --only=prod

echo "Installation des dépendances node du backend …"
cd "${newdir}/backend/static"
npm ci --only=prod


echo "Mise à jour du backend …"
cd "${newdir}/install"
./01_install_backend.sh
source "${newdir}/backend/venv/bin/activate"

echo "Installation des modules externes …"
# Modules before 2.11
if [ -d "${olddir}/external_modules/" ]; then
    cd "${newdir}/backend"
    for module in ${olddir}/external_modules/*; do
        if [ ! -L "${module}" ]; then
            echo "N’est pas un lien symbolique, ignore : ${module}"
            continue
        fi
        name=$(basename ${module})
        echo "Installation du module ${name} …"
        target=$(realpath "$(readlink "${module}")")
        moduledir="${target/#${olddir}/${newdir}}"
        oldmoduledir="${target/#${newdir}/${olddir}}"
        if [ ! -f "${newdir}/config/${name}_config.toml" ] && [ -f "${oldmoduledir}/config/conf_gn_module.toml" ]; then
            echo "Récupération de l’ancien fichier de configuration…"
            if [ "${oldmoduledir}" != "${moduledir}" ]; then
                cp "${oldmoduledir}/config/conf_gn_module.toml" "${newdir}/config/${name}_config.toml"
            else
                mv "${moduledir}/config/conf_gn_module.toml" "${newdir}/config/${name}_config.toml"
            fi
        fi
        geonature install-gn-module "${moduledir}" "${name^^}" --build=false --upgrade-db=false
    done
fi
cd "${newdir}/frontend/external_modules"
# Modules since 2.11
if [ -d "${olddir}/frontend/external_modules/" ]; then
    for module in ${olddir}/frontend/external_modules/*; do
        if [ ! -L "${module}" ]; then
            echo "N’est pas un lien symbolique, ignore : ${module}"
            continue
        fi
        name=$(basename ${module})
        echo "Installation du module ${name} …"
        target=$(realpath "$(readlink "${module}")")
        if [ "$(basename ${target})" != "frontend" ]; then
            "Erreur, ne pointe pas vers un dossier frontend : ${module}"
            exit 1
        fi
        moduledir=$(dirname "${target/#${olddir}/${newdir}}")
        oldmoduledir=$(dirname "${target/#${newdir}/${olddir}}")
        if [ ! -f "${newdir}/config/${name}_config.toml" ] && [ -f "${oldmoduledir}/config/conf_gn_module.toml" ]; then
            echo "Récupération de l’ancien fichier de configuration…"
            if [ "${oldmoduledir}" != "${moduledir}" ]; then
                cp "${oldmoduledir}/config/conf_gn_module.toml" "${newdir}/config/${name}_config.toml"
            else
                mv "${moduledir}/config/conf_gn_module.toml" "${newdir}/config/${name}_config.toml"
            fi
        fi
        geonature install-gn-module "${moduledir}" "${name^^}" --build=false --upgrade-db=false
    done
fi

echo "Mise à jour des scripts systemd…"
cd ${newdir}/install
if [ -f /etc/systemd/system/geonature-reload.path ]; then  # before GN 2.12
    sudo systemctl stop geonature-reload.path
    sudo systemctl disable geonature-reload.path
    sudo rm /etc/systemd/system/geonature-reload.path
fi
./02_configure_systemd.sh
cd ${newdir}/

echo "Mise à jour de la configuration Apache …"
cd "${newdir}/install/"
./06_configure_apache.sh
sudo apachectl configtest && sudo systemctl reload apache2 || echo "Attention, configuration Apache incorrecte !"

# before GeoNature 2.10
if [ -f "/var/log/geonature.log" ]; then
    echo "Déplacement des fichiers de logs /var/log/geonature.log → /var/log/geonature/geonature.log …"
    sudo mkdir -p /var/log/geonature/
    sudo mv /var/log/geonature.log /var/log/geonature/geonature.log
    sudo chown $USER: -R /var/log/geonature/
fi

# Update the API ENDPOINT in frontend configuration file
api_end_point=$(geonature get-config API_ENDPOINT)
api_end_point=${api_end_point/'http:'/''}
echo "Set API_ENDPOINT to "$api_end_point" in frontend configuration file..."
echo '{"API_ENDPOINT":"'${api_end_point}'"}' > ${newdir}/frontend/src/assets/config.json

echo "Mise à jour des fichiers de configuration frontend et rebuild du frontend…"
geonature update-configuration

echo "Mise à jour de la base de données…"
# Si occtax est installé, alors il faut le mettre à jour en version 4c97453a2d1a (min.)
# *avant* de mettre à jour GeoNature (contrainte NOT NULL sur id_source dans la synthèse)
# Voir https://github.com/PnX-SI/GeoNature/issues/2186#issuecomment-1337684933
geonature db heads | grep "(occtax)" > /dev/null && geonature db upgrade occtax@4c97453a2d1a
geonature db autoupgrade || exit 1
geonature upgrade-modules-db || exit 1
# Mise à jour manuel de validation, la branche Alambic ayant été rajouté avec GN 2.13
geonature db heads | grep "(validation)" > /dev/null && geonature db upgrade validation@head

# On déplace les médias à la fin de la migration, pour ne pas se retrouver avec une nouvelle installation
# GeoNature cassé mais les médias déjà déplacé de l’ancien GN au nouveau GN non fonctionnel.
echo "Déplacement des anciens fichiers static vers les médias …"  # before GN 2.12
cd "${olddir}/backend"
if [ -d static/medias ]; then mkdir -p media/attachments; mv static/medias/* media/attachments/; fi  # medias becomes attachments
if [ -d static/pdf ]; then mkdir -p media; mv static/pdf media/; fi
if [ -d static/exports ]; then mkdir -p media; mv static/exports media/; fi
if [ -d static/geopackages ]; then mkdir -p media; mv static/geopackages media/; fi
if [ -d static/shapefiles ]; then mkdir -p media; mv static/shapefiles media/; fi
if [ -d static/mobile ]; then mkdir -p media; mv static/mobile media/; fi
echo "Déplacement des médias …"
shopt -s nullglob
for dir in "${olddir}"/backend/media/*; do
    if [ -d "${newdir}"/backend/media/$(basename "${dir}") ]; then
        for subdir in "${dir}"/*; do
            mv -n "${subdir}" "${newdir}"/backend/media/$(basename "${dir}")/
        done
    else
        mv -n "${dir}" "${newdir}"/backend/media/
    fi
done
shopt -u nullglob

echo "Redémarrage des services…"
for service in ${SERVICES[@]}; do
    sudo systemctl start "${service}"
done

deactivate


# before 2.15 - Suppression de l'application Taxhub et de la configuration du service systemctl
if [ -f "/etc/systemd/system/taxhub.service" ]; then
    sudo systemctl stop taxhub 
    sudo systemctl disable taxhub
    sudo rm /etc/systemd/system/taxhub
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
fi

# before 2.15 - Suppression de l'application Taxhub et de la configuration apache
if [ -f "/etc/apache2/sites-available/taxhub.conf" ]; then
    rm /etc/apache2/sites-available/taxhub.conf
fi

if [ -f "/etc/apache2/sites-available/taxhub-le-ssl.conf" ]; then
    rm /etc/apache2/sites-available/taxhub-le-ssl.conf
    rm -r /var/log/taxhub/
fi

if [ -f "/etc/apache2/conf-available/taxhub.conf" ]; then
    rm /etc/apache2/conf-available/taxhub.conf
fi

if [ -f "/etc/apache2/conf-available/taxhub-le-ssl.conf" ]; then
    rm /etc/apache2/conf-available/taxhub-le-ssl.conf
    rm -r /var/log/taxhub/
fi

# before 2.15 - Suppression de l'application Taxhub et rapatriement des médias TaxHub
if [ ! -d "${newdir}/backend/media/taxhub" ];then
    mkdir -p "${newdir}/backend/media/taxhub"
    cp -r "${TAXHUB_DIR}"/static/medias/* "${newdir}"/backend/media/taxhub/
fi


sudo apachectl restart
echo "Migration terminée"
