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

mkdir -p tmp/geonature
mkdir -p tmp/taxhub
mkdir -p tmp/nomenclatures
mkdir -p tmp/usershub
mkdir -p tmp/habref
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



write_log "Creating 'public' functions..."
gn_psql -f data/core/public.sql

if [ "$install_usershub_schema" = true ];
 then
    write_log "Getting and creating USERS schema (utilisateurs)..."
    wget -nc https://raw.githubusercontent.com/PnX-SI/UsersHub/$usershub_release/data/usershub.sql -P tmp/usershub || exit 1
    gn_psql -f tmp/usershub/usershub.sql
    write_log "Insert minimal data (utilisateurs)..."
    wget -nc https://raw.githubusercontent.com/PnX-SI/UsersHub/$usershub_release/data/usershub-data.sql -P tmp/usershub || exit 1
    gn_psql -f tmp/usershub/usershub-data.sql
    wget -nc https://raw.githubusercontent.com/PnX-SI/UsersHub/$usershub_release/data/usershub-dataset.sql -P tmp/usershub || exit 1
    gn_psql -f tmp/usershub/usershub-dataset.sql
    write_log "Insertion of data for usershub..."
    # First insert TaxHub data for UsersHub
    wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/adds_for_usershub.sql -P tmp/taxhub || exit 1
    gn_psql -f tmp/taxhub/adds_for_usershub.sql
    # Insert GeoNature data for UsersHub
    gn_psql -f data/utilisateurs/adds_for_usershub.sql
fi

echo "Download and extract Taxref file..."

wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/inpn/data_inpn_taxhub.sql -P tmp/taxhub || exit 1

# sed to replace /tmp/taxhub to ~/<geonature_dir>/tmp.taxhub
sed -i "s#FROM .*/tmp/taxhub\(.*\)'#FROM '${BASE_DIR}/tmp/taxhub\1'#g" tmp/taxhub/data_inpn_taxhub.sql || exit 1

array=( TAXREF_v14_2020.zip ESPECES_REGLEMENTEES_v11.zip LR_FRANCE_20160000.zip BDC-Statuts-v14.zip )
for i in "${array[@]}"
do
  if [ ! -f 'tmp/taxhub/'$i ]
  then
      wget -nc http://geonature.fr/data/inpn/taxonomie/$i -P tmp/taxhub || exit 1
  else
      echo $i exists
  fi
  unzip -u tmp/taxhub/$i -d tmp/taxhub || exit 1
done

echo "Getting 'taxonomie' schema creation scripts..."
wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdb.sql -P tmp/taxhub || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata.sql -P tmp/taxhub || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata_atlas.sql -P tmp/taxhub || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/materialized_views.sql -P tmp/taxhub || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/generic_drop_and_restore_deps_views.sql -P tmp/taxhub || exit 1

write_log "Creating 'taxonomie' schema..."
gn_psql -f tmp/taxhub/taxhubdb.sql
write_log "Inserting INPN taxonomic data... (This may take a few minutes)"
sudo -u postgres -s psql -d $db_name -v ON_ERROR_STOP=ON -f tmp/taxhub/data_inpn_taxhub.sql |& tee -a "${LOG_FILE}" || exit 1  # FIXME remove sudo
#gn_psql -f tmp/taxhub/data_inpn_taxhub.sql &>> var/log/install_db.log

write_log "Creating database views utils fonctions..."
gn_psql -f tmp/taxhub/generic_drop_and_restore_deps_views.sql

write_log "Creating dictionaries data for taxonomic schema..."

gn_psql -f tmp/taxhub/taxhubdata.sql

write_log "Inserting sample dataset - atlas attributes...."
gn_psql -f tmp/taxhub/taxhubdata_atlas.sql

write_log "Creating a view that represents the taxonomic hierarchy..."
gn_psql -f tmp/taxhub/materialized_views.sql

echo "Download and extract Habref file..."
wget -nc https://geonature.fr/data/inpn/habitats/HABREF_50.zip -P tmp/habref || exit 1
unzip -u tmp/habref/HABREF_50.zip -d tmp/habref || exit 1

