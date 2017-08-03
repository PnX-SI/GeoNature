#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config/settings.ini

echo "Création du schéma contactfaune..."
echo "" &>> log/install_db.log
echo "" &>> log/install_db.log
echo "--------------------" &>> log/install_db.log
echo "Création du schéma contactfaune" &>> log/install_db.log
echo "--------------------" &>> log/install_db.log
echo "" &>> log/install_db.log
cp data/modules/contactfaune/contactfaune.sql /tmp/contactfaune.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/contactfaune.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/contactfaune.sql  &>> log/install_db.log
