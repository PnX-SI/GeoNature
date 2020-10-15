#!/bin/bash

filepath=$(realpath $0)
GEONATURE_ROOT=$(dirname $(dirname $(dirname $filepath)))

. $GEONATURE_ROOT/config/settings.ini

wget  --cache=off http://geonature.fr/data/ign/departement_admin_express_2020-02.zip -P $GEONATURE_ROOT/tmp/geonature

unzip $GEONATURE_ROOT/tmp/geonature/departement_admin_express_2020-02.zip -d $GEONATURE_ROOT/tmp/geonature
sudo ls
sudo -u postgres -s psql -d $db_name -f $GEONATURE_ROOT/tmp/geonature/fr_departements.sql &> $GEONATURE_ROOT/var/log/insert_departements.log
sudo -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_fr_departements OWNER TO $user_pg;" &>> $GEONATURE_ROOT/var/log/insert_departements.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f $GEONATURE_ROOT/data/core/ref_geo_departements.sql &>> $GEONATURE_ROOT/var/log/insert_departements.log

sudo -n -u postgres -s psql -d $db_name -c "DROP TABLE ref_geo.temp_fr_departements;" &>> $GEONATURE_ROOT/var/log/insert_departements.log

rm $GEONATURE_ROOT/tmp/geonature/departement_admin_express_2020-02.zip
rm $GEONATURE_ROOT/tmp/geonature/fr_departements.sql