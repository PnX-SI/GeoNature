#!/usr/bin/env bash

set -e

. install_all.ini
. /etc/os-release
OS_NAME=$ID
OS_VERSION=$VERSION_ID
OS_BITS="$(getconf LONG_BIT)"
BASE_DIR=$(readlink -e "${0%/*}")
export GEONATURE_DIR="${HOME}/geonature"
export TAXHUB_DIR="${HOME}/taxhub"
export USERSHUB_DIR="${HOME}/usershub"


# Test the server architecture
if [ !"$OS_BITS" == "64" ]; then
   echo "GeoNature must be installed on a 64-bits operating system; yours is $OS_BITS-bits" 1>&2
   exit 1
fi

# Format my_url to set a / at the end
if [ "${my_url: -1}" != '/' ]
then
my_url=$my_url/
fi

# Remove http:// and remove final / from $my_url to create $my_domain
# No more used actually but can be useful if we want to create a Servername in Apache configuration
my_domain=$(echo $my_url | sed -r 's|^.*\/\/(.*)$|\1|')
my_domain=$(echo $my_domain | sed s'/.$//')
export DOMAIN_NAME="$my_domain"

# Check OS and versions
if [ "$OS_NAME" != "debian" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour la distribution Debian\e[0m" >&2
    exit 1
fi

if [ "$OS_VERSION" != "10" ] && [ "$OS_VERSION" != "11" ] && [ "$OS_VERSION" != "12" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour Debian 10, 11 ou 12\e[0m" >&2
    exit 1
fi

# Make sure this script is NOT run as root
if [ "$(id -u)" == "0" ]; then
   echo -e "\e[91m\e[1mThis script should NOT be run as root\e[0m" >&2
   echo -e "\e[91m\e[1mLancez ce script avec l'utilisateur courant : `whoami`\e[0m" >&2
   exit 1
fi


echo "############### Installation des paquets systèmes ###############"


# Installing required environment for GeoNature and TaxHub
echo "Installation de l'environnement logiciel..."
sudo apt-get install -y unzip git postgresql-postgis postgis python3-pip python3-venv python3-dev libpq-dev libgdal-dev libffi-dev libpangocairo-1.0-0 apache2 redis gettext-base || exit 1

if [ "${mode}" = "dev" ]; then
    sudo apt-get install -y xvfb || exit 1
fi

# Apache configuration
sudo a2enmod rewrite || exit 1
sudo a2enmod proxy || exit 1
sudo a2enmod proxy_http || exit 1
sudo systemctl restart apache2 || exit 1

# Installing GeoNature with current user
if [ ! -d "${GEONATURE_DIR}" ]; then
    echo "Téléchargement et installation de GeoNature ..."
	cd "${HOME}"
    if [ "${mode}" = "dev" ]; then
        git clone https://github.com/PnX-SI/GeoNature "${GEONATURE_DIR}"
        cd "${GEONATURE_DIR}"
        git checkout "$geonature_release"
        git submodule init
        git submodule update
    else
        escaped_geonature_release=${geonature_release//\//-}
        wget https://github.com/PnX-SI/GeoNature/archive/$geonature_release.zip -O GeoNature-$escaped_geonature_release.zip || exit 1
        unzip GeoNature-$escaped_geonature_release.zip || exit 1
        mv GeoNature-$escaped_geonature_release "${GEONATURE_DIR}"
    fi
fi

cd "${GEONATURE_DIR}"

# Updating GeoNature settings
cp config/settings.ini.sample config/settings.ini
echo "Installation de la base de données et configuration de l'application GeoNature ..."
my_url="${my_url//\//\\/}"
proxy_http="${proxy_http//\//\\/}"
proxy_https="${proxy_https//\//\\/}"


sed -i "s/MODE=.*$/MODE=$mode/g" config/settings.ini
sed -i "s/my_local=.*$/my_local=$my_local/g" config/settings.ini
sed -i "s/my_url=.*$/my_url=$my_url/g" config/settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_geonaturedb/g" config/settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
sed -i "s/srid_local=.*$/srid_local=$srid_local/g" config/settings.ini
sed -i "s/install_bdc_statuts=.*$/install_bdc_statuts=$install_bdc_statuts/g" config/settings.ini
sed -i "s/install_sig_layers=.*$/install_sig_layers=$install_sig_layers/g" config/settings.ini
sed -i "s/install_grid_layer=.*$/install_grid_layer=$install_grid_layer/g" config/settings.ini
sed -i "s/install_default_dem=.*$/install_default_dem=$install_default_dem/g" config/settings.ini
sed -i "s/vectorise_dem=.*$/vectorise_dem=$vectorise_dem/g" config/settings.ini
sed -i "s/install_ref_sensitivity=.*$/install_ref_sensitivity=$install_ref_sensitivity/g" config/settings.ini
sed -i "s/add_sample_data=.*$/add_sample_data=$add_sample_data/g" config/settings.ini
sed -i "s/usershub_release=.*$/usershub_release=$usershub_release/g" config/settings.ini
sed -i "s/taxhub_release=.*$/taxhub_release=$taxhub_release/g" config/settings.ini
sed -i "s/taxhub_release=.*$/taxhub_release=$taxhub_release/g" config/settings.ini
sed -i "s/install_module_validation=.*$/install_module_validation=$install_module_validation/g" config/settings.ini
sed -i "s/install_module_occhab=.*$/install_module_occhab=$install_module_occhab/g" config/settings.ini
sed -i "s/proxy_http=.*$/proxy_http=$proxy_http/g" config/settings.ini
sed -i "s/proxy_https=.*$/proxy_https=$proxy_https/g" config/settings.ini

cd "${GEONATURE_DIR}/install"

echo "Installation de nvm"
./00_install_nvm.sh || exit 1
echo "Installation du backend GeoNature"
./01_install_backend.sh || exit 1
echo "Installation des scripts systemd"
./02_configure_systemd.sh || exit 1
echo "Installation de la base de données"
./03_create_db.sh || exit 1
echo "Installation des modules GeoNature"
./04_install_gn_modules.sh || exit 1
echo "Installation du frontend GeoNature"
./05_install_frontend.sh || exit 1
echo "Installation de la config Apache pour GeoNature"
./06_configure_apache.sh || exit 1

if [ "${mode}" != dev ]; then
    sudo systemctl start geonature || exit 1
    sudo systemctl start geonature-worker || exit 1
    sudo systemctl enable geonature || exit 1
    sudo systemctl enable geonature-worker || exit 1
fi


# Installing TaxHub with current user
if [ ! -d "${TAXHUB_DIR}" ]; then
    echo "Téléchargement et installation de TaxHub ..."
    cd "${HOME}"
    if [ "${mode}" = "dev" ]; then
        git clone https://github.com/PnX-SI/TaxHub "${TAXHUB_DIR}" || exit 1
        cd "${TAXHUB_DIR}"
        git checkout "$taxhub_release" || exit 1
        git submodule init || exit 1
        git submodule update || exit 1
    else
        escaped_taxhub_release=${taxhub_release//\//-}
        wget https://github.com/PnX-SI/TaxHub/archive/$taxhub_release.zip -O TaxHub-$escaped_taxhub_release.zip || exit 1
        unzip TaxHub-$escaped_taxhub_release.zip || exit 1
        mv TaxHub-$escaped_taxhub_release "${TAXHUB_DIR}"
    fi
fi

cd "${TAXHUB_DIR}"

# Setting configuration of TaxHub
echo "Configuration de l'application TaxHub ..."
cp settings.ini.sample settings.ini
sed -i "s/mode=.*$/mode=$mode/g" settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=false/g" settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" settings.ini
sed -i "s/db_port=.*$/db_port=$pg_port/g" settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" settings.ini
sed -i "s/user_schema=.*$/user_schema=local/g" settings.ini
sed -i "s/usershub_host=.*$/usershub_host=$pg_host/g" settings.ini
sed -i "s/usershub_port=.*$/usershub_port=$pg_port/g" settings.ini
sed -i "s/usershub_db=.*$/usershub_db=$usershubdb_name/g" settings.ini
sed -i "s/usershub_user=.*$/usershub_user=$user_pg/g" settings.ini
sed -i "s/usershub_pass=.*$/usershub_pass=$user_pg_pass/g" settings.ini
sed -i "s/enable_https=.*$/enable_https=$enable_https/g" settings.ini
sed -i "s/https_cert_path=.*$/https_cert_path=$enable_https/g" settings.ini
sed -i "s/https_key_path=.*$/https_key_path=$enable_https/g" settings.ini

# Installation of TaxHub
# lance install_app en le sourcant pour que la commande NVM soit disponible
./install_app.sh || exit 1

source "${GEONATURE_DIR}/backend/venv/bin/activate"
geonature db upgrade taxhub-admin@head
deactivate

sudo systemctl start taxhub || exit 1
if [ "${mode}" != "dev" ]; then
    sudo systemctl enable taxhub || exit 1
fi

# Installation and configuration of UsersHub application (if activated)
if [ "$install_usershub_app" = true ]; then
    if [ ! -d "${USERSHUB_DIR}" ]; then
        echo "Installation de l'application Usershub"
        cd "${HOME}"
        if [ "${mode}" = "dev" ]; then
            git clone https://github.com/PnX-SI/UsersHub "${USERSHUB_DIR}" || exit 1
            cd "${USERSHUB_DIR}"
            git checkout "$usershub_release" || exit 1
            git submodule init || exit 1
            git submodule update || exit 1
        else
            escaped_usershub_release=${usershub_release//\//-}
            wget https://github.com/PnX-SI/UsersHub/archive/$usershub_release.zip -O UsersHub-$escaped_usershub_release.zip || exit 1
            unzip UsersHub-$escaped_usershub_release.zip || exit 1
            mv UsersHub-$escaped_usershub_release "${USERSHUB_DIR}"
        fi
    fi
    cd "${USERSHUB_DIR}"
    echo "Installation de la base de données et configuration de l'application UsersHub ..."
    cp config/settings.ini.sample config/settings.ini
    sed -i "s/mode=.*$/mode=$mode/g" config/settings.ini
    sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
    sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
    sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
    sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
    sed -i 's#url_application=.*#url_application='$my_url'usershub#g' config/settings.ini

    # Installation of UsersHub application
    ./install_app.sh

    # Installation of UsersHub database through geonature db as UsersHub does not known all revisions
    if [ "${mode}" != "dev" ]; then
	    # Tell GeoNature where to find UsersHub alembic revision files
	    grep '\[ALEMBIC\]' "${GEONATURE_DIR}/config/geonature_config.toml" > /dev/null || echo -e "\n[ALEMBIC]\nVERSION_LOCATIONS = '${USERSHUB_DIR}/app/migrations/versions/'" >> "${GEONATURE_DIR}/config/geonature_config.toml"
    fi
    source "${GEONATURE_DIR}/backend/venv/bin/activate"
    geonature db upgrade usershub-samples@head
    deactivate

    sudo systemctl start usershub || exit 1
    if [ "${mode}" != "dev" ]; then
        sudo systemctl enable usershub || exit 1
    fi
fi

# Upgrade depending branches like taxhub and usershub
source "${GEONATURE_DIR}/backend/venv/bin/activate"
geonature db autoupgrade
deactivate

# Apache vhost for GeoNature, TaxHub and UsersHub
envsubst '${DOMAIN_NAME}' < "${GEONATURE_DIR}/install/assets/vhost_apache.conf" | sudo tee /etc/apache2/sites-available/geonature.conf || exit 1
envsubst '${DOMAIN_NAME}' < "${GEONATURE_DIR}/install/assets/vhost_apache_maintenance.conf" | sudo tee /etc/apache2/sites-available/geonature_maintenance.conf || exit 1
sudo mkdir -p /var/www/geonature_maintenance/
sudo cp "${GEONATURE_DIR}/install/assets/maintenance.html" /var/www/geonature_maintenance/index.html
sudo a2ensite geonature || exit 1
sudo systemctl reload apache2 || exit 1

echo "L'installation est terminée!"