wget -nc https://raw.githubusercontent.com/PnX-SI/Habref-api-module/$habref_api_release/src/pypn_habref_api/data/habref.sql -P tmp/habref || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/Habref-api-module/$habref_api_release/src/pypn_habref_api/data/data_inpn_habref.sql -P tmp/habref || exit 1

# sed to replace /tmp/taxhub to ~/<geonature_dir>/tmp.taxhub
sed -i "s#FROM .*/tmp/habref\(.*\)'#FROM '${BASE_DIR}/tmp/habref\1'#g" tmp/habref/data_inpn_habref.sql || exit 1

write_log "Creating 'ref_habitat' schema..."
gn_psql -f tmp/habref/habref.sql

write_log "Inserting INPN habitat data..."
sudo -u postgres -s psql -d $db_name -v ON_ERROR_STOP=ON -f tmp/habref/data_inpn_habref.sql |& tee -a "${LOG_FILE}" || exit 1  # FIXME remove sudo


echo "Getting 'ref_nomenclature' schema creation scripts..."
wget -nc https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/nomenclatures.sql -P tmp/nomenclatures || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/data_nomenclatures.sql -P tmp/nomenclatures || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/nomenclatures_taxonomie.sql -P tmp/nomenclatures || exit 1
wget -nc https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/data_nomenclatures_taxonomie.sql -P tmp/nomenclatures || exit 1

write_log "Creating 'ref_nomenclatures' schema"

gn_psql -f tmp/nomenclatures/nomenclatures.sql
gn_psql -f tmp/nomenclatures/nomenclatures_taxonomie.sql

write_log "Inserting 'ref_nomenclatures' data..."

sudo sed -i "s/MYDEFAULTLANGUAGE/$default_language/g" tmp/nomenclatures/data_nomenclatures.sql
gn_psql -f tmp/nomenclatures/data_nomenclatures.sql
gn_psql -f tmp/nomenclatures/data_nomenclatures_taxonomie.sql

write_log "Creating 'gn_commons' schema..."
cp data/core/commons.sql tmp/geonature/commons.sql || exit 1
sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/commons.sql || exit 1
gn_psql -f tmp/geonature/commons.sql

write_log "Creating 'gn_meta' schema..."

gn_psql -f data/core/meta.sql

write_log "Creating 'ref_geo' schema..."
cp data/core/ref_geo.sql tmp/geonature/ref_geo.sql || exit 1
sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/ref_geo.sql || exit 1
gn_psql -f tmp/geonature/ref_geo.sql

write_log "Creating 'gn_imports' schema..."
gn_psql -f data/core/imports.sql

write_log "Creating 'gn_synthese' schema..."
cp data/core/synthese.sql tmp/geonature/synthese.sql
sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/synthese.sql
gn_psql -f tmp/geonature/synthese.sql
gn_psql -f data/core/synthese_default_values.sql

write_log "Creating 'gn_exports' schema..."
gn_psql -f data/core/exports.sql

write_log "Creating 'gn_monitoring' schema..."
gn_psql -v MYLOCALSRID=$srid_local -f data/core/monitoring.sql

write_log "Creating 'gn_permissions' schema"
gn_psql -f data/core/permissions.sql

write_log "Insert 'gn_permissions' data"
gn_psql -f data/core/permissions_data.sql

gn_psql -f data/core/sensitivity.sql

write_log "Insert 'gn_sensitivity' data"
echo "--------------------"
if [ ! -f 'tmp/geonature/referentiel_donnees_sensibles_v13.csv' ]
    then
        wget -nc https://geonature.fr/data/inpn/sensitivity/referentiel_donnees_sensibles_v13.csv -P tmp/geonature/ || exit 1
        mv tmp/geonature/referentiel_donnees_sensibles_v13.csv tmp/geonature/referentiel_donnees_sensibles.csv || exit 1
    else
        echo "tmp/geonature/referentiel_donnees_sensibles.csv already exist"
