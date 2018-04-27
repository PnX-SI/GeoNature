#/bin/bash

Make sure only root can run our script
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

echo "Ecriture de la liste de taxons"

echo "Ecriture de la liste de taxons" >> /var/log/geonature/install_db.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f update_db.sql  &>> /var/log/geonature/install_db.log


cp -r custom /home/$monuser/geonature/frontend/src/custom
cp configuration/map.config.ts /home/$monuser/geonature/frontend/src/conf/map.config.ts


cat configuration/occtax.config.toml | sudo tee -a /etc/geonature/mods-enabled/occtax/conf_gn_module.toml
cat configuration/geonature.config.toml | sudo tee -a /etc/geonature/geonature_config.toml
 

cd /home/$monuser/geonature/backend
source venv/bin/activate
geonature update_configuration --build=false
geonature update_module_configuration occtax
deactivate

rm -r custom
rm -r configuration
rm custom.zip
rm update_db.sql