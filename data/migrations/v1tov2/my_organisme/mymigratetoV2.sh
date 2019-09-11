#! /bin/bash
. ../migratetoV2.ini
. mymigratetov2.ini
. ../../../../config/settings.ini

sudo rm ../../../../var/log/mymigratetov2.log
touch ../../../../var/log/mymigratetov2.log
sudo chmod 777 . ../../../../var/log/mymigratetov2.log

#schema utilisateurs
if $import_users
then
    echo "Get utilisateurs schema content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f myusers.sql  &>> ../../../../var/log/mymigratetov2.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f mypermissions.sql  &>> ../../../../var/log/mymigratetov2.log
fi

#schema gn_meta
if $import_metadata
then
    echo "Get meta schema content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f mymeta.sql  &>> ../../../../var/log/mymigratetov2.log
fi

#schema aigle
if $import_aigle
then
    echo "Get aigle schema content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f aigle.sql  &>> ../../../../var/log/mymigratetov2.log
fi

#schema bryophytes
if $import_bryophytes
then
    echo "Get bryophytes schema content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f bryophytes.sql  &>> ../../../../var/log/mymigratetov2.log
fi

#schema gn_meta
# if $import_synthese
# then
#     echo "Get meta synthese content from geontauredb1"
#     export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f mysynthese.sql  &>> ../../../var/log/mymigratetov2.log
# fi
