#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config/settings.ini

echo "Création du schéma contact..."
echo "" &>> log/install_schemas.log
echo "" &>> log/install_schemas.log
echo "--------------------" &>> log/install_schemas.log
echo "Création du schéma contact" &>> log/install_schemas.log
echo "--------------------" &>> log/install_schemas.log
echo "" &>> log/install_schemas.log
cp data/modules/contact/contact.sql /tmp/contact.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/contact.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/contact.sql  &>> log/install_schemas.log
