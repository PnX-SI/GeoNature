#!/bin/bash

#configuration initiale de l'installation serveur
. install_env.ini

# Make sure this script is NOT run as root
if [ "$(id -u)" == "0" ]; then
   echo -e "\e[91m\e[1mThis script should NOT be run as root\e[0m" >&2
   echo -e "\e[91m\e[1mLancez ce script avec l'utilisateur courant : '$monuser'\e[0m" >&2
   exit 1
fi

#installation de l'environnement nécessaire à UsersHub, GeoNature et TaxHub
echo "Installation de l'environnement logiciel..."
#TODO ntpdate
sudo apt-get update
sudo apt-get install -y curl unzip git
sudo apt-get install -y apache2 php5 libapache2-mod-php5 libapache2-mod-wsgi libapache2-mod-perl2 php5-gd php5-pgsql 
sudo apt-get install -y php5-gd php5-pgsql
sudo apt-get install -y postgresql postgis 
sudo apt-get install -y cgi-mapserver gdal-bin libgeos-dev
sudo apt-get install -y python3 python3-dev python-dev python-pip libpq-dev python-setuptools python-gdal python-virtualenv

sudo pip install virtualenv

sudo sh -c 'echo "" >> /etc/apt/sources.list'
sudo sh -c 'echo "#Backports" >> /etc/apt/sources.list'
sudo sh -c 'echo "deb http://http.debian.net/debian wheezy-backports main" >> /etc/apt/sources.list'
sudo apt-get update
sudo apt-get -y -t wheezy-backports install nodejs
sudo update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100
#sudo curl https://www.npmjs.com/install.sh | sudo sh
sudo sh -c 'curl https://www.npmjs.com/install.sh | sh'
sudo npm install -g bower

echo "Configuration de postgresql..."
sudo sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" -i /etc/postgresql/*/main/postgresql.conf
sudo sh -c 'echo "host    all             all             0.0.0.0/0            md5" >> /etc/postgresql/9.4/main/pg_hba.conf'
sudo /etc/init.d/postgresql restart

echo "Création des utilisateurs postgresql..."
sudo -n -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';"
sudo -n -u postgres -s psql -c "CREATE ROLE $user_atlas WITH LOGIN PASSWORD '$user_atlas_pass';"
sudo -n -u postgres -s psql -c "CREATE ROLE $admin_pg WITH SUPERUSER LOGIN PASSWORD '$admin_pg_pass';" 

#Ajouter un alias du serveur de base de données dans le fichier /etc/hosts
echo "ajout d'un alias 'databases' et 'geonatdbhost' dans /etc/hosts..."
sudo sh -c 'echo "127.0.1.1       databases" >> /etc/hosts'
sudo sh -c 'echo "127.0.1.1       geonatdbhost" >> /etc/hosts'
echo "Activation des modules apache rewrite, wsgi et cgi..."
sudo a2enmod rewrite
sudo a2enmod cgi
sudo a2enmod wsgi
sudo apache2ctl restart

#Iynstallation de UsersHub avec l'utilisateur courant
echo "téléchargement et installation de UsersHub ..."
cd /tmp
wget https://github.com/PnEcrins/UsersHub/archive/v$usershub_release.zip
unzip v$usershub_release.zip
rm v$usershub_release.zip
mv UsersHub-$usershub_release /home/$monuser/usershub/
cd /home/$monuser/usershub

#configuration des settings de UsersHub
echo "Installation de la base de données et configuration de l'application UsersHub ..."
cp config/settings.ini.sample config/settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_usershubdb/g" config/settings.ini
sed -i "s/db_name=.*$/db_name=$usershubdb_name/g" config/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
#installation de la base de données UsersHub en root
sudo ./install_db.sh
#installation et configuration de l'application UsersHub
./install_app.sh

#installation de GeoNature avec l'utilisateur courant
echo "téléchargement et installation de GeoNature ..."
cd /tmp
wget https://github.com/PnEcrins/GeoNature/archive/$geonature_release.zip
unzip $geonature_release.zip
rm $geonature_release.zip
mv GeoNature-$geonature_release /home/$monuser/geonature/
cd /home/$monuser/geonature

