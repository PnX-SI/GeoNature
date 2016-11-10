#!/bin/bash
#sudo apt-get update
#sudo apt-get install -y python-virtualenv libapache2-mod-wsgi python-dev build-essential
#sudo apt-get install libpq-dev postgresql-server-dev-9.4

##########CONFIG##############
#valeur à mettre à jour selon votre configuration serveur
#api access config
user_home_path=synthese
domaine=92.222.107.92
webapiurl=synchronomade
token=mon\!token#complexe
#db config
dbname=geonaturedb
dbuser=geonatuser
userpassword=monpassachanger
dbhost=localhost
dbport=5432
##############################

cd /tmp
wget https://github.com/PnEcrins/GeoNature-mobile-webapi/archive/master.zip
unzip master.zip
mv GeoNature-mobile-webapi-master/webapi /home/$user_home_path/$webapiurl/
rm -R GeoNature-mobile-webapi-master/
rm master.zip
cd /home/$user_home_path/$webapiurl

cp faune/settings_local.py.sample  faune/settings_local.py
sed -i "s/dbname/$dbname/g" faune/settings_local.py
sed -i "s/dbuser/$dbuser/g" faune/settings_local.py
sed -i "s/userpassword/$userpassword/g" faune/settings_local.py
sed -i "s/localhost/$dbhost/g" faune/settings_local.py
sed -i "s/5432/$dbport/g" faune/settings_local.py
sed -i "s/666/$token/g" faune/settings_local.py
sed -i "s/666/$token/g" faune/settings.py
sed -i "s/MOBILE_SOFT_PATH = \"\/tmp\//MOBILE_SOFT_PATH = \"\/home\/$user_home_path\/$webapiurl\/apk\//g" faune/settings_local.py
sed -i "s/MOBILE_MBTILES_PATH = \"\/tmp\//MOBILE_MBTILES_PATH = \"\/home\/$user_home_path\/$webapiurl\/datas\//g" faune/settings_local.py
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

sed -i "s/mondomaine.fr/$domaine/g" settings.json
sed -i "s/urlsynchro/$webapiurl/g" settings.json
sed -i "s/mon\!token#complexe/$token/g" settings.json

sed -i "s/mondomaine.fr/$domaine/g" settings_fauna.json
sed -i "s/urlsynchro/$webapiurl/g" settings_fauna.json
sed -i "s/mon\!token#complexe/$token/g" settings_fauna.json

sed -i "s/mondomaine.fr/$domaine/g" settings_flora.json
sed -i "s/urlsynchro/$webapiurl/g" settings_flora.json
sed -i "s/mon\!token#complexe/$token/g" settings_flora.json

sed -i "s/mondomaine.fr/$domaine/g" settings_invertebrate.json
sed -i "s/urlsynchro/$webapiurl/g" settings_invertebrate.json
sed -i "s/mon\!token#complexe/$token/g" settings_invertebrate.json

sed -i "s/mondomaine.fr/$domaine/g" settings_mortality.json
sed -i "s/urlsynchro/$webapiurl/g" settings_mortality.json
sed -i "s/mon\!token#complexe/$token/g" settings_mortality.json

sed -i "s/mondomaine.fr/$domaine/g" settings_search.json
sed -i "s/urlsynchro/$webapiurl/g" settings_search.json
sed -i "s/mon\!token#complexe/$token/g" settings_search.json


#TODO : conf apache
sudo apache2ctl restart