#!/bin/bash
#TODO : 
    #faire une install complète avec des données du PNE pour l'atlas
    #ajouter la connexion pour la synchro du schema utilisateurs de GeoNature
    #demander à l'utilisateur de mettre ses shp dans les data/ref puis de relancer le install_db.sh
    #régler le soucis de la question posée ainsi que le doublement du prompt pour le user sudo
    #préparer une installation et une version de geonature compatible avec d'autres projections

#configuration initiale de l'installation serveur
. install_all.ini

# Make sure this script is NOT run as root
if [ "$(id -u)" == "0" ]; then
   echo -e "\e[91m\e[1mThis script should NOT be run as root\e[0m" >&2
   echo -e "\e[91m\e[1mLancez ce script avec l'utilisateur courant : '$monuser'\e[0m" >&2
   exit 1
fi

#installation de l'environnement nécessaire à UsersHub, GeoNature, TaxHub et GeoNature-atlas
echo "Installation de l'environnement logiciel..."
sudo apt-get update
sudo apt-get -y install ntpdate
sudo ntpdate-debian
sudo apt-get install -y curl unzip git
sudo apt-get install -y apache2 php5 libapache2-mod-php5 libapache2-mod-wsgi libapache2-mod-perl2
sudo apt-get install -y php5-gd php5-pgsql
sudo apt-get install -y cgi-mapserver gdal-bin libgeos-dev
sudo apt-get install -y postgresql postgis postgresql-server-dev-9.4
sudo apt-get install -y python-dev python-pip libpq-dev python-setuptools python-gdal python-virtualenv build-essential
# sudo apt-get install -y python3 python3-dev 

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
echo "Configuration de Apache..."
echo "ajout d'un alias 'databases' et 'geonatdbhost' dans /etc/hosts..."
sudo sh -c 'echo "127.0.1.1       databases" >> /etc/hosts'
sudo sh -c 'echo "127.0.1.1       geonatdbhost" >> /etc/hosts'
#suppression de la notice au redémarrage d'apache
sudo sh -c 'echo "ServerName localhost" >> /etc/apache2/apache2.conf'
echo "Activation des modules apache rewrite, wsgi et cgi..."
sudo a2enmod rewrite
sudo a2enmod cgi
sudo a2enmod wsgi
sudo apache2ctl restart

#Installation de UsersHub avec l'utilisateur courant
echo "téléchargement et installation de UsersHub ..."
cd /tmp
wget https://github.com/PnEcrins/UsersHub/archive/$usershub_release.zip
unzip $usershub_release.zip
rm $usershub_release.zip
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
#configuration de la connexion à la base de données GeoNature
rm config/dbconnexions.json
touch config/dbconnexions.json
echo "{" >> config/dbconnexions.json
echo "    \"databases\":" >> config/dbconnexions.json
echo "    [" >> config/dbconnexions.json
echo "        {" >> config/dbconnexions.json  
echo "            \"dbfunname\":\"Utilisateurs\"" >> config/dbconnexions.json 
echo "            ,\"host\":\"$pg_host\"" >> config/dbconnexions.json 
echo "            ,\"dbname\":\"$usershubdb_name\"" >> config/dbconnexions.json 
echo "            ,\"user\":\"$user_pg\"" >> config/dbconnexions.json 
echo "            ,\"pass\":\"$user_pg_pass\"" >> config/dbconnexions.json 
echo "            ,\"port\":\"$pg_port\"" >> config/dbconnexions.json 
echo "        }" >> config/dbconnexions.json
echo "        ,{" >> config/dbconnexions.json
echo "            \"dbfunname\":\"GeoNature\"" >> config/dbconnexions.json 
echo "            ,\"host\":\"$pg_host\"" >> config/dbconnexions.json 
echo "            ,\"dbname\":\"$geonaturedb_name\"" >> config/dbconnexions.json 
echo "            ,\"user\":\"$user_pg\"" >> config/dbconnexions.json 
echo "            ,\"pass\":\"$user_pg_pass\"" >> config/dbconnexions.json 
echo "            ,\"port\":\"$pg_port\"" >> config/dbconnexions.json 
echo "        }" >> config/dbconnexions.json  
echo "    ]" >> config/dbconnexions.json
echo "}" >> config/dbconnexions.json

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
#sudo apache2ctl restart

#installation de l'atlas avec l'utilisateur courant
echo "téléchargement et installation de GeoNature-atlas ..."
cd /tmp
wget https://github.com/PnEcrins/GeoNature-atlas/archive/$atlas_release.zip
unzip $atlas_release.zip
rm $atlas_release.zip
mv GeoNature-atlas-$atlas_release /home/$monuser/atlas/
cd /home/$monuser/atlas

echo "Création de l'environnement virtuel de GeoNature-atlas ..."
virtualenv ./venv
. ./venv/bin/activate

echo "Installation des dépendances pour l'application GeoNature-atlas ..."
pip install -r requirements.txt

