#!/bin/bash


set -eo pipefail


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"

# Make sure root isnt running the script
if [ "$(id -u)" == "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi


cd "${BASE_DIR}"

source backend/venv/bin/activate
which geonature > /dev/null
if [ $? -ne 0 ]; then
  echo "La commande geonature n’a pas été installé dans le venv" >&2 |& tee -a "${LOG_FILE}"
  exit 1
fi

mkdir -p tmp
mkdir -p var/log

if [ "${db_host}" != "localhost" ] && [ "${db_host}" != "127.0.0.1" ]; then
    export $PGHOST=$db_host
    export $PGPORT=$db_port
    export $PGDATABASE=$remote_super_user_database_name
    export $PGUSER=$remote_super_user_name
    export $PGPASSWORD=$remote_super_user_pass
fi

if database_exists "${db_name}"; then
    if $drop_apps_db; then
        echo "Close all Postgresql conections on GeoNature DB"
        query=("SELECT pg_terminate_backend(pg_stat_activity.pid) "
            "FROM pg_stat_activity "
            "WHERE pg_stat_activity.datname = '${db_name}' "
            "AND pid <> pg_backend_pid() ;")
        sudo -E -u "postgres" -s psql -d "postgres" -c "${query[*]}"

        echo "Drop database..."
        sudo -E -u "postgres" -s dropdb "${db_name}"
    else
        echo "Database exists but the settings file indicates that we don't have to drop it."
        exit 0
    fi
fi

###################
# Create database #
###################

write_log "Check GeoNature database user '$user_pg' exists…"
user_pg_exists=$(sudo -E -u postgres -s psql -t -c "SELECT COUNT(1) FROM pg_catalog.pg_roles WHERE  rolname = '${user_pg}';")
if [ ${user_pg_exists} -eq 0 ]; then
  write_log "Create GeoNature database user…"
  sudo -E -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';" |& tee -a "${LOG_FILE}"
fi

write_log "Creating GeoNature database..."
sudo -E -u postgres -s createdb -O $user_pg $db_name -T template0 -E UTF-8 -l $my_local |& tee -a "${LOG_FILE}"

write_log "Adding default PostGIS extension"
sudo -E -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;" |& tee -a "${LOG_FILE}"

write_log "Extracting PostGIS version"
postgis_full_version=$(sudo -E -u postgres -s psql -d "${db_name}" -c "SELECT PostGIS_Version();")
postgis_short_version=$(echo "${postgis_full_version}" | sed -n 's/^\s*\([0-9]*\.[0-9]*\)\s.*/\1/p')
write_log "PostGIS full version:\n ${postgis_full_version}"
write_log  "PostGIS short version extract: '${postgis_short_version}'"

write_log "Adding Raster PostGIS extension if necessary"
postgis_required_version="3.0"
if [[ "$(printf '%s\n' "${postgis_required_version}" "${postgis_short_version}" | sort -V | head -n1)" = "${postgis_required_version}" ]]; then
    write_log "PostGIS version greater than or equal to ${postgis_required_version} --> adding Raster extension"
    sudo -E -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis_raster;" |& tee -a "${LOG_FILE}"
else
    write_log "PostGIS version lower than ${postgis_required_version} --> do nothing"
fi

write_log "Adding other use PostgreSQL extensions"
sudo -E -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS hstore;" |& tee -a "${LOG_FILE}"
sudo -E -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';" |& tee -a "${LOG_FILE}"
sudo -E -u postgres -s psql -d $db_name -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' |& tee -a "${LOG_FILE}"
sudo -E -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA pg_catalog;" |& tee -a "${LOG_FILE}"
sudo -E -u postgres -s psql -d $db_name -c 'CREATE EXTENSION IF NOT EXISTS "unaccent";' |& tee -a "${LOG_FILE}"


# Mise en place de la structure de la BDD et des données permettant son fonctionnement avec l'application
write_log 'GRANT access to GeoNature user to necessary tables...'
for table in geometry_columns geography_columns spatial_ref_sys; do
  sudo -E -u postgres -s psql -d $db_name -c "GRANT SELECT ON TABLE ${table} TO ${user_pg}" |& tee -a "${LOG_FILE}"
done


##########################
# Create database schema #
##########################

if [[ "${MODE}" == "dev" ]]; then
    export DATA_DIRECTORY="${BASE_DIR}/cache"
    mkdir -p "${DATA_DIRECTORY}"
fi

geonature db upgrade geonature@head -x local-srid=$srid_local |& tee -a "${LOG_FILE}"
geonature db autoupgrade -x local-srid=$srid_local |& tee -a "${LOG_FILE}"

geonature db exec "DO 'BEGIN ASSERT EXISTS (SELECT 1 FROM taxonomie.taxref); END'" 2>/dev/null || if [ "$install_bdc_statuts" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head |& tee -a "${LOG_FILE}"
    geonature taxref import-v16
else
    geonature taxref import-v16 --skip-bdc-statuts
fi
geonature db upgrade nomenclatures_taxonomie_data@head

# Installation des données exemples
if [ "$add_sample_data" = true ];
then
    write_log "Inserting sample datasets..."
    geonature db upgrade geonature-samples@head |& tee -a "${LOG_FILE}"
fi

if [ "$install_sig_layers" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head |& tee -a "${LOG_FILE}"
    geonature db upgrade ref_geo_fr_municipalities@head |& tee -a "${LOG_FILE}"
    geonature db upgrade ref_geo_fr_regions@head |& tee -a "${LOG_FILE}"
fi

if [ "$install_grid_layer" = true ];
then
    geonature db upgrade ref_geo_inpn_grids_1@head |& tee -a "${LOG_FILE}"
    geonature db upgrade ref_geo_inpn_grids_5@head |& tee -a "${LOG_FILE}"
    geonature db upgrade ref_geo_inpn_grids_10@head |& tee -a "${LOG_FILE}"
fi

if [ "$install_ref_sensitivity" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head |& tee -a "${LOG_FILE}"
    geonature sensitivity add-referential \
            --source-name "Référentiel sensibilité TAXREF v16 20230203" \
            --url https://geonature.fr/data/inpn/sensitivity/RefSensibiliteV16_20230203.zip \
            --zipfile RefSensibiliteV16_20230203.zip \
            --csvfile RefSensibiliteV16_20230203/RefSensibilite_16.csv  \
            --encoding=iso-8859-15 |& tee -a "${LOG_FILE}"
    geonature sensitivity refresh-rules-cache |& tee -a "${LOG_FILE}"
fi

if  [ "$install_default_dem" = true ];
then
    geonature db upgrade ign_bd_alti@head -x local-srid=$srid_local |& tee -a "${LOG_FILE}"
    if [ "$vectorise_dem" = true ];
    then
        geonature db upgrade ign_bd_alti_vector@head |& tee -a "${LOG_FILE}"
    fi
fi

geonature db autoupgrade -x local-srid=$srid_local |& tee -a "${LOG_FILE}"
