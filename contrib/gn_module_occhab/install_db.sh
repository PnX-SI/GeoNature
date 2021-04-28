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

log_file=${GEONATURE_DIR}/var/log/install_occhab_schema.log

echo "Create occhab schema..."
echo "--------------------" &> $log_file
echo "Create occhab schema" &>> $log_file
echo "--------------------" &>> $log_file
echo "" &>> $log_file
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ${MODULE_DIR}/data/occhab.sql -v MYLOCALSRID=$srid_local   &>> ${GEONATURE_DIR}/var/log/install_occtax_schema.log

echo "Insert Occhab data..."
echo "--------------------" &> $log_file
echo "Insert Occhab data" &>> $log_file
echo "--------------------" &>> $log_file
echo "" &>> $log_file
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ${MODULE_DIR}/data/sample_data.sql  &>> $log_file