fi
cp data/core/sensitivity_data.sql tmp/geonature/sensitivity_data.sql || exit 1
sed -i "s#FROM .*/tmp/geonature\(.*\)'#FROM '${BASE_DIR}/tmp/geonature\1'#g" tmp/geonature/sensitivity_data.sql || exit 1
echo "Insert 'gn_sensitivity' data... (This may take a few minutes)"
sudo -u postgres -s psql -d $db_name -v ON_ERROR_STOP=ON -f tmp/geonature/sensitivity_data.sql |& tee -a "${LOG_FILE}" || exit 1  # FIXME remove sudo

write_log "Creating table and FK depending of other schema"
gn_psql -f data/core/commons_after.sql

# Installation des données exemples
if [ "$add_sample_data" = true ];
then
    write_log "Inserting sample datasets..."
    gn_psql -f data/core/meta_data.sql

    write_log "Inserting sample dataset of taxons for taxonomic schema..."

    wget -nc https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata_taxons_example.sql -P tmp/taxhub || exit 1
    gn_psql -f tmp/taxhub/taxhubdata_taxons_example.sql
fi


geonature db stamp f06cc80cc8ba  # mark schema as in version 2.7.5
geonature db upgrade geonature@head  # upgrade schema to last revision


if [ "$install_sig_layers" = true ];
then
    geonature db upgrade ref_geo_fr_departments -x geo-data-directory=tmp/geonature |& tee -a "${LOG_FILE}" || exit 1
    geonature db upgrade ref_geo_fr_municipalities -x geo-data-directory=tmp/geonature |& tee -a "${LOG_FILE}" || exit 1
fi

if [ "$install_grid_layer" = true ];
then
    geonature db upgrade ref_geo_inpn_grids_1 -x geo-data-directory=tmp/geonature |& tee -a "${LOG_FILE}" || exit 1
    geonature db upgrade ref_geo_inpn_grids_5 -x geo-data-directory=tmp/geonature |& tee -a "${LOG_FILE}" || exit 1
    geonature db upgrade ref_geo_inpn_grids_10 -x geo-data-directory=tmp/geonature |& tee -a "${LOG_FILE}" || exit 1
fi

if  [ "$install_default_dem" = true ];
then
    write_log "Insert default French DEM (IGN 250m BD alti). (This may takes a few minutes)"
    if [ ! -f 'tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip' ]
    then
        wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P tmp/geonature
    else
        echo "tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip already exist"
    fi
          unzip -u tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d tmp/geonature
    export PGPASSWORD=$user_pg_pass;raster2pgsql -s $srid_local -c -C -I -M -d -t 5x5 tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h $db_host -U $user_pg -d $db_name  &>> var/log/install_db.log
	#echo "Refresh DEM spatial index. This may take a few minutes..."
    sudo -u postgres -s psql -d $db_name -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;" &>> var/log/install_db.log
    if [ "$vectorise_dem" = true ];
    then
        write_log "Vectorisation of DEM raster. This may take a few minutes..."
        sudo -u postgres -s psql -d $db_name -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;" &>> var/log/install_db.log

        write_log "Refresh DEM vector spatial index. This may take a few minutes..."
        sudo -u postgres -s psql -d $db_name -c "REINDEX INDEX ref_geo.index_dem_vector_geom;" &>> var/log/install_db.log
    fi
fi



# Suppression des fichiers : on ne conserve que les fichiers compressés
echo "Cleaning files..."

if [ "$install_default_dem" = true ];
then
    rm tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc
    rm tmp/geonature/IGNF_BDALTIr_2-0_ASC_250M_LAMB93_IGN69_FRANCE.html
fi

rm -f tmp/geonature/*.sql
rm -f tmp/usershub/*.sql
rm -rf tmp/taxhub/TAXREF_INPN_v13
rm -f tmp/taxhub/*.csv
rm -f tmp/taxhub/*.sql
rm -f tmp/habref/*.csv
rm -f tmp/habref/*.pdf
rm -f tmp/habref/*.sql
rm -f tmp/nomenclatures/*.sql
