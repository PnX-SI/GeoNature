#!/bin/bash
currentdir=${PWD##*/}
parentdir="$(dirname "$(pwd)")"
if [ $currentdir != 'install' ]
then
    echo 'Please run the script from the install directory'
    exit
fi

cd ../
# Make sure root cannot run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi

. config/settings.ini

if [ ! -d 'tmp' ]
then
  mkdir tmp
fi

if [ ! -d 'tmp/geonature/' ]
then
  mkdir tmp/geonature
fi

if [ ! -d 'tmp/taxhub/' ]
then
  mkdir tmp/taxhub
fi

if [ ! -d 'tmp/nomenclatures/' ]
then
  mkdir tmp/nomenclatures
fi

if [ ! -d 'tmp/usershub/' ]
then
  mkdir tmp/usershub
fi

if [ ! -d 'var' ]
then
  mkdir var
fi

if [ ! -d 'var/log' ]
then
  mkdir var/log
  chmod -R 775 var/log/
fi

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

function write_log() {
    echo $1
    echo "" &>> var/log/install_db.log
    echo "" &>> var/log/install_db.log
    echo "--------------------" &>> var/log/install_db.log
    echo $1 &>> var/log/install_db.log
    echo "--------------------" &>> var/log/install_db.log
}


if database_exists $db_name
then
        if $drop_apps_db
            then
            echo "Drop database..."
            sudo -u postgres -s dropdb $db_name
        else
            echo "Database exists but the settings file indicate that we don't have to drop it."
        fi
fi

if ! database_exists $db_name
then
    echo "--------------------" &> var/log/install_db.log
    write_log "Creating GeoNature database..."
    sudo -n -u postgres -s createdb -O $user_pg $db_name -T template0 -E UTF-8 -l $my_local
    write_log "Adding PostGIS and other use PostgreSQL extensions"
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;" &>> var/log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS hstore;" &>> var/log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';" &>> var/log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' &>> var/log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" &>> var/log/install_db.log


    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "GRANT..."
    cp data/grant.sql tmp/geonature/grant.sql
    sudo sed -i "s/MYPGUSER/$user_pg/g" tmp/geonature/grant.sql
    write_log 'GRANT'
    sudo -n -u postgres -s psql -d $db_name -f tmp/geonature/grant.sql &>> var/log/install_db.log

    write_log "Creating 'public' functions..."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/public.sql  &>> var/log/install_db.log

    if [ "$install_usershub_schema" = true ];
     then
        write_log "Getting and creating USERS schema (utilisateurs).."
        wget https://raw.githubusercontent.com/PnEcrins/UsersHub/$usershub_release/data/usershub.sql -P tmp/usershub
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/usershub/usershub.sql  &>> var/log/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/usershub/usershub_api.sql  &>> var/log/install_db.log
        
        write_log "Insert minimal data (utilisateurs)"
        wget https://raw.githubusercontent.com/PnEcrins/UsersHub/$usershub_release/data/usershub-data.sql -P tmp/usershub
        wget https://raw.githubusercontent.com/PnEcrins/UsersHub/$usershub_release/data/usershub-dataset.sql -P tmp/usershub
        wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/adds_for_usershub.sql -P tmp/taxhub
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/usershub/usershub-data.sql  &>> var/log/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/usershub/usershub-dataset.sql  &>> var/log/install_db.log
        write_log "Insertion of data for usershub..."
        # fisrt insert taxhub data for usershub
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/taxhub/adds_for_usershub.sql  &>> var/log/install_db.log
        # insert geonature data for usershub
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/utilisateurs/adds_for_usershub.sql  &>> var/log/install_db.log
        
    fi

    echo "Download and extract taxref file..."

    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/inpn/data_inpn_taxhub.sql -P tmp/taxhub

    # sed to replace /tmp/taxhub to ~/<geonature_dir>/tmp.taxhub
    sed -i 's#'/tmp/taxhub'#'$parentdir/tmp/taxhub'#g' tmp/taxhub/data_inpn_taxhub.sql
    

    array=( TAXREF_INPN_v11.zip ESPECES_REGLEMENTEES_v11.zip LR_FRANCE_20160000.zip )
    for i in "${array[@]}"
    do
      if [ ! -f 'tmp/taxhub/'$i ]
      then
          wget http://geonature.fr/data/inpn/taxonomie/$i -P tmp/taxhub
      else
          echo $i exists
      fi
      unzip tmp/taxhub/$i -d tmp/taxhub
    done

    echo "Getting 'taxonomie' schema creation scripts..."
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdb.sql -P tmp/taxhub
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata.sql -P tmp/taxhub
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata_atlas.sql -P tmp/taxhub
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/materialized_views.sql -P tmp/taxhub

    write_log "Creating 'taxonomie' schema..."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/taxhub/taxhubdb.sql  &>> var/log/install_db.log
    write_log "Inserting INPN taxonomic data... (This may take a few minutes)"
    sudo -n -u postgres -s psql -d $db_name -f tmp/taxhub/data_inpn_taxhub.sql &>> var/log/install_db.log

    write_log "Creating dictionaries data for taxonomic schema..."

    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/taxhub/taxhubdata.sql  &>> var/log/install_db.log

    write_log "Inserting sample dataset  - atlas attributes...."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/taxhub/taxhubdata_atlas.sql  &>> var/log/install_db.log

    write_log "Creating a view that represent the taxonomic hierarchy..."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/taxhub/materialized_views.sql  &>> var/log/install_db.log


    echo "Download and extract habref file..."
    if [ ! -d 'tmp/habref/' ]
    then
        mkdir tmp/habref
    fi
    if [ ! -f 'tmp/habref/HABREF_50.zip' ]
    then
      wget https://geonature.fr/data/inpn/habitats/HABREF_50.zip -P tmp/habref
    else
      echo HABREF_40.zip exists
    fi
    unzip tmp/habref/HABREF_50.zip -d tmp/habref
    
    wget https://raw.githubusercontent.com/PnX-SI/Habref-api-module/$habref_api_release/src/pypn_habref_api/data/habref.sql -P tmp/habref
    wget https://raw.githubusercontent.com/PnX-SI/Habref-api-module/$habref_api_release/src/pypn_habref_api/data/data_inpn_habref.sql -P tmp/habref 

    # sed to replace /tmp/taxhub to ~/<geonature_dir>/tmp.taxhub
    sed -i 's#'/tmp/habref'#'$parentdir/tmp/habref'#g' tmp/habref/data_inpn_habref.sql

    write_log "Creating 'habitat' schema..."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/habref/habref.sql &>> var/log/install_db.log

    write_log "Inserting INPN habitat data..."
    sudo -u postgres -s psql -d $db_name  -f tmp/habref/data_inpn_habref.sql &>> var/log/install_db.log


    echo "Getting 'nomenclature' schema creation scripts..."
    wget --no-cache --no-cookies https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/nomenclatures.sql -P tmp/nomenclatures
    wget --no-cache --no-cookies https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/data_nomenclatures.sql -P tmp/nomenclatures
    wget https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/nomenclatures_taxonomie.sql -P tmp/nomenclatures
    wget https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/$nomenclature_release/data/data_nomenclatures_taxonomie.sql -P tmp/nomenclatures

    write_log "Creating 'nomenclatures' schema"

    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/nomenclatures.sql  &>> var/log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/nomenclatures_taxonomie.sql  &>> var/log/install_db.log

    write_log "Inserting 'nomenclatures' data..."

    sudo sed -i "s/MYDEFAULTLANGUAGE/$default_language/g" tmp/nomenclatures/data_nomenclatures.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/data_nomenclatures.sql  &>> var/log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/nomenclatures/data_nomenclatures_taxonomie.sql  &>> var/log/install_db.log

    write_log "Creating 'commons' schema..."
    cp data/core/commons.sql tmp/geonature/commons.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/commons.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/commons.sql  &>> var/log/install_db.log

    write_log "Creating 'meta' schema..."

    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/meta.sql  &>> var/log/install_db.log

    write_log "Creating 'ref_geo' schema..."
    cp data/core/ref_geo.sql tmp/geonature/ref_geo.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/ref_geo.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/ref_geo.sql  &>> var/log/install_db.log

    if [ "$install_sig_layers" = true ];
    then
        write_log "Insert default French municipalities (IGN admin-express)"
        if [ ! -f 'tmp/geonature/communes_fr_admin_express_2019-01.zip' ]
        then
            wget  --cache=off http://geonature.fr/data/ign/communes_fr_admin_express_2019-01.zip -P tmp/geonature
        else
            echo "tmp/geonature/communes_fr_admin_express_2019-01.zip already exist"
        fi
        unzip tmp/geonature/communes_fr_admin_express_2019-01.zip -d tmp/geonature
        sudo -n -u postgres -s psql -d $db_name -f tmp/geonature/fr_municipalities.sql &>> var/log/install_db.log
        write_log "Restore $user_pg owner"
        sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_fr_municipalities OWNER TO $user_pg;" &>> var/log/install_db.log
        write_log "Insert data in l_areas and li_municipalities tables"
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_municipalities.sql  &>> var/log/install_db.log
        write_log "Drop french municipalities temp table"
        sudo -n -u postgres -s psql -d $db_name -c "DROP TABLE ref_geo.temp_fr_municipalities;" &>> var/log/install_db.log
    fi

    if [ "$install_grid_layer" = true ];
    then
        write_log "Insert INPN grids"
        if [ ! -f 'tmp/geonature/inpn_grids.zip' ]
        then
            wget  --cache=off https://geonature.fr/data/inpn/layers/2019/inpn_grids.zip -P tmp/geonature
        else
            echo "tmp/geonature/inpn_grids.zip already exist"
        fi
        unzip tmp/geonature/inpn_grids.zip -d tmp/geonature
        write_log "Insert grid layers... (This may take a few minutes)"
        sudo -n -u postgres -s psql -d $db_name -f tmp/geonature/inpn_grids.sql &>> var/log/install_db.log
        write_log "Restore $user_pg owner"
        sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_grids_1 OWNER TO $user_pg;" &>> var/log/install_db.log
        sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_grids_5 OWNER TO $user_pg;" &>> var/log/install_db.log
        sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_grids_10 OWNER TO $user_pg;" &>> var/log/install_db.log
        write_log "Insert data in l_areas and li_grids tables"
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_grids.sql  &>> var/log/install_db.log
    fi

    if  [ "$install_default_dem" = true ];
    then
        write_log "Insert default French DEM (IGN 250m BD alti)"
        if [ ! -f 'tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip' ]
        then
            wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P tmp/geonature
        else
            echo "tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip already exist"
        fi
	      unzip tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d tmp/geonature
        #gdalwarp -t_srs EPSG:$srid_local tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc tmp/geonature/dem.tif &>> var/log/install_db.log
        export PGPASSWORD=$user_pg_pass;raster2pgsql -s $srid_local -c -C -I -M -d -t 5x5 tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h $db_host -U $user_pg -d $db_name  &>> var/log/install_db.log
    	#echo "Refresh DEM spatial index. This may take a few minutes..."
        sudo -n -u postgres -s psql -d $db_name -c "REINDEX INDEX ref_geo.dem_st_convexhull_idx;" &>> var/log/install_db.log
        if [ "$vectorise_dem" = true ];
        then
            write_log "Vectorisation of DEM raster. This may take a few minutes..."
            sudo -n -u postgres -s psql -d $db_name -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;" &>> var/log/install_db.log
            
            write_log "Refresh DEM vector spatial index. This may take a few minutes..."
            sudo -n -u postgres -s psql -d $db_name -c "REINDEX INDEX ref_geo.index_dem_vector_geom;" &>> var/log/install_db.log
        fi
    fi

    write_log "Creating 'imports' schema..."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/imports.sql  &>> var/log/install_db.log


    write_log "Creating 'synthese' schema..."
    cp data/core/synthese.sql tmp/geonature/synthese.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" tmp/geonature/synthese.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/geonature/synthese.sql  &>> var/log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/synthese_default_values.sql  &>> var/log/install_db.log

    write_log "Creating commons view depending of synthese"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/commons_synthese.sql  &>> var/log/install_db.log

    write_log "Creating 'exports' schema..."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/exports.sql  &>> var/log/install_db.log


    write_log "Creating 'monitoring' schema..."
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -v MYLOCALSRID=$srid_local -f data/core/monitoring.sql  &>> var/log/install_db.log

    write_log "Creating 'permissions' schema"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/permissions.sql  &>> var/log/install_db.log

    write_log "Insert 'permissions' data"
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/permissions_data.sql  &>> var/log/install_db.log

    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/sensitivity.sql  &>> var/log/install_db.log
    
    write_log "Insert 'gn_sensitivity' data"
    echo "--------------------"
    if [ ! -f 'tmp/geonature/181201_referentiel_donnes_sensibles.csv' ]
        then
            wget --cache=off https://geonature.fr/data/inpn/sensitivity/181201_referentiel_donnes_sensibles.csv -P tmp/geonature
        else
            echo "tmp/geonature/181201_referentiel_donnes_sensibles.csv already exist"
    fi
    cp data/core/sensitivity_data.sql tmp/geonature/sensitivity_data.sql
    sed -i 's#'/tmp/geonature'#'$parentdir/tmp/geonature'#g' tmp/geonature/sensitivity_data.sql
    echo "Insert 'gn_sensitivity' data... (This may take a few minutes)"
    sudo -n -u postgres -s psql -d $db_name -f tmp/geonature/sensitivity_data.sql &>> var/log/install_db.log


    #Installation des données exemples
    if [ "$add_sample_data" = true ];
    then
        write_log "Inserting sample datasets..."
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/meta_data.sql  &>> var/log/install_db.log
        
        
        write_log "Inserting sample dataset of taxons for taxonomic schema..."

        wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata_taxons_example.sql -P tmp/taxhub
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f tmp/taxhub/taxhubdata_taxons_example.sql  &>> var/log/install_db.log

    fi

    if [ "$install_default_dem" = true ];
    then
        sudo rm tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc
        sudo rm tmp/geonature/IGNF_BDALTIr_2-0_ASC_250M_LAMB93_IGN69_FRANCE.html
    fi

fi

# Suppression des fichiers : on ne conserve que les fichiers compressés
echo "Cleaning files..."
rm tmp/geonature/*.sql
rm tmp/usershub/*.sql
rm tmp/taxhub/*.txt
rm tmp/taxhub/*.sql
rm tmp/taxhub/*.csv
rm tmp/habref/*.csv
rm tmp/habref/*.pdf
rm tmp/habref/*.sql
rm tmp/nomenclatures/*.sql
