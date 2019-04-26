#! /bin/bash
. migratetoV2.ini
. ../../../config/settings.ini
echo $geonature1user

#Sur le serveur de GeoNature V2 : création du lien FDW avec la base GeoNature1 
sudo rm ../../../var/log/migratetov2.log
sudo touch ../../../var/log/migratetov2.log
sudo chmod 777 ../../../var/log/migratetov2.log

sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgres_fdw;" >> ../../../var/log/migratetov2.log
sudo -n -u postgres -s psql -d $db_name -c "DROP SERVER IF EXISTS geonature1server CASCADE;" >> ../../../var/log/migratetov2.log
sudo -n -u postgres -s psql -d $db_name -c "CREATE SERVER geonature1server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '$geonature1host', dbname '$geonature1db', port '$geonature1port');" >> ../../../var/log/migratetov2.log
sudo -n -u postgres -s psql -d $db_name -c "CREATE USER MAPPING FOR $user_pg SERVER geonature1server OPTIONS (user '$geonature1user', password '$geonature1userpass');" >> ../../../var/log/migratetov2.log
sudo -n -u postgres -s psql -d $db_name -c "ALTER SERVER geonature1server OWNER TO $user_pg;" >> ../../../var/log/migratetov2.log

echo "Create v1_compat schema and architecture"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f create_v1_compat.sql  &>> ../../../var/log/migratetov2.log

#schema utilisateurs
if $import_users
then
    echo "Get utilisateurs schema content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f users.sql  &>> ../../../var/log/migratetov2.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f permissions.sql  &>> ../../../var/log/migratetov2.log
fi

#schema taxonomie
if $import_taxonomie
then
    echo "Get taxonomie schema content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f taxonomie.sql  &>> ../../../var/log/migratetov2.log
fi

#schema gn_meta
if $import_metadata
then
    echo "Get meta schema content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f meta.sql  &>> ../../../var/log/migratetov2.log
fi

# ref_geo
if $import_ref_geo
then
    echo "Get meta synthese content from geontauredb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ref_geo.sql  &>> ../../../var/log/migratetov2.log
fi

#schema pr_occtax
if $import_contactfaune
then
    echo "Get contactfaune content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f contact_faune_to_occtax.sql  &>> ../../../var/log/migratetov2.log
fi

#schema pr_occtax
if $import_contactinv
then
    echo "Get contactinv content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f contact_inv_to_occtax.sql  &>> ../../../var/log/migratetov2.log
fi

#schema pr_occtax
if $import_contactflore
then
    echo "Get contactflore content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f contact_flore_to_occtax.sql  &>> ../../../var/log/migratetov2.log
fi

#schema v1_florestation
if $import_florestation
then
    echo "Get florestation content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f florestation.sql  &>> ../../../var/log/migratetov2.log
fi

#schema v1_florepatri
if $import_florepatri
then
    echo "Get florepatri content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f florepatri.sql  &>> ../../../var/log/migratetov2.log
fi

#schema gn_synthese
if $import_synthese
then
    echo "Get synthese content from geonaturedb1"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f synthese.sql  &>> ../../../var/log/migratetov2.log
fi

# echo "Maintenant tu dois t'inspirer du script migratetov2.sql qui a été écrit pour le PNE."
# echo "ce script établi des correspondances bib_programmes <-> t_acquisition_frameworks, bib_lots <-> t_datasets, bib_criteres_synthese et nomenclatures."
# echo "Ces correspondances sont propres à chaque structures et ne peuvent pas être automatisées."

#export PGPASSWORD='$user_pg_pass';psql -h $db_host -U $user_pg -d $db_name -f 'migratetov2.sql' >> ../../../var/log/migratetov2.log
#export PGPASSWORD='$user_pg_pass';psql -h $db_host -U $user_pg -d $db_name -f 'v1_contactfaune.sql' >> ../../../var/log/migratetov2.log

