#/bin/bash

Make sure only root can run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi

. install_all.ini

cd /tmp

wget http://geonature.fr/install_dlb/update_db.sql
wget http://geonature.fr/install_dlb/map.config.ts
wget http://geonature.fr/install_dlb/custom_frontend.zip
unzip custom_frontend.zip


export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f update_db.sql  &>> /var/log/geonature/install_db.log


cp -r custom /home/$monuser/geonature/src/custom
cp -r map.config.ts /home/$monuser/geonature/src/conf/map.config.ts

observer_txt="observers_txt = true \n"
available_format="available_export_format = ['csv', 'geojson'] \n"
export_message="export_message = '<p> <b> Attention: </b> </br>  Vous vous apprêtez à télécharger les données de la <b>recherche courante.</b> </br> Pour n'exporter qu'un jeu de données, filtrez par <b>jeu de données</b> et cliquez sur le bouton <b> Rechercher </b> avant d'exporter. </br> </br>
 <small> <b> Notes: </b> </br> - Pour Ginco, utilisez le format CSV </br>  - Les données sont exportées dans le système de réference (SRID) 4326, encodage UTF8 </small> </p>' "

echo -e $observer_txt | sudo tee -a /etc/geonature/mods-enabled/occtax/conf_gn_module.toml
echo -e $available_format | sudo tee -a /etc/geonature/mods-enabled/occtax/conf_gn_module.toml
echo -e $export_message | sudo tee -a /etc/geonature/mods-enabled/occtax/conf_gn_module.toml
 


cd /home/$monuser/geonature/backend
source venv/bin/activate
geonature update_configuration --build=false
geonature update_module_configuration

rm -r custom
rm update_db.sql
rm map.config.ts