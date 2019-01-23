#!/bin/bash
. install_all.ini
. /etc/os-release
OS_NAME=$ID
OS_VERSION=$VERSION_ID
OS_BITS="$(getconf LONG_BIT)"

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

# Check OS and versions
if [ "$OS_NAME" != "debian" ] && [ "$OS_NAME" != "ubuntu" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour les distributions Debian et Ubuntu\e[0m" >&2
    exit 1
fi

if [ "$OS_VERSION" != "8" ] && [ "$OS_VERSION" != "9" ] && [ "$OS_VERSION" != "18.04" ] && [ "$OS_VERSION" != "16.04" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour Debian 8/9 et Ubuntu 16.04/18.04\e[0m" >&2
    exit 1
fi

# Make sure this script is NOT run as root
if [ "$(id -u)" == "0" ]; then
   echo -e "\e[91m\e[1mThis script should NOT be run as root\e[0m" >&2
   echo -e "\e[91m\e[1mLancez ce script avec l'utilisateur courant : `whoami`\e[0m" >&2
   exit 1
fi

# Create log folder if it don't already exists
if [ ! -d 'var' ]
then
  mkdir var
  chmod -R 775 var
fi

if [ ! -d 'var/log' ]
then
  mkdir var/log
  chmod -R 775 var/log/
fi

if [ -f  var/log/install_app.log ]; then
  rm  var/log/install_app.log
fi
touch  var/log/install_app.log

echo "############### Installation des paquets systèmes ###############"&>>  var/log/install_app.log


# Updating language locale
sudo apt-get install -y locales
sudo sed -i "s/# $my_local/$my_local/g" /etc/locale.gen
sudo locale-gen $my_local
echo "export LC_ALL=$my_local" >> ~/.bashrc
echo "export LANG=$my_local" >> ~/.bashrc
echo "export LANGUAGE=$my_local" >> ~/.bashrc
source ~/.bashrc

# Installing required environment for GeoNature and TaxHub
echo "Installation de l'environnement logiciel..."

sudo apt-get -y install ntpdate 2> var/log/install_app.log
sudo ntpdate-debian &>>  var/log/install_app.log 2> var/log/install_app.log
sudo apt-get install -y curl unzip git &>>  var/log/install_app.log 2> var/log/install_app.log
sudo apt-get install -y apache2 libapache2-mod-wsgi libapache2-mod-perl2 2> var/log/install_app.log
sudo apt-get install -y postgresql 2> var/log/install_app.log
sudo apt-get install -y postgresql-contrib
if [ "$OS_VERSION" == "9" ]
then
    sudo apt-get install -y postgresql-server-dev-9.6 2> var/log/install_app.log
    sudo apt install -y postgis-2.3 postgis postgresql-9.6-postgis-2.3 2> var/log/install_app.log
fi
if [ "$OS_VERSION" == "8" ]
then
    sudo apt-get install -y postgresql-server-dev-9.4 2> var/log/install_app.log
    sudo apt install -y postgis-2.3 postgis 2> var/log/install_app.log
fi

if [ "$OS_VERSION" == "18.04" ]
then
    sudo apt-get install -y postgresql-server-dev-10 2> var/log/install_app.log
    sudo apt install -y postgis 2> var/log/install_app.log
fi

if [ "$OS_VERSION" == "16.04" ]
then
    sudo apt-get install -y libatlas3-base
    sudo apt-get install -y postgresql-server-dev-9.5  2> var/log/install_app.log
    sudo apt install -y postgis postgis postgresql-9.5-postgis-2.2 2> var/log/install_app.log
fi
sudo sed -e "s/datestyle =.*$/datestyle = 'ISO, DMY'/g" -i /etc/postgresql/*/main/postgresql.conf
sudo service postgresql restart

sudo apt-get install -y python3 2> var/log/install_app.log
sudo apt-get install -y python3-dev 2> var/log/install_app.log
sudo apt-get install -y python3-setuptools 2> var/log/install_app.log
sudo apt-get install -y python-pip 2> var/log/install_app.log
sudo apt-get install -y libpq-dev 2> var/log/install_app.log
sudo apt-get install -y libgdal-dev 2> var/log/install_app.log
sudo apt-get install -y python-gdal 2> var/log/install_app.log
sudo apt-get install -y python-virtualenv 2> var/log/install_app.log
sudo apt-get install -y build-essential 2> var/log/install_app.log
sudo pip install --upgrade pip virtualenv virtualenvwrapper 2> var/log/install_app.log

if [ "$OS_VERSION" == "9" ]
then
    sudo curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
    sudo apt-get install nodejs
    fi
if [ "$OS_VERSION" == "8" ]
then
    sudo apt-get install -y npm 2> var/log/install_app.log
fi

if [ "$OS_VERSION" == "16.04" ] || [ "$OS_VERSION" == "18.04" ]
then
    sudo apt-get install -y nodejs
    sudo apt-get install -y npm
fi

sudo apt-get install -y supervisor 2> var/log/install_app.log

# To make opencv (TaxHub) work on Debian 8
sudo apt-get install -y libsm6 libxrender1 libfontconfig1 2> var/log/install_app.log
sudo apt-get install -y python-qt4 2> var/log/install_app.log

# Creating PostgreSQL user
echo "Création de l'utilisateur PostgreSQL..."
sudo -n -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';"
#restart postgresql if we launch twice the script
sudo service postgresql restart

# Apache configuration
sudo sh -c 'echo "ServerName localhost" >> /etc/apache2/apache2.conf'
sudo a2enmod rewrite
sudo a2dismod mod_pyth
sudo a2enmod wsgi
sudo apache2ctl restart

# Installing GeoNature with current user
echo "Téléchargement et installation de GeoNature ..."
wget https://github.com/PnX-SI/GeoNature/archive/$geonature_release.zip
unzip $geonature_release.zip
rm $geonature_release.zip
mv GeoNature-$geonature_release /home/`whoami`/geonature/
sudo chown `whoami` /home/`whoami`/geonature/

cd /home/`whoami`/geonature

# Updating GeoNature settings
cp config/settings.ini.sample config/settings.ini
echo "Installation de la base de données et configuration de l'application GeoNature ..."
my_url="${my_url//\//\\/}"
sed -i "s/my_url=.*$/my_url=$my_url/g" config/settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_geonaturedb/g" config/settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
sed -i "s/srid_local=.*$/srid_local=$srid_local/g" config/settings.ini
sed -i "s/install_sig_layers=.*$/install_sig_layers=$install_sig_layers/g" config/settings.ini
sed -i "s/install_default_dem=.*$/install_default_dem=$install_default_dem/g" config/settings.ini
sed -i "s/vectorise_dem=.*$/vectorise_dem=$vectorise_dem/g" config/settings.ini
sed -i "s/add_sample_data=.*$/add_sample_data=$add_sample_data/g" config/settings.ini
sed -i "s/usershub_release=.*$/usershub_release=$usershub_release/g" config/settings.ini
sed -i "s/taxhub_release=.*$/taxhub_release=$taxhub_release/g" config/settings.ini
sed -i "s/enable_https=.*$/enable_https=$enable_https/g" config/settings.ini
sed -i "s/https_cert_path=.*$/https_cert_path=$https_cert_path/g" config/settings.ini
sed -i "s/https_key_path=.*$/https_key_path=$https_key_path/g" config/settings.ini


cd install/
# Installation of GeoNature database
./install_db.sh

# Installation and configuration of GeoNature application
./install_app.sh

cd ../

# Apache configuration of GeoNature
if [ -f  /etc/apache2/sites-available/geonature.conf ]; then
  sudo rm  /etc/apache2/sites-available/geonature.conf
fi
sudo touch /etc/apache2/sites-available/geonature.conf

sudo sh -c 'echo "# Configuration GeoNature" >> /etc/apache2/sites-available/geonature.conf'
conf="Alias /geonature /home/`whoami`/geonature/frontend/dist"
echo $conf | sudo tee -a /etc/apache2/sites-available/geonature.conf
sudo sh -c 'echo  $conf>> /etc/apache2/sites-available/geonature.conf'
conf="<Directory /home/`whoami`/geonature/frontend/dist>"
echo $conf | sudo tee -a /etc/apache2/sites-available/geonature.conf
sudo sh -c 'echo  "Require all granted">> /etc/apache2/sites-available/geonature.conf'
sudo sh -c 'echo  "</Directory>">> /etc/apache2/sites-available/geonature.conf'
# Conf Apache du backend de GeoNature
sudo sh -c 'echo "<Location /geonature/api>" >> /etc/apache2/sites-available/geonature.conf'
sudo sh -c 'echo "ProxyPass http://127.0.0.1:8000" >> /etc/apache2/sites-available/geonature.conf'
sudo sh -c 'echo "ProxyPassReverse  http://127.0.0.1:8000" >> /etc/apache2/sites-available/geonature.conf'
sudo sh -c 'echo "</Location>" >> /etc/apache2/sites-available/geonature.conf'
sudo sh -c '#FIN Configuration GeoNature 2>" >> /etc/apache2/sites-available/geonature.conf'

sudo a2ensite geonature

# Apache configuration of GeoNature maintenance page
if [ -f  /etc/apache2/sites-available/geonature_maintenance.conf ]; then
  sudo rm  /etc/apache2/sites-available/geonature_maintenance.conf
fi
sudo touch /etc/apache2/sites-available/geonature_maintenance.conf

conf="Alias /geonature /home/`whoami`/geonature/frontend/src/app/maintenance"
echo $conf | sudo tee -a /etc/apache2/sites-available/geonature_maintenance.conf
sudo sh -c 'echo  $conf>> /etc/apache2/sites-available/geonature_maintenance.conf'
conf="<Directory /home/`whoami`/geonature/frontend/src/app/maintenance>"
echo $conf | sudo tee -a /etc/apache2/sites-available/geonature_maintenance.conf
sudo sh -c 'echo  "Require all granted">> /etc/apache2/sites-available/geonature_maintenance.conf'
sudo sh -c 'echo  "</Directory>">> /etc/apache2/sites-available/geonature_maintenance.conf'

# Installing TaxHub with current user
echo "Téléchargement et installation de TaxHub ..."
wget https://github.com/PnX-SI/TaxHub/archive/$taxhub_release.zip
unzip $taxhub_release.zip
rm $taxhub_release.zip
mv TaxHub-$taxhub_release /home/`whoami`/taxhub/
sudo chown -R `whoami` /home/`whoami`/taxhub/
cd /home/`whoami`/taxhub

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

# Apache configuration of TaxHub
if [ -f  /etc/apache2/sites-available/taxhub.conf ]; then
  sudo rm  /etc/apache2/sites-available/taxhub.conf
fi
sudo touch /etc/apache2/sites-available/taxhub.conf
sudo sh -c 'echo "# Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "<Location /taxhub>" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "ProxyPass  http://127.0.0.1:5000 retry=0" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "ProxyPassReverse  http://127.0.0.1:5000" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "</Location>" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "#FIN Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'

# Creation of system files used by TaxHub
. create_sys_dir.sh
create_sys_dir

sudo a2ensite taxhub
sudo a2enmod proxy
sudo a2enmod proxy_http

# Installation of TaxHub
./install_app.sh

# Installation and configuration of UsersHub application (if activated)
if [ "$install_usershub_app" = true ]; then
    echo "Installation de l'application Usershub"

    wget https://github.com/PnEcrins/UsersHub/archive/$usershub_release.zip
    unzip $usershub_release.zip
    rm $usershub_release.zip
    mv UsersHub-$usershub_release /home/`whoami`/usershub/
    sudo chown -R `whoami` /home/`whoami`/usershub/
    cd /home/`whoami`/usershub
    echo "Installation de la base de données et configuration de l'application UsersHub ..."
    cp config/settings.ini.sample config/settings.ini
    sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
    sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
    sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
    sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
    sed -i 's#url_application=.*#url_application='$my_url'usershub#g' config/settings.ini

    # Installation of UsersHub application
    ./install_app.sh

    # Apache configuration of UsersHub
    if [ -f  /etc/apache2/sites-available/usershub.conf ]; then
        sudo rm /etc/apache2/sites-available/usershub.conf
    fi
    sudo touch /etc/apache2/sites-available/usershub.conf
    sudo sh -c 'echo "# Configuration Usershub" >> /etc/apache2/sites-available/usershub.conf'
    sudo sh -c 'echo "<Location /usershub>" >> /etc/apache2/sites-available/usershub.conf'
    sudo sh -c 'echo "ProxyPass  http://127.0.0.1:5001 retry=0" >> /etc/apache2/sites-available/usershub.conf'
    sudo sh -c 'echo "ProxyPassReverse  http://127.0.0.1:5001" >> /etc/apache2/sites-available/usershub.conf'
    sudo sh -c 'echo "</Location>" >> /etc/apache2/sites-available/usershub.conf'
    sudo sh -c 'echo "#FIN Configuration Usershub" >> /etc/apache2/sites-available/usershub.conf'
    sudo a2ensite usershub
fi

sudo apache2ctl restart


echo "L'installation est terminée!"
