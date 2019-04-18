#! /bin/bash
. migratetov2.ini
. ../../../config/settings.ini

touch ../../../var/log/mymigratetov2.log
sudo chmod 777 . ../../../var/log/mymigratetov2.log

#schema utilisateurs
if $import_users
then
    echo "Get utilisateurs schema content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f myusers.sql  &>> ../../../var/log/mymigratetov2.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f mypermissions.sql  &>> ../../../var/log/mymigratetov2.log
fi

#schema gn_meta
if $import_metadata
then
    echo "Get meta schema content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f mymeta.sql  &>> ../../../var/log/mymigratetov2.log
fi

#schema gn_meta
if $import_synthese
then
    echo "Get meta synthese content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f mysynthese.sql  &>> ../../../var/log/mymigratetov2.log
fi


if $import_ref_geo
then
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f myrefgeo.sql  &>> ../../../var/log/mymigratetov2.log
    if [ ! -f '../../../tmp/geonature/communes_fr_admin_express_2019-01.zip' ]
        then
            wget  --cache=off http://geonature.fr/data/ign/communes_fr_admin_express_2019-01.zip -P ../../../tmp/geonature
        else
            echo "tmp/geonature/communes_fr_admin_express_2019-01.zip already exist"
    fi
        unzip ../../../tmp/geonature/communes_fr_admin_express_2019-01.zip -d ../../../tmp/geonature
        sudo -n -u postgres -s psql -d $db_name -f ../../../tmp/geonature/fr_municipalities.sql &>> ../../../var/log/mymigratetov2.log
    rm ../../../tmp/geonature/*.sql
fi