#configuration des settings de GeoNature
echo "Installation de la base de données et configuration de l'application GeoNature ..."
cp config/settings.ini.sample config/settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_geonaturedb/g" config/settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
sed -i "s/admin_pg=.*$/admin_pg=$admin_pg/g" config/settings.ini
sed -i "s/admin_pg_pass=.*$/admin_pg_pass=$admin_pg_pass/g" config/settings.ini
# sed -i "s/users_schema=.*$/user_schema=$geonature_users_schema_location/g" config/settings.ini
# sed -i "s/usershub_host=.*$/usershub_host=$pg_host/g" config/settings.ini
# sed -i "s/usershub_port=.*$/usershub_port=$pg_port/g" config/settings.ini
# sed -i "s/usershub_db=.*$/usershub_db=$usershubdb_name/g" config/settings.ini
# sed -i "s/usershub_user=.*$/usershub_user=$user_pg/g" config/settings.ini
# sed -i "s/usershub_pass=.*$/usershub_pass=$user_pg_pass/g" config/settings.ini
sed -i -e "s/\/var\/www/$apache_document_root/g" install_app.sh
#installation de la base de données GeoNature en root
sudo ./install_db.sh
#installation et configuration de l'application GeoNature
./install_app.sh
#configuration apache de l'application GeoNature
cd /home/$monuser/geonature
sed -i -e "s/\/home\/synthese\/geonature/\/home\/$monuser\/geonature/g" apache/sf.conf
sed -i -e "s/\/home\/synthese\/geonature/\/home\/$monuser\/geonature/g" apache/wms.conf
sed -i -e "s/\/var\/www\/geonature/\/var\/www\/html\/geonature/g" apache/synthese.conf
sed -i -e "s/mon-domaine.fr/$mondomaine/g" web/js/config.js
sed -i -e "s/ma_cle_api_ign/$macleign/g" web/js/configmap.js
sudo sh -c 'echo "IncludeOptional /home/'$monuser'/geonature/apache/*.conf" >> /etc/apache2/apache2.conf'
#sudo apache2ctl restart

#installation de Taxhub avec l'utilisateur courant
echo "téléchargement et installation de Taxhub ..."
cd /tmp
wget https://github.com/PnX-SI/TaxHub/archive/$taxhub_release.zip
unzip $taxhub_release.zip
rm $taxhub_release.zip
mv TaxHub-$taxhub_release /home/$monuser/taxhub/
cd /home/$monuser/taxhub

#configuration des settings de TaxHub
echo "Configuration de l'application TaxHub ..."
cp settings.ini.sample settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_taxhubdb/g" settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" settings.ini
sed -i "s/db_port=.*$/db_port=$pg_port/g" settings.ini
sed -i "s/db_name=.*$/db_name=$taxhubdb_name/g" settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" settings.ini
sed -i "s/admin_pg=.*$/admin_pg=$admin_pg/g" settings.ini
sed -i "s/admin_pg_pass=.*$/admin_pg_pass=$admin_pg_pass/g" settings.ini
sed -i "s/user_schema=.*$/user_schema=$taxhub_users_schema_location/g" settings.ini
sed -i "s/usershub_host=.*$/usershub_host=$pg_host/g" settings.ini
sed -i "s/usershub_port=.*$/usershub_port=$pg_port/g" settings.ini
sed -i "s/usershub_db=.*$/usershub_db=$usershubdb_name/g" settings.ini
sed -i "s/usershub_user=.*$/usershub_user=$user_pg/g" settings.ini
sed -i "s/usershub_pass=.*$/usershub_pass=$user_pg_pass/g" settings.ini

#configuration apache de TaxHub
sudo touch /etc/apache2/sites-available/taxhub.conf
sudo sh -c 'echo "#Backports" >> /etc/apt/sources.list'
sudo sh -c 'echo "# Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "WSGIScriptAlias /taxhub \"/home/'$monuser'/taxhub/app.wsgi\"" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "<Directory \"/home/'$monuser'/taxhub/\">" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "Order allow,deny" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "Allow from all" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "Require all granted" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "</Directory>" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "#FIN Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'
sudo a2ensite taxhub
#installation et configuration de l'application TaxHub
./install_app.sh
sudo apache2ctl restart