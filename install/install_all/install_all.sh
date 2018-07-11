#!/bin/bash
. /etc/os-release
OS_NAME=$ID
OS_VERSION=$VERSION_ID


if  [ $LANG == "" ];
then
    echo -e "\e[91m\e[1mAucune langue par défaut n'a été définit sur serveur, lancez la commande 'sudo dpkg-reconfigure locales'
            pour la définir
 \e[0m" >&2
    exit 1
fi

# Check os and versions
if [ "$OS_NAME" != "debian" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour les distributions Debian\e[0m" >&2
    exit 1
fi

if [ "$OS_VERSION" != "8" ] && [ "$OS_VERSION" != "9" ]
then
    echo -e "\e[91m\e[1mLe script d'installation n'est prévu que pour Debian 8 ou 9\e[0m" >&2
    exit 1
fi

# Make sure this script is NOT run as root
if [ "$(id -u)" == "0" ]; then
   echo -e "\e[91m\e[1mThis script should NOT be run as root\e[0m" >&2
   echo -e "\e[91m\e[1mLancez ce script avec l'utilisateur courant : '$monuser'\e[0m" >&2
   exit 1
fi



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

sudo apt-get install -y nano 2> var/log/install_app.log 
nano install_all.ini
. install_all.ini

# Installation de l'environnement nécessaire à GeoNature et TaxHub
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
    sudo apt install -y postgis postgresql-9.6-postgis-2.3 2> var/log/install_app.log
else
    sudo apt-get install -y postgresql-server-dev-9.4 2> var/log/install_app.log 
    sudo apt install postgis 2> var/log/install_app.log
fi
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
else
    sudo apt-get install -y npm 2> var/log/install_app.log 
fi

sudo apt-get install -y supervisor 2> var/log/install_app.log 

# To make opencv (TaxHub) work on Debian 8
sudo apt-get install -y libsm6 libxrender1 libfontconfig1 2> var/log/install_app.log 
sudo apt-get install -y python-qt4 2> var/log/install_app.log 

# Création de l'utilisateur PostgreSQL
echo "Création de l'utilisateur PostgreSQL..."
sudo -n -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';"

# Configuration Apache
sudo sh -c 'echo "ServerName localhost" >> /etc/apache2/apache2.conf'
sudo a2enmod rewrite
sudo a2dismod mod_pyth
sudo a2enmod wsgi
sudo apache2ctl restart

# Installation de GeoNature avec l'utilisateur courant
echo "Téléchargement et installation de GeoNature ..."
cd /tmp
wget https://github.com/PnX-SI/GeoNature/archive/$geonature_release.zip
unzip $geonature_release.zip
rm $geonature_release.zip
mv GeoNature-$geonature_release /home/$monuser/geonature/
sudo chown $monuser /home/$monuser/geonature/

cd /home/$monuser/geonature

# Configuration des settings de GeoNature
cp config/settings.ini.sample config/settings.ini
echo "Installation de la base de données et configuration de l'application GeoNature ..."
my_url="${my_url//\//\\/}"
sed -i "s/monuser=.*$/monuser=$monuser/g" config/settings.ini
sed -i "s/my_url=.*$/my_url=$my_url/g" config/settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_geonaturedb/g" config/settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
sed -i "s/srid_local=.*$/srid_local=$srid_local/g" config/settings.ini
sed -i "s/install_default_dem=.*$/install_default_dem=$install_default_dem/g" config/settings.ini
sed -i "s/add_sample_data=.*$/add_sample_data=$add_sample_data/g" config/settings.ini
sed -i "s/usershub_release=.*$/usershub_release=$usershub_release/g" config/settings.ini
sed -i "s/taxhub_release=.*$/taxhub_release=$taxhub_release/g" config/settings.ini
sed -i "s/enable_https=.*$/enable_https=$enable_https/g" config/settings.ini
sed -i "s/https_cert_path=.*$/https_cert_path=$https_cert_path/g" config/settings.ini
sed -i "s/https_key_path=.*$/https_key_path=$https_key_path/g" config/settings.ini


cd install/
# Installation de la base de données GeoNature en root
./install_db.sh

# Installation et configuration de l'application GeoNature
./install_app.sh

cd ../

# Configuration Apache de Geonature
sudo touch /etc/apache2/sites-available/geonature.conf

sudo sh -c 'echo "# Configuration GeoNature" >> /etc/apache2/sites-available/geonature.conf'
conf="Alias /geonature /home/"$monuser"/geonature/frontend/dist"
echo $conf | sudo tee -a /etc/apache2/sites-available/geonature.conf 
sudo sh -c 'echo  $conf>> /etc/apache2/sites-available/geonature.conf'
conf="<Directory /home/$monuser/geonature/frontend/dist>"
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

# Configuration Apache de la page de maintenance de GeoNature
sudo touch /etc/apache2/sites-available/geonature_maintenance.conf

conf="Alias /geonature /home/"$monuser"/geonature/frontend/src/app/maintenance"
echo $conf | sudo tee -a /etc/apache2/sites-available/geonature_maintenance.conf 
sudo sh -c 'echo  $conf>> /etc/apache2/sites-available/geonature_maintenance.conf'
conf="<Directory /home/$monuser/geonature/frontend/src/app/maintenance>"
echo $conf | sudo tee -a /etc/apache2/sites-available/geonature_maintenance.conf 
sudo sh -c 'echo  "Require all granted">> /etc/apache2/sites-available/geonature_maintenance.conf'
sudo sh -c 'echo  "</Directory>">> /etc/apache2/sites-available/geonature_maintenance.conf'

# Installation de TaxHub avec l'utilisateur courant
echo "Téléchargement et installation de TaxHub ..."
cd /tmp
wget https://github.com/PnX-SI/TaxHub/archive/$taxhub_release.zip
unzip $taxhub_release.zip
rm $taxhub_release.zip
mv TaxHub-$taxhub_release /home/$monuser/taxhub/
sudo chown -R $monuser /home/$monuser/taxhub/
cd /home/$monuser/taxhub

# Configuration des settings de TaxHub
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

# Configuration Apache de TaxHub
sudo touch /etc/apache2/sites-available/taxhub.conf
sudo sh -c 'echo "# Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "RewriteEngine  on" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "RewriteRule    \"taxhub$\"  \"taxhub/\"  [R]" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "<Location /taxhub>" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "ProxyPass  http://127.0.0.1:5000 retry=0" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "ProxyPassReverse  http://127.0.0.1:5000" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "</Location>" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "#FIN Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'

# Création des fichiers systèmes liés à Taxhub
. create_sys_dir.sh
create_sys_dir

sudo a2ensite taxhub
sudo a2enmod proxy
sudo a2enmod proxy_http

# Script d'installation de TaxHub
./install_app.sh

# Installation et configuration de l'application UsersHub (si activée)
if [ "$install_usershub_app" = true ]; then
    echo "Installation de l'application Usershub"
    os_version=$(cat /etc/os-release |grep VERSION_ID)
    # Sur Debian 9 : php7. Sur Debian 8 : php5
    if [ "$OS_VERSION" == "9" ] 
    then
        sudo apt-get install -y php7.0 libapache2-mod-php7.0 libapache2-mod-php7.0 php7.0-pgsql php7.0-gd 2> var/log/install_app.log 
    else
        sudo apt-get install -y php5 libapache2-mod-php5 libapache2-mod-php5 php5-pgsql php5-gd 2> var/log/install_app.log 
    fi
    cd /tmp
    wget https://github.com/PnEcrins/UsersHub/archive/$usershub_release.zip
    unzip $usershub_release.zip
    rm $usershub_release.zip
    mv UsersHub-$usershub_release /home/$monuser/usershub/
    sudo chown -R $monuser /home/$monuser/usershub/
    cd /home/$monuser/usershub
    echo "Installation de la base de données et configuration de l'application UsersHub ..."
    cp config/settings.ini.sample config/settings.ini
    sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
    sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
    sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
    sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini

    # Script d'installation de UsersHub
    ./install_app.sh
    
    # Conf Apache de UsersHub
    sudo touch /etc/apache2/sites-available/usershub.conf
    sudo sh -c 'echo  "#Configuration usershub">> /etc/apache2/sites-available/usershub.conf'
    conf="Alias /usershub /home/$monuser/usershub/web"
    echo $conf | sudo tee -a /etc/apache2/sites-available/usershub.conf 
    conf="<Directory /home/$monuser/usershub/web>"
    echo $conf | sudo tee -a /etc/apache2/sites-available/usershub.conf
    sudo sh -c 'echo  "Require all granted">> /etc/apache2/sites-available/usershub.conf'
    sudo sh -c 'echo  "</Directory>">> /etc/apache2/sites-available/usershub.conf'
    sudo a2ensite usershub
fi

sudo apache2ctl restart
