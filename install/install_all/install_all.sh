#!/bin/bash
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
   echo "GeoNature must be installed on a 64-bits operating system ; your is $OS_BITS-bits" 1>&2
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

# Check OS and versions
if [ "$OS_NAME" != "debian" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour la distribution Debian\e[0m" >&2
    exit 1
fi

if [ "$OS_VERSION" != "10" ] && [ "$OS_VERSION" != "11" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour Debian 10 et Debian 11\e[0m" >&2
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

sudo apt-get install -y unzip git postgresql postgis python2 python3-pip python3-venv libgdal-dev libpangocairo-1.0-0 apache2 || exit 1

# Apache configuration
sudo a2enmod rewrite || exit 1
sudo a2enmod proxy || exit 1
sudo a2enmod proxy_http || exit 1
sudo systemctl restart apache2 || exit 1

# Installing GeoNature with current user
if [ ! -d "${GEONATURE_DIR}" ]; then
	echo "Téléchargement et installation de GeoNature ..."
	cd "${HOME}"
	wget https://github.com/PnX-SI/GeoNature/archive/$geonature_release.zip || exit 1
	unzip $geonature_release.zip || exit 1
	mv GeoNature-$geonature_release "${GEONATURE_DIR}"
fi

cd "${GEONATURE_DIR}"

# Updating GeoNature settings
cp config/settings.ini.sample config/settings.ini
echo "Installation de la base de données et configuration de l'application GeoNature ..."
my_url="${my_url//\//\\/}"
proxy_http="${proxy_http//\//\\/}"
proxy_https="${proxy_https//\//\\/}"


sed -i "s/my_local=.*$/my_local=$my_local/g" config/settings.ini
sed -i "s/my_url=.*$/my_url=$my_url/g" config/settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_geonaturedb/g" config/settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
sed -i "s/srid_local=.*$/srid_local=$srid_local/g" config/settings.ini
sed -i "s/install_sig_layers=.*$/install_sig_layers=$install_sig_layers/g" config/settings.ini
sed -i "s/install_grid_layer=.*$/install_grid_layer=$install_grid_layer/g" config/settings.ini
sed -i "s/install_default_dem=.*$/install_default_dem=$install_default_dem/g" config/settings.ini
sed -i "s/vectorise_dem=.*$/vectorise_dem=$vectorise_dem/g" config/settings.ini
sed -i "s/add_sample_data=.*$/add_sample_data=$add_sample_data/g" config/settings.ini
sed -i "s/usershub_release=.*$/usershub_release=$usershub_release/g" config/settings.ini
sed -i "s/taxhub_release=.*$/taxhub_release=$taxhub_release/g" config/settings.ini
sed -i "s/taxhub_release=.*$/taxhub_release=$taxhub_release/g" config/settings.ini
sed -i "s/install_module_validation=.*$/install_module_validation=$install_module_validation/g" config/settings.ini
sed -i "s/install_module_occhab=.*$/install_module_occhab=$install_module_occhab/g" config/settings.ini
sed -i "s/proxy_http=.*$/proxy_http=$proxy_http/g" config/settings.ini
sed -i "s/proxy_https=.*$/proxy_https=$proxy_https/g" config/settings.ini

cd "${GEONATURE_DIR}/install"

echo "Installation du backend GeoNature"
#./01_install_backend.sh || exit 1
echo "Installation de la base de données"
#./02_create_db.sh || exit 1
echo "Installation des modules GeoNature"
#./03_install_gn_modules.sh || exit 1
echo "Installation du frontend GeoNature"
#./04_install_frontend.sh || exit 1

sudo systemctl start geonature2

cd "${GEONATURE_DIR}"

# Apache configuration of GeoNature
envsubst '${DOMAIN_NAME} ${GEONATURE_DIR}' < "${GEONATURE_DIR}/install/assets/geonature_apache.conf" | sudo tee /etc/apache2/sites-available/geonature.conf || exit 1
envsubst '${DOMAIN_NAME} ${GEONATURE_DIR}' < "${GEONATURE_DIR}/install/assets/geonature_apache_maintenance.conf" | sudo tee /etc/apache2/sites-available/geonature_maintenance.conf || exit 1
sudo a2ensite geonature && sudo systemctl reload apache2 || exit 1


# Installing TaxHub with current user
if [ ! -d "${TAXHUB_DIR}" ]; then
	echo "Téléchargement et installation de TaxHub ..."
	cd "${HOME}"
	wget https://github.com/PnX-SI/TaxHub/archive/$taxhub_release.zip
	unzip $taxhub_release.zip
	mv TaxHub-$taxhub_release "${TAXHUB_DIR}"
fi

cd "${TAXHUB_DIR}"

# Setting configuration of TaxHub
echo "Configuration de l'application TaxHub ..."
cp settings.ini.sample settings.ini
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

# Creation of system files used by TaxHub
. create_sys_dir.sh
create_sys_dir || exit 1

# Apache configuration of TaxHub
envsubst '${TAXHUB_DIR}' < "${GEONATURE_DIR}/install/assets/taxhub_apache.conf" | sudo tee /etc/apache2/conf-available/taxhub.conf || exit 1

sudo a2enconf taxhub || exit 1
sudo a2enmod proxy || exit 1
sudo a2enmod proxy_http || exit 1

sudo systemctl restart apache2 || exit 1

# Installation of TaxHub
# lance install_app en le sourcant pour que la commande NVM soit disponible
./install_app.sh || exit 1
# Note: on ne lance pas install_db car celle-ci a déjà été créé par le processus d’installation de GeoNature

sudo systemctl start taxhub || exit 1

# Installation and configuration of UsersHub application (if activated)
if [ "$install_usershub_app" = true ]; then
    if [ ! -d "${TAXHUB_DIR}" ]; then
        echo "Installation de l'application Usershub"
        cd "${HOME}"
        wget https://github.com/PnX-SI/UsersHub/archive/$usershub_release.zip
        unzip $usershub_release.zip
        mv UsersHub-$usershub_release "${USERSHUB_DIR}"
    fi
    cd "${USERSHUB_DIR}"
    echo "Installation de la base de données et configuration de l'application UsersHub ..."
    cp config/settings.ini.sample config/settings.ini
    sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
    sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
    sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
    sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
    sed -i 's#url_application=.*#url_application='$my_url'usershub#g' config/settings.ini

    # Installation of UsersHub application
    # lance install_app en le sourcant pour que la commande NVM soit disponible
    ./install_app.sh

    envsubst '${TAXHUB_DIR}' < "${GEONATURE_DIR}/install/assets/usershub_apache.conf" | sudo tee /etc/apache2/conf-available/usershub.conf || exit 1

    sudo a2enconf usershub

    sudo systemctl reload apache2 || exit 1
fi


# fix nvm version
cd "${GEONATURE_DIR}"/frontend
nvm alias default
echo "L'installation est terminée!"
