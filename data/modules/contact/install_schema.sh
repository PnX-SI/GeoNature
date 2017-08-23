#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config/settings.ini

echo "Create contact schema..."
echo "" &>> log/install_contact_schema.log
echo "" &>> log/install_contact_schema.log
echo "" &>> log/install_contact_schema.log
echo "--------------------" &>> log/install_contact_schema.log
echo "Create contact schema" &>> log/install_contact_schema.log
echo "--------------------" &>> log/install_contact_schema.log
echo "" &>> log/install_contact_schema.log
cp data/modules/contact/contact.sql /tmp/contact.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/contact.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/contact.sql  &>> log/install_contact_schema.log

if $add_sample_data
	then
	echo "Insert sample data in contact schema..."
	echo "" &>> log/install_contact_schema.log
	echo "" &>> log/install_contact_schema.log
	echo "" &>> log/install_contact_schema.log
	echo "--------------------" &>> log/install_contact_schema.log
	echo "Insert sample data in contact schema..." &>> log/install_contact_schema.log
	echo "--------------------" &>> log/install_contact_schema.log
	echo "" &>> log/install_contact_schema.log
	export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/modules/contact/sample_data.sql  &>> log/install_contact_schema.log
fi

echo "Privileges on log folder..."
    chmod -R 777 log
