#!/bin/bash

# Scripts qui restaure une BDD GINCO à parit d'un DUMP SQL
# Puis crée un Foreign Data Wrapper entre la base restaurée et la base GeoNature cible 
# remplir le fichier settings.ini en amont

. settings.ini
if [ ! -d 'log' ]
then
  mkdir log
fi

function write_log() {
    echo $1
    echo "" &>> log/restore_ginco_db.log
    echo "" &>> log/restore_ginco_db.log
    echo "--------------------" &>> log/restore_ginco_db.log
    echo $1 &>> log/restore_ginco_db.log
    echo "--------------------" &>> log/restore_ginco_db.log
}

function database_exists () {
    # /!\ Will return false if psql can't list database. Edit your pg_hba.conf
    # as appropriate.
    if [ -z $1 ]
        then
        # Argument is null
        return 0
    else
        # Grep db name in the list of database
        sudo -u postgres -s -- psql -tAl | grep -q "^$1|"
        return $?
    fi
}

# create user 
sudo ls
sudo -n -u postgres -s psql -c "CREATE ROLE admin WITH LOGIN PASSWORD '$ginco_admin_pg_pass';" &> log/restore_ginco_db.log
sudo -n -u postgres -s psql -c "CREATE ROLE ogam WITH LOGIN PASSWORD '$ginco_ogame_pg_pass';" &>> log/restore_ginco_db.log
sudo -n -u postgres -s psql -c "ALTER ROLE admin WITH SUPERUSER;" &>> log/restore_ginco_db.log
-- create database

if database_exists $ginco_db_name
then
        if $drop_ginco_db
            then
            write_log "Drop database..."
            sudo -u postgres -s dropdb $ginco_db_name
        else
            write_log "Database exists but the settings file indicate that we don't have to drop it."
        fi
fi
write_log "Create DB"
sudo -n -u postgres -s createdb -O admin $ginco_db_name &>> log/restore_ginco_db.log
sudo -n -u postgres -s psql -d $ginco_db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;" &>> log/restore_ginco_db.log
sudo -n -u postgres -s psql -d $ginco_db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';" &>> log/restore_ginco_db.log
sudo -n -u postgres -s psql -d $ginco_db_name -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' &>> log/restore_ginco_db.log
sudo -n -u postgres -s psql -d $ginco_db_name -c 'CREATE EXTENSION IF NOT EXISTS unaccent;' &>> log/restore_ginco_db.log

write_log "Restauration de la DB... ça va être long !"
export PGPASSWORD=$ginco_admin_pg_pass;psql -h $db_host -d $ginco_db_name -U admin -f $sql_dump_path &>> log/restore_ginco_db.log
write_log "Restauration terminée"



write_log "Création du lien entre base: FDW"

sudo -n -u postgres -s psql -d $geonature_db_name -c "CREATE EXTENSION IF NOT EXISTS postgres_fdw;"&>> log/restore_ginco_db.log
sudo -n -u postgres -s psql -d $geonature_db_name -c "DROP SERVER IF EXISTS gincoserver CASCADE;"&>> log/restore_ginco_db.log
sudo -n -u postgres -s psql -d $geonature_db_name -c "CREATE SERVER gincoserver FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '$db_host', dbname '$ginco_db_name', port '$db_port');"&>> log/restore_ginco_db.log

sudo -n -u postgres -s psql -d $geonature_db_name -c "CREATE USER MAPPING FOR geonatadmin SERVER gincoserver OPTIONS (user 'admin', password '$ginco_admin_pg_pass');"&>> log/restore_ginco_db.log

sudo -n -u postgres -s psql -d $geonature_db_name -c "ALTER SERVER gincoserver OWNER TO $geonature_pg_user;"&>> log/restore_ginco_db.log
export PGPASSWORD=$geonature_user_pg_pass;
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -c " DROP SCHEMA IF EXISTS ginco_migration;"
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -c "
CREATE SCHEMA ginco_migration;
IMPORT FOREIGN SCHEMA website FROM SERVER gincoserver INTO ginco_migration;
IMPORT FOREIGN SCHEMA raw_data FROM SERVER gincoserver INTO ginco_migration;
"

write_log "Restauration terminée"



