#!/bin/bash
. ../settings.ini

mkdir -p /tmp/taxhub
sudo chown -R "$(id -u)" /tmp/taxhub


LOG_DIR="../log/"

mkdir -p $LOG_DIR

echo "Import des données de taxref v12"

echo "Import des données de taxref v12" > $LOG_DIR/update_taxref_v12.log
array=( TAXREF_INPN_v12.zip ESPECES_REGLEMENTEES_v11.zip )
for i in "${array[@]}"
do
    if [ ! -f '/tmp/taxhub/'$i ]
    then
        wget http://geonature.fr/data/inpn/taxonomie/$i -P /tmp/taxhub
    else
        echo $i exists
    fi
    unzip -o /tmp/taxhub/$i -d /tmp/taxhub &>> $LOG_DIR/update_taxref_v12.log
done


echo "Import taxref v12"
# sudo -n -u postgres -s psql -d $geonature_db_name -c "DROP TABLE taxonomie.import_taxref"
export PGPASSWORD=$geonature_user_pg_pass;psql -h $db_host -U $geonature_pg_user -d $geonature_db_name  -f create_structure.sql   &>> $LOG_DIR/update_taxref_v12.log
sudo -n -u postgres -s psql -d $geonature_db_name -v USER_GN=$geonature_pg_user -f import_taxref_data.sql
export PGPASSWORD=$geonature_user_pg_pass;psql -h $db_host -U $geonature_pg_user -d $geonature_db_name  -f migrate_taxref_data.sql   &>> $LOG_DIR/update_taxref_v12.log
