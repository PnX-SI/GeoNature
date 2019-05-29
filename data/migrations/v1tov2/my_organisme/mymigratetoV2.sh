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
fi

