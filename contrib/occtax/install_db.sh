#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must not be run as root" 1>&2
   exit 1
fi

. ../../config/settings.ini

if [ ! -d 'tmp' ]
then
  mkdir tmp
fi

echo "Create occtax schema..."
echo "--------------------" &> ../../var/log/install_occtax_schema.log
echo "Create occtax schema" &>> ../../var/log/install_occtax_schema.log
echo "--------------------" &>> ../../var/log/install_occtax_schema.log
echo "" &>> ../../var/log/install_occtax_schema.log
cp data/occtax.sql tmp/occtax.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" tmp/occtax.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/occtax.sql  &>> ../../var/log/install_occtax_schema.log

echo "Create export occtax view(s)..."
echo "--------------------" &>> ../../var/log/install_occtax_schema.log
echo "Create export occtax view(s)" &>> ../../var/log/install_occtax_schema.log
echo "--------------------" &>> ../../var/log/install_occtax_schema.log
echo "" &>> ../../var/log/install_occtax_schema.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/exports_occtax.sql  &>> ../../var/log/install_occtax_schema.log


echo "INSTALL SAMPLE  = $add_sample_data "
if $add_sample_data
	then
	echo "Insert sample data in occtax schema..."
	echo "" &>> ../../var/log/install_occtax_schema.log
	echo "" &>> ../../var/log/install_occtax_schema.log
	echo "" &>> ../../var/log/install_occtax_schema.log
	echo "--------------------" &>> ../../var/log/install_occtax_schema.log
	echo "Insert sample data in occtax schema..." &>> ../../var/log/install_occtax_schema.log
	echo "--------------------" &>> ../../var/log/install_occtax_schema.log
	echo "" &>> ../../var/log/install_occtax_schema.log
	export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/sample_data.sql  &>> ../../var/log/install_occtax_schema.log
fi

echo "Cleaning files..."
    rm tmp/*.sql
