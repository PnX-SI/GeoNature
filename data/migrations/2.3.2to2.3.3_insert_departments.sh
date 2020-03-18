myrootpath=`pwd`/../..

. $myrootpath/config/settings.ini

wget  --cache=off http://geonature.fr/data/ign/departement_admin_express_2020-02.zip -P $myrootpath/tmp/geonature

unzip $myrootpath/tmp/geonature/departement_admin_express_2020-02.zip -d $myrootpath/tmp/geonature
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f $myrootpath/tmp/geonature/fr_departements.sql  &> $myrootpath/var/log/insert_departements.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f $myrootpath/data/core/ref_geo_departements.sql  &>> $myrootpath/var/log/insert_departements.log

sudo -n -u postgres -s psql -d $db_name -c "DROP TABLE ref_geo.temp_fr_departements;" &>> $myrootpath/var/log/insert_departements.log

