#!/bin/bash
# script bash pour la création du schéma de BDD du module

GEONATURE_DIR=$1
MODULE_DIR=$(readlink -e "${0%/*}")/

if [ -z $GEONATURE_DIR ]; then
    echo "$0 : Veuillez précisier l'emplacement de GeoNature (install_db.sh <chemin vers GeoNature>)"
    exit 1
fi

if [ "$(id -u)" == "0" ]; then
   echo "This script must not be run as root" 1>&2
   exit 1
fi

. ${GEONATURE_DIR}/config/settings.ini


echo "Create occtax schema..."
echo "--------------------" &> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
echo "Create occtax schema" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
echo "--------------------" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
echo "" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ${MODULE_DIR}/data/occtax.sql -v MYLOCALSRID=$srid_local   &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log

echo "Create export occtax view(s)..."
echo "--------------------" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
echo "Create export occtax view(s)" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
echo "--------------------" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
echo "" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ${MODULE_DIR}/data/exports_occtax.sql  &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log


echo "INSTALL SAMPLE  = $add_sample_data "
if $add_sample_data
	then
	echo "Insert sample data in occtax schema..."
	echo "" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
	echo "" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
	echo "" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
	echo "--------------------" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
	echo "Insert sample data in occtax schema..." &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
	echo "--------------------" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
	echo "" &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
	export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ${MODULE_DIR}/data/sample_data.sql  &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log
fi
