#!/usr/bin/env bash

filepath=$(realpath $0)
GEONATURE_ROOT=$(dirname $(dirname $(dirname $filepath)))

. $GEONATURE_ROOT/config/settings.ini

--wget  --cache=off http://geonature.fr/data/ign/reg_fr_admin_express_2020-07.zip -P $GEONATURE_ROOT/tmp/geonature

unzip $GEONATURE_ROOT/tmp/geonature/reg_fr_admin_express_2020-07.zip -d $GEONATURE_ROOT/tmp/geonature
sudo -u postgres psql -d $db_name -f $GEONATURE_ROOT/tmp/geonature/fr_regions.sql &> $GEONATURE_ROOT/var/log/insert_reg.log
sudo -u postgres psql -d $db_name -c "ALTER TABLE ref_geo.temp_fr_regions OWNER TO $user_pg;" &>> $GEONATURE_ROOT/var/log/insert_reg.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f $GEONATURE_ROOT/data/core/ref_geo_regions.sql &>> $GEONATURE_ROOT/var/log/insert_reg.log

sudo -n -u postgres psql -d $db_name -c "DROP TABLE ref_geo.temp_fr_regions;" &>> $GEONATURE_ROOT/var/log/insert_reg.log

# rm $GEONATURE_ROOT/tmp/geonature/reg_fr_admin_express_2020-07.zip
rm $GEONATURE_ROOT/tmp/geonature/fr_regions.sql
