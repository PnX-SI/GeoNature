#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must not be run as root" 1>&2
   exit 1
fi

. ../../config/settings.ini

mkdir /tmp/geonature

echo "Create contact schema..."
echo "--------------------" &> /var/log/geonature/install_contact_schema.log
echo "Create contact schema" &>> /var/log/geonature/install_contact_schema.log
echo "--------------------" &>> /var/log/geonature/install_contact_schema.log
echo "" &>> /var/log/geonature/install_contact_schema.log
cp data/contact.sql /tmp/geonature/contact.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/geonature/contact.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/geonature/contact.sql  &>> /var/log/geonature/install_contact_schema.log

echo "Create export contact view(s)..."
echo "--------------------" &> /var/log/geonature/install_contact_schema.log
echo "Create export contact view(s)" &>> /var/log/geonature/install_contact_schema.log
echo "--------------------" &>> /var/log/geonature/install_contact_schema.log
echo "" &>> /var/log/geonature/install_contact_schema.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/exports_contact.sql  &>> /var/log/geonature/install_contact_schema.log


echo "INSTALL SAMPLE  = $add_sample_data "
if $add_sample_data
	then
	echo "Insert sample data in contact schema..."
	echo "" &>> /var/log/geonature/install_contact_schema.log
	echo "" &>> /var/log/geonature/install_contact_schema.log
	echo "" &>> /var/log/geonature/install_contact_schema.log
	echo "--------------------" &>> /var/log/geonature/install_contact_schema.log
	echo "Insert sample data in contact schema..." &>> /var/log/geonature/install_contact_schema.log
	echo "--------------------" &>> /var/log/geonature/install_contact_schema.log
	echo "" &>> /var/log/geonature/install_contact_schema.log
	export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/sample_data.sql  &>> /var/log/geonature/install_contact_schema.log
fi

echo "Cleaning files..."
    rm /tmp/geonature/*.sql
