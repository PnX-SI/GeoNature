#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config/settings.ini

function database_exists () {
    # /!\ Will return false if psql can't list database. Edit your pg_hba.conf
    # as appropriate.
    if [ -z $1 ]
        then
        # Argument is null
        return 0
    else
        # Grep db name in the list of database
        sudo -n -u postgres -s -- psql -tAl | grep -q "^$1|"
        return $?
    fi
}


if database_exists $db_name
then
        if $drop_apps_db
            then
            echo "Drop database..."
            sudo -n -u postgres -s dropdb $db_name
        else
            echo "Database exists but the settings file indicate that we don't have to drop it."
        fi
fi

if [ ! -d "log" ]; then
    mkdir log
fi

if ! database_exists $db_name
then
    echo "Creating GeoNature database..."
    echo "--------------------" &> log/install_db.log
    echo "Creating GeoNature database" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s createdb -O $user_pg $db_name
    echo "Adding PostGIS and PLPGSQL extensions..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Adding PostGIS and PLPGSQL extensions" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' &>> log/install_db.log


    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "GRANT..."
    cp data/grant.sql /tmp/grant.sql
    sudo sed -i "s/MYPGUSER/$user_pg/g" /tmp/grant.sql
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "GRANT" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -f /tmp/grant.sql &>> log/install_db.log

    echo "Creating 'public' functions..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'public' functions" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/public.sql  &>> log/install_db.log

    echo "Getting and creating USERS schema (utilisateurs)..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating USERS schema (utilisateurs)" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    wget https://raw.githubusercontent.com/PnEcrins/UsersHub/$usershub_release/data/usershub.sql -P /tmp/
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/usershub.sql  &>> log/install_db.log


    echo "Download and extract taxref file..."
    cd data/taxonomie/inpn

    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/inpn/data_inpn_v9_taxhub.sql

    array=( TAXREF_INPN_v9.0.zip    ESPECES_REGLEMENTEES_20161103.zip    LR_FRANCE_20160000.zip )
    for i in "${array[@]}"
    do
      if [ ! -f '/tmp/'$i ]
      then
          wget http://geonature.fr/data/inpn/taxonomie/$i -P /tmp
      else
          echo $i exists
      fi
    done
    unzip /tmp/TAXREF_INPN_v9.0.zip -d /tmp
    unzip /tmp/ESPECES_REGLEMENTEES_20161103.zip -d /tmp
    unzip /tmp/LR_FRANCE_20160000.zip -d /tmp
    cd ..

    echo "Getting 'taxonomie' schema creation scripts..."
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdb.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata_taxon_example.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/materialized_views.sql
    cd ../..

    echo "Creating 'taxonomie' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'taxonomie' schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/taxhubdb.sql  &>> log/install_db.log

    echo "Inserting INPN taxonomic data... (This may take a few minutes)"
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Inserting INPN taxonomic data" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -f data/taxonomie/inpn/data_inpn_v9_taxhub.sql &>> log/install_db.log

    echo "Creating dictionaries data for taxonomic schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating dictionaries data for taxonomic schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/taxhubdata.sql  &>> log/install_db.log

    echo "Inserting sample dataset of taxons for taxonomic schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Inserting sample dataset of taxons for taxonomic schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/taxhubdata_taxon_example.sql  &>> log/install_db.log

    echo "Creating a view that represent the taxonomic hierarchy..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating a view that represent the taxonomic hierarchy" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/materialized_views.sql  &>> log/install_db.log


    echo "Creating 'nomenclatures' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'nomenclatures' schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/nomenclatures.sql  &>> log/install_db.log

    echo "Inserting 'nomenclatures' data..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Inserting 'nomenclatures' data" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    cp data/core/data_nomenclatures.sql /tmp/data_nomenclatures.sql
    sudo sed -i "s/MYDEFAULTLANGUAGE/$default_language/g" /tmp/data_nomenclatures.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/data_nomenclatures.sql  &>> log/install_db.log

    echo "Creating 'meta' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'meta' schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/meta.sql  &>> log/install_db.log

    echo "Creating 'ref_geo' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'ref_geo' schema..." &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    cp data/core/ref_geo.sql /tmp/ref_geo.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/ref_geo.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/ref_geo.sql  &>> log/install_db.log

    if $install_sig_layers
    then
        echo "Insert default French municipalities (IGN admin-express)"
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Insert default French municipalities (IGN admin-express)" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        if [ ! -f '/tmp/communes_fr_admin_express_2017-06.zip' ]
        then
            wget  --cache=off http://geonature.fr/data/ign/communes_fr_admin_express_2017-06.zip -P /tmp
        else
            echo "/tmp/communes_fr_admin_express_2017-06.zip already exist"
        fi
        unzip /tmp/communes_fr_admin_express_2017-06.zip -d /tmp
        sudo -n -u postgres -s psql -d $db_name -f /tmp/fr_municipalities.sql &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "Restore $user_pg owner" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_fr_municipalities OWNER TO $user_pg;" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "Insert data in l_areas and li_municipalities tables" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_data.sql  &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "Drop french municipalities temp table" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        sudo -n -u postgres -s psql -d $db_name -c "DROP TABLE ref_geo.temp_fr_municipalities;" &>> log/install_db.log
    fi

    if $install_default_dem
    then
        echo "Insert default French DEM (IGN 250m BD alti)"
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Insert default French DEM (IGN 250m BD alti)" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        if [ ! -f '/tmp/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip' ]
        then
            wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P /tmp
        else
            echo "/tmp/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip already exist"
        fi
	      unzip /tmp/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d /tmp
        #gdalwarp -t_srs EPSG:$srid_local /tmp/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc /tmp/dem.tif &>> log/install_db.log
        export PGPASSWORD=$user_pg_pass;raster2pgsql -s $srid_local -c -C -I -M -d -t 100x100 /tmp/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h $db_host -U $user_pg -d $db_name  &>> log/install_db.log
    	  echo "Vectorisation of dem raster. This may take a few minutes..."
        sudo -n -u postgres -s psql -d $db_name -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;" &>> log/install_db.log
        echo "Refresh dem vector spatial index. This may take a few minutes..."
        sudo -n -u postgres -s psql -d $db_name -c "REINDEX INDEX ref_geo.index_dem_vector_geom;" &>> log/install_db.log
    fi


    echo "Creating 'medias' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'medias' schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/medias.sql  &>> log/install_db.log


    echo "Creating 'synthese' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'synthese' schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    cp data/core/synthese.sql /tmp/synthese.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/synthese.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/synthese.sql  &>> log/install_db.log


    echo "Creating 'exports' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'exports' schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/exports.sql  &>> log/install_db.log


    echo "Creating 'gn_users' schema..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Creating 'gn_users' schema" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/gn_users.sql  &>> log/install_db.log


    # Suppression des fichiers : on ne conserve que les fichiers compressés
    echo "Cleaning files..."
    rm /tmp/*.txt
    rm /tmp/*.csv
    rm /tmp/usershub.sql
    rm data/taxonomie/taxhubdb.sql
    rm data/taxonomie/materialized_views.sql
    rm data/taxonomie/taxhubdata.sql
    rm data/taxonomie/taxhubdata_taxon_example.sql
    rm data/taxonomie/inpn/data_inpn_v9_taxhub.sql
    rm /tmp/fr_municipalities.sql
    rm /tmp/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc
    rm /tmp/IGNF_BDALTIr_2-0_ASC_250M_LAMB93_IGN69_FRANCE.html
    # rm /tmp/dem.tif

    echo "Permission on log folder..."
    chmod -R 777 log
fi
