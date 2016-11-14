#!/bin/bash

#configuration initiale de l'installation serveur
. install_env.ini

#installation de l'atlas avec l'utilisateur courant
echo "téléchargement et installation de GeoNature-atlas ..."
cd /tmp
wget https://github.com/PnEcrins/GeoNature-atlas/archive/$atlas_release.zip
unzip $atlas_release.zip
rm $atlas_release.zip
mv GeoNature-atlas-$atlas_release /home/$monuser/atlas/
cd /home/$monuser/atlas

echo "Installation des logiciels manquant pour l'application GeoNature-atlas ..."
sudo apt-get install -y python-setuptools python-gdal python-virtualenv

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
################TODO mettre à jour la config.py
sed -i "s/database_connection = .*$/database_connection = \"postgresql:\/\/$user_pg:$user_pg_pass@$pg_host:$pg_port/$atlasdb_name\"/g" main/configuration/config.py
sed -i "s/STRUCTURE = \".*$/STRUCTURE = \"$structure\"/g"  main/configuration/config.py
sed -i "s/NOM_APPLICATION = \".*$/NOM_APPLICATION = \"$structure\"/g"  main/configuration/config.py

sudo ./install_db.sh

#configuration apache de GeoNature-atlas
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