#!/bin/bash
#sudo apt-get update
#sudo apt-get install -y python-virtualenv libapache2-mod-wsgi python-dev build-essential
#sudo apt-get install libpq-dev postgresql-server-dev-9.4

##########CONFIG##############
#valeur à mettre à jour selon votre configuration serveur
#api access config
# monuser=test
# mondomaine=87.98.168.87
# webapiurl=synchronomade
# token=mon\!token#complexe
#db config
# geonaturedb_name=geonaturedb
# user_pg=geonatuser
# user_pg_pass=monpassachanger
# pg_host=localhost
# pg_port=5432
##############################

#configuration initiale de l'installation serveur
. install_all.ini

cd /tmp
wget https://github.com/PnEcrins/GeoNature-mobile-webapi/archive/$webapi_release.zip
unzip $webapi_release.zip
mv GeoNature-mobile-webapi-$webapi_release/webapi /home/$monuser/synchronomade/
rm -R GeoNature-mobile-webapi-$webapi_release/
rm $webapi_release.zip
cd /home/$monuser/synchronomade

cp faune/settings_local.py.sample  faune/settings_local.py
sed -i "s/dbname/$geonaturedb_name/g" faune/settings_local.py
sed -i "s/dbuser/$user_pg/g" faune/settings_local.py
sed -i "s/userpassword/$user_pg_pass/g" faune/settings_local.py
sed -i "s/localhost/$pg_host/g" faune/settings_local.py
sed -i "s/5432/$pg_port/g" faune/settings_local.py
sed -i "s/666/$token/g" faune/settings_local.py
sed -i "s/666/$token/g" faune/settings.py
sed -i "s/MOBILE_SOFT_PATH = \"\/tmp\//MOBILE_SOFT_PATH = \"\/home\/$monuser\/synchronomade\/apk\//g" faune/settings_local.py
sed -i "s/MOBILE_MBTILES_PATH = \"\/tmp\//MOBILE_MBTILES_PATH = \"\/home\/$monuser\/synchronomade\/datas\//g" faune/settings_local.py
sed -i "s/\/usr\/local\/bin\/talend\/ecrins2rezo\/ecrins2rezo\/ecrins2rezo_run.sh --context_param mes_zp=//g" faune/settings_local.py

make install

mkdir datas
mkdir apk
chmod 755 datas/
chmod 755 apk/

cd apk 
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/apk/fauna-release-1.1.0.apk
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/apk/flora-release-1.1.0.apk
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/apk/invertebrate-release-1.1.0.apk
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/apk/mortality-release-1.1.0.apk
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/apk/search-release-1.1.0.apk
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/apk/version.json

cd ../datas
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile-sync/master/docs/install/1.0.0/settings.json
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/internal%20memory/settings_fauna.json
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/internal%20memory/settings_flora.json
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/internal%20memory/settings_invertebrate.json
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/internal%20memory/settings_mortality.json
wget https://raw.githubusercontent.com/PnEcrins/GeoNature-mobile/master/docs/install/v1.1.0/internal%20memory/settings_search.json

sed -i "s/mondomaine.fr/$mondomaine/g" settings.json
sed -i "s/urlsynchro/synchronomade/g" settings.json
sed -i "s/mon\!token#complexe/$token/g" settings.json

sed -i "s/mondomaine.fr/$mondomaine/g" settings_fauna.json
sed -i "s/urlsynchro/synchronomade/g" settings_fauna.json
sed -i "s/mon\!token#complexe/$token/g" settings_fauna.json

sed -i "s/mondomaine.fr/$mondomaine/g" settings_flora.json
sed -i "s/urlsynchro/synchronomade/g" settings_flora.json
sed -i "s/mon\!token#complexe/$token/g" settings_flora.json

sed -i "s/mondomaine.fr/$mondomaine/g" settings_invertebrate.json
sed -i "s/urlsynchro/synchronomade/g" settings_invertebrate.json
sed -i "s/mon\!token#complexe/$token/g" settings_invertebrate.json

sed -i "s/mondomaine.fr/$mondomaine/g" settings_mortality.json
sed -i "s/urlsynchro/synchronomade/g" settings_mortality.json
sed -i "s/mon\!token#complexe/$token/g" settings_mortality.json

sed -i "s/mondomaine.fr/$mondomaine/g" settings_search.json
sed -i "s/urlsynchro/synchronomade/g" settings_search.json
sed -i "s/mon\!token#complexe/$token/g" settings_search.json

#configuration apache de GeoNature-mobile-webapi
sudo rm /etc/apache2/sites-available/synchronomade.conf
sudo touch /etc/apache2/sites-available/synchronomade.conf
sudo sh -c 'echo "# Configuration de GeoNature-mobile-webapi" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "WSGIScriptAlias /synchronomade \"/home/'$monuser'/synchronomade/faune/wsgi.py\"" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "WSGIPythonPath /synchronomade/faune/lib/python2.7/site-packages\"" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "<Directory \"/home/'$monuser'/synchronomade/faune/\">" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "<Files wsgi.py>" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "Order deny,allow" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "Allow from all" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "Require all granted" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "</Files>" >> /etc/apache2/sites-available/synchronomade.conf'
sudo sh -c 'echo "</Directory>" >> /etc/apache2/sites-available/synchronomade.conf'
sudo a2ensite synchronomade
sudo apache2ctl restart