echo "configuration de l'application GeoNature-atlas ..."
cp ./main/configuration/config.py.sample ./main/configuration/config.py
cp ./main/configuration/settings.ini.sample ./main/configuration/settings.ini
cp ./static/custom/templates/footer.html.sample ./static/custom/templates/footer.html
cp ./static/custom/templates/introduction.html.sample ./static/custom/templates/introduction.html
cp ./static/custom/templates/presentation.html.sample ./static/custom/templates/presentation.html
cp ./static/custom/custom.css.sample ./static/custom/custom.css
cp ./static/custom/glossaire.json.sample ./static/custom/glossaire.json

#configuration des settings de GeoNature-atlas et création de la base de données
echo " Configuration et installation de la base de données ..."
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_atlasdb/g" main/configuration/settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_atlasdb/g" main/configuration/settings.ini
sed -i "s/db_name=.*$/db_name=$atlasdb_name/g" main/configuration/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_atlas/g"  main/configuration/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_atlas_pass/g"  main/configuration/settings.ini
sed -i "s/admin_pg=.*$/admin_pg=$admin_pg/g"  main/configuration/settings.ini
sed -i "s/admin_pg_pass=.*$/admin_pg_pass=$admin_pg_pass/g"  main/configuration/settings.ini
sed -i "s/db_source_host=.*$/db_source_host=$pg_host/g"  main/configuration/settings.ini
sed -i "s/db_source_port=.*$/db_source_port=$pg_port/g"  main/configuration/settings.ini
sed -i "s/admin_source_user=.*$/admin_source_user=$admin_pg/g"  main/configuration/settings.ini
sed -i "s/admin_source_pass=.*$/admin_source_pass=$admin_pg_pass/g"  main/configuration/settings.ini
sed -i "s/atlas_source_user=.*$/atlas_source_user=$user_pg/g"  main/configuration/settings.ini #TODO utiliser la variable $user_atlaset faire des GRANT select et usage pour geonatatlas sur la bd geonature
sed -i "s/atlas_source_pass=.*$/atlas_source_pass=$user_pg_pass/g"  main/configuration/settings.ini #TODO utiliser la variable $user_atlas_pass
sed -i -e "s/limit_shp=.*$/limit_shp=\/home\/$monuser\/atlas\/data\/ref\/$limit_shp_name/g" main/configuration/settings.ini
sed -i -e "s/communes_shp=.*$/communes_shp=\/home\/$monuser\/atlas\/data\/ref\/$communes_shp_name/g" main/configuration/settings.ini
sed -i "s/colonne_insee=.*$/colonne_insee=$colonne_insee/g"  main/configuration/settings.ini
sed -i "s/colonne_nom_commune=.*$/colonne_nom_commune=$colonne_nom_commune/g"  main/configuration/settings.ini
sed -i "s/metropole=.*$/metropole=$metropole/g"  main/configuration/settings.ini
sed -i "s/taillemaille=.*$/taillemaille=$taillemaille/g"  main/configuration/settings.ini
sed -i -e "s/chemin_custom_maille=.*$/chemin_custom_maille=\/home\/$monuser\/atlas\/data\/ref\/$custom_maille_name/g" main/configuration/settings.ini
#mettre à jour config.py
sed -i "s/database_connection =.*$/database_connection = \"postgresql:\/\/$user_atlas:$user_atlas_pass@$pg_host:$pg_port\/$atlasdb_name\"/g" main/configuration/config.py
sed -i "s/STRUCTURE = \".*$/STRUCTURE = \"$structure\"/g" main/configuration/config.py
sed -i "s/NOM_APPLICATION = \".*$/NOM_APPLICATION = \"$nom_application\"/g" main/configuration/config.py
sed -i "s/URL_APPLICATION =.*$/URL_APPLICATION = \"$url_atlas\"/g" main/configuration/config.py
sed -i "s/ID_GOOGLE_ANALYTICS =.*$/ID_GOOGLE_ANALYTICS = \"$id_google_analytics\"/g" main/configuration/config.py
sed -i "s/IGNAPIKEY =.*/IGNAPIKEY = \'$macleign\';/g" main/configuration/config.py
#sed -i "s/+IGNAPIKEY+/+$macleign+/g" main/configuration/config.py
sed -i "s/'LAT_LONG':.*$/\'LAT_LONG\': [$y, $x],/g" main/configuration/config.py

sudo ./install_db.sh

#configuration apache de GeoNature-atlas
sudo rm /etc/apache2/sites-available/atlas.conf
sudo touch /etc/apache2/sites-available/atlas.conf
sudo sh -c 'echo "# Configuration de GeoNature-atlas" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "WSGIScriptAlias /atlas \"/home/'$monuser'/atlas/atlas.wsgi\"" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "<Directory \"/home/'$monuser'/atlas/\">" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "WSGIApplicationGroup %{GLOBAL}" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "WSGIScriptReloading On" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "Order deny,allow" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "Allow from all" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "Require all granted" >> /etc/apache2/sites-available/atlas.conf'
sudo sh -c 'echo "</Directory>" >> /etc/apache2/sites-available/atlas.conf'
sudo a2ensite atlas
sudo apachectl restart
#nettoyage
sudo rm /tmp/*.sql