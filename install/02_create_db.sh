#!/bin/bash


set -o pipefail


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


if database_exists "${db_name}"; then
    if $drop_apps_db; then
        echo "Close all Postgresql conections on GeoNature DB"
        query=("SELECT pg_terminate_backend(pg_stat_activity.pid) "
            "FROM pg_stat_activity "
            "WHERE pg_stat_activity.datname = '${db_name}' "
            "AND pid <> pg_backend_pid() ;")
        sudo -u "postgres" -s psql -d "postgres" -c "${query[*]}"

        echo "Drop database..."
        sudo -u "postgres" -s dropdb "${db_name}"
    else
        echo "Database exists but the settings file indicates that we don't have to drop it."
	exit 1
    fi
fi

###################
# Create database #
###################

write_log "Check GeoNature database user '$user_pg' exists…"
user_pg_exists=$(sudo -u postgres -s psql -t -c "SELECT COUNT(1) FROM pg_catalog.pg_roles WHERE  rolname = '${user_pg}';")
if [ ${user_pg_exists} -eq 0 ]; then
  write_log "Create GeoNature database user…"
  sudo -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';" |& tee -a "${LOG_FILE}" || exit 1
fi

write_log "Creating GeoNature database..."
sudo -u postgres -s createdb -O $user_pg $db_name -T template0 -E UTF-8 -l $my_local |& tee -a "${LOG_FILE}" || exit 1

write_log "Adding default PostGIS extension"
sudo -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;" |& tee -a "${LOG_FILE}" || exit 1

write_log "Extracting PostGIS version"
postgis_full_version=$(sudo -u postgres -s psql -d "${db_name}" -c "SELECT PostGIS_Version();")
postgis_short_version=$(echo "${postgis_full_version}" | sed -n 's/^\s*\([0-9]*\.[0-9]*\)\s.*/\1/p')
write_log "PostGIS full version:\n ${postgis_full_version}"
write_log  "PostGIS short version extract: '${postgis_short_version}'"

write_log "Adding Raster PostGIS extension if necessary"
postgis_required_version="3.0"
if [[ "$(printf '%s\n' "${postgis_required_version}" "${postgis_short_version}" | sort -V | head -n1)" = "${postgis_required_version}" ]]; then
    write_log "PostGIS version greater than or equal to ${postgis_required_version} --> adding Raster extension"
    sudo -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis_raster;" |& tee -a "${LOG_FILE}" || exit 1
else
    write_log "PostGIS version lower than ${postgis_required_version} --> do nothing"
fi

write_log "Adding other use PostgreSQL extensions"
sudo -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS hstore;" |& tee -a "${LOG_FILE}" || exit 1
sudo -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';" |& tee -a "${LOG_FILE}" || exit 1
sudo -u postgres -s psql -d $db_name -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' |& tee -a "${LOG_FILE}" || exit 1
sudo -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA pg_catalog;" |& tee -a "${LOG_FILE}" || exit 1


# Mise en place de la structure de la BDD et des données permettant son fonctionnement avec l'application
write_log 'GRANT access to GeoNature user to necessary tables...'
for table in geometry_columns geography_columns spatial_ref_sys; do
  sudo -u postgres -s psql -d $db_name -c "GRANT SELECT ON TABLE ${table} TO ${user_pg}" |& tee -a "${LOG_FILE}" || exit 1
done


##########################
# Create database schema #
##########################


function gn_psql() {
  PGPASSWORD=$user_pg_pass psql -h $db_host -U $user_pg -d $db_name -v ON_ERROR_STOP=ON $* |& tee -a "${LOG_FILE}" || exit 1
}

geonature db upgrade geonature@head -x data-directory=tmp/ -x local-srid=$srid_local

# Installation des données exemples
if [ "$add_sample_data" = true ];
then
    write_log "Inserting sample datasets..."
    geonature db upgrade geonature-samples@head |& tee -a "${LOG_FILE}" || exit 1

    write_log "Inserting sample dataset of taxons for taxonomic schema..."
    geonature db upgrade taxonomie_taxons_example@head |& tee -a "${LOG_FILE}" || exit 1
fi

if [ "$install_sig_layers" = true ];
then
    geonature db upgrade ref_geo_fr_departments -x data-directory=tmp |& tee -a "${LOG_FILE}" || exit 1
    geonature db upgrade ref_geo_fr_municipalities -x data-directory=tmp |& tee -a "${LOG_FILE}" || exit 1
fi

if [ "$install_grid_layer" = true ];
then
    geonature db upgrade ref_geo_inpn_grids_1 -x data-directory=tmp |& tee -a "${LOG_FILE}" || exit 1
    geonature db upgrade ref_geo_inpn_grids_5 -x data-directory=tmp |& tee -a "${LOG_FILE}" || exit 1
    geonature db upgrade ref_geo_inpn_grids_10 -x data-directory=tmp |& tee -a "${LOG_FILE}" || exit 1
fi

if  [ "$install_default_dem" = true ];
then
    write_log "Insert default French DEM (IGN 250m BD alti). (This may takes a few minutes)"
    if [ ! -f 'tmp/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip' ]
    then
        wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P tmp
    else
        echo "tmp/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip already exist"
    fi
          unzip -u tmp/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d tmp
    export PGPASSWORD=$user_pg_pass;raster2pgsql -s $srid_local -c -C -I -M -d -t 5x5 tmp/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h $db_host -U $user_pg -d $db_name  &>> var/log/install_db.log
	#echo "Refresh DEM spatial index. This may take a few minutes..."
    gn_psql -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;" &>> var/log/install_db.log
    if [ "$vectorise_dem" = true ];
    then
        write_log "Vectorisation of DEM raster. This may take a few minutes..."
        gn_psql -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;" &>> var/log/install_db.log

        write_log "Refresh DEM vector spatial index. This may take a few minutes..."
        gn_psql -c "REINDEX INDEX ref_geo.index_dem_vector_geom;" &>> var/log/install_db.log
    fi
fi



# Suppression des fichiers : on ne conserve que les fichiers compressés
echo "Cleaning files..."

if [ "$install_default_dem" = true ];
then
    rm tmp/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc
    rm tmp/IGNF_BDALTIr_2-0_ASC_250M_LAMB93_IGN69_FRANCE.html
fi

rm -f tmp/*.sql
