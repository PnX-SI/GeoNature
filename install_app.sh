#!/bin/bash

. config/settings.ini

# Donner les droits nécessaires pour le bon fonctionnement de l'application (adapter les chemins à votre serveur)
echo "Configuration des droits des répertoires de l'application..."
mkdir log
mkdir cache
chmod -R 777 log
chmod -R 777 cache
chmod -R 775 web/exportshape
chmod -R 775 web/uploads/shapes
chmod -R 775 web/uploads/exports
mkdir web/uploads/gpx
chmod -R 775 web/uploads/gpx


echo "Vider le cache de Symfony..."
php symfony cc

echo "Créer les fichiers de configurations en lien avec la base de données..."
cp config/databases.yml.sample config/databases.yml
cp wms/wms.map.sample wms/wms.map
sed -i "s/MYLOCALSRID/$srid_local/g" wms/wms.map

echo "configuration du fichier config/databases.yml..."
sed -i "s/host=localhost;dbname=.*$/host=$db_host;dbname=$db_name'/" config/databases.yml
sed -i "s/username: .*$/username: $user_pg/" config/databases.yml
sed -i "s/password: .*$/password: $user_pg_pass/" config/databases.yml

echo "Configuration du fichier wms/wms.map ..."
sed -i "s/CONNECTION \"host=localhost.*$/CONNECTION \"host=$db_host dbname=$db_name user=$user_pg password=$user_pg_pass\"/" wms/wms.map

#echo "Suppression des fichier de log de l'installation..."
#rm log/*.log

echo "Création des fichiers de configuration Apache..."
cp apache/sf.conf.sample apache/sf.conf
cp apache/synthese.conf.sample apache/synthese.conf
cp apache/wms.conf.sample apache/wms.conf

echo "Création des fichiers de configuration de l'application..."
cp web/js/config.js.sample web/js/config.js
cp web/js/configmap.js.sample web/js/configmap.js
cp lib/sfGeonatureConfig.php.sample lib/sfGeonatureConfig.php
sed -i "s/MYLOCALSRID/$srid_local/g" lib/sfGeonatureConfig.php

echo "Configuration du répertoire web de l'application..."
sudo ln -s ${PWD}/web/ /var/www/geonature
echo "Vous devez maintenant éditer les fichiers de configuration de l'application : web/js/config.js, web/js/configmap.js et lib/sfGeonatureConfig.php et les adapter à votre besoin."
echo "Vous devez également éditer les fichiers de configuration Apache : apache/sf.conf, apache/synthese.conf et apache/wms.conf et adapter les chemins à votre serveur."
