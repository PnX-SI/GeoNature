#/bin/bash

#Make sure only root can run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi

. install_all.ini

cd /tmp

wget http://geonature.fr/documents/install_dlb/update_db.sql
wget http://geonature.fr/documents/install_dlb/configuration_dlb.zip
wget http://geonature.fr/documents/install_dlb/custom_frontend.zip
unzip custom_frontend.zip
unzip configuration_dlb.zip


echo "Ecriture de la liste de taxons" >> /var/log/geonature/install_db.log
export PGPASSWORD=$user_pg_pass;psql -h $pg_host -U $user_pg -d $geonaturedb_name -f /tmp/update_db.sql  &>> /var/log/geonature/install_db.log

rm -r /home/`whoami`/geonature/frontend/src/custom
cp -r custom /home/`whoami`/geonature/frontend/src/
cp configuration/map.config.ts /home/`whoami`/geonature/frontend/src/conf/map.config.ts


url_app=https://depot-legal-biodiversite.naturefrance.fr/saisie
api_end_point=https://depot-legal-biodiversite.naturefrance.fr/saisie/api
api_taxhub=https://depot-legal-biodiversite.naturefrance.fr/taxhub/api

url_app="${url_app//\//\\/}"
api_end_point="${api_end_point//\//\\/}"
api_taxhub="${api_taxhub//\//\\/}"

sudo sed -i "s/URL_APPLICATION = .*$/URL_APPLICATION = '${url_app}' /g" /etc/geonature/geonature_config.toml
sudo sed -i "s/API_ENDPOINT = .*$/API_ENDPOINT = '${api_end_point}'/g" /etc/geonature/geonature_config.toml
sudo sed -i "s/API_TAXHUB = .*$/API_TAXHUB = '${api_taxhub}'/g" /etc/geonature/geonature_config.toml

cat configuration/occtax.config.toml | sudo tee -a /etc/geonature/mods-enabled/occtax/conf_gn_module.toml
cat configuration/geonature.config.toml | sudo tee -a /etc/geonature/geonature_config.toml
 

cd /home/`whoami`/geonature/backend
source venv/bin/activate
geonature update_configuration --build=false
geonature update_module_configuration occtax
deactivate

rm -r /tmp/custom
rm -r /tmp/configuration
rm /tmp/custom_frontend.zip
rm /tmp/configuration_dlb.zip
rm /tmp/update_db.sql
