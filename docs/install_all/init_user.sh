#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

#configuration initiale de l'installation serveur
. install_env.ini

#affectation des droits d'exécution sur le fichier install_env.sh
chmod 755 install_env.sh

#installation de sudo et de l'utilisateur courant comme user sudo
apt-get update
apt-get install -y sudo
usermod -g www-data $monuser
usermod -a -G root $monuser
adduser $monuser sudo

echo "L'utilisateur $monuser dispose désormais des droits administrateurs avec sudo"
exit