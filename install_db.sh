#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config/settings.ini

if [ ! -d '/tmp/geonature/' ]
then
  mkdir /tmp/geonature
  chmod -R 775 /tmp/geonature
fi

if [ ! -d '/tmp/taxhub/' ]
then
  mkdir /tmp/taxhub
  chmod -R 775 /tmp/taxhub
fi

if [ ! -d '/tmp/usershub/' ]
then
  mkdir /tmp/usershub
  chmod -R 775 /tmp/usershub
fi

if [ ! -d '/var/log/geonature/' ]
then
  sudo mkdir /var/log/geonature
  sudo chown "$(id -u)" /var/log/geonature
  chmod -R 775 /var/log/geonature
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

if ! database_exists $db_name
then
    echo "Creating GeoNature database..."
    echo "--------------------" &> /var/log/geonature/install_db.log
    echo "Creating GeoNature database" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    sudo -n -u postgres -s createdb -O $user_pg $db_name
    echo "Adding PostGIS and PLPGSQL extensions..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Adding PostGIS and PLPGSQL extensions" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;" &>> /var/log/geonature/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';" &>> /var/log/geonature/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' &>> /var/log/geonature/install_db.log


    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "GRANT..."
    cp data/grant.sql /tmp/geonature/grant.sql
    sudo sed -i "s/MYPGUSER/$user_pg/g" /tmp/geonature/grant.sql
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "GRANT" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    sudo -n -u postgres -s psql -d $db_name -f /tmp/geonature/grant.sql &>> /var/log/geonature/install_db.log

    echo "Creating 'public' functions..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'public' functions" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/public.sql  &>> /var/log/geonature/install_db.log

    echo "Getting and creating USERS schema (utilisateurs)..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating USERS schema (utilisateurs)" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    wget https://raw.githubusercontent.com/PnEcrins/UsersHub/$usershub_release/data/usershub.sql -P /tmp/usershub
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/usershub/usershub.sql  &>> /var/log/geonature/install_db.log


    echo "Download and extract taxref file..."

    # Create log directory for taxhub
    if [ ! -d '/var/log/taxhub/' ]
        then
        sudo mkdir -p /var/log/taxhub
        sudo chown -R "$(id -u)" /var/log/taxhub
        chmod -R 775 /var/log/taxhub
    fi

    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/inpn/data_inpn_taxhub.sql -P /tmp/taxhub

    array=( TAXREF_INPN_v11.zip ESPECES_REGLEMENTEES_v11.zip LR_FRANCE_20160000.zip )
    for i in "${array[@]}"
    do
      if [ ! -f '/tmp/taxhub/'$i ]
      then
          wget http://geonature.fr/data/inpn/taxonomie/$i -P /tmp/taxhub
      else
          echo $i exists
      fi
      unzip /tmp/taxhub/$i -d /tmp/taxhub
    done

    echo "Getting 'taxonomie' schema creation scripts..."
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdb.sql -P /tmp/taxhub
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata.sql -P /tmp/taxhub
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata_taxon_example.sql -P /tmp/taxhub
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/materialized_views.sql -P /tmp/taxhub

    echo "Creating 'taxonomie' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'taxonomie' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/taxhub/taxhubdb.sql  &>> /var/log/geonature/install_db.log

    echo "Inserting INPN taxonomic data... (This may take a few minutes)"
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Inserting INPN taxonomic data" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    sudo -n -u postgres -s psql -d $db_name -f /tmp/taxhub/data_inpn_taxhub.sql &>> /var/log/geonature/install_db.log

    echo "Creating dictionaries data for taxonomic schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating dictionaries data for taxonomic schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/taxhub/taxhubdata.sql  &>> /var/log/geonature/install_db.log

    echo "Inserting sample dataset of taxons for taxonomic schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Inserting sample dataset of taxons for taxonomic schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/taxhub/taxhubdata_taxon_example.sql  &>> /var/log/geonature/install_db.log

    echo "Creating a view that represent the taxonomic hierarchy..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating a view that represent the taxonomic hierarchy" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/taxhub/materialized_views.sql  &>> /var/log/geonature/install_db.log


    echo "Creating 'nomenclatures' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'nomenclatures' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/nomenclatures.sql  &>> /var/log/geonature/install_db.log

    echo "Inserting 'nomenclatures' data..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Inserting 'nomenclatures' data" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    cp data/core/data_nomenclatures.sql /tmp/geonature/data_nomenclatures.sql
    sudo sed -i "s/MYDEFAULTLANGUAGE/$default_language/g" /tmp/geonature/data_nomenclatures.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/geonature/data_nomenclatures.sql  &>> /var/log/geonature/install_db.log

    echo "Creating 'meta' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "CreatingInstall_ 'meta' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/meta.sql  &>> /var/log/geonature/install_db.log

    echo "Creating 'ref_geo' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'ref_geo' schema..." &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    cp data/core/ref_geo.sql /tmp/geonature/ref_geo.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/geonature/ref_geo.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/geonature/ref_geo.sql  &>> /var/log/geonature/install_db.log

    if $install_sig_layers
    then
        echo "Insert default French municipalities (IGN admin-express)"
        echo "" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "Insert default French municipalities (IGN admin-express)" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        if [ ! -f '/tmp/geonature/communes_fr_admin_express_2017-06.zip' ]
        then
            wget  --cache=off http://geonature.fr/data/ign/communes_fr_admin_express_2017-06.zip -P /tmp/geonature
        else
            echo "/tmp/geonature/communes_fr_admin_express_2017-06.zip already exist"
        fi
        unzip /tmp/geonature/communes_fr_admin_express_2017-06.zip -d /tmp/geonature
        sudo -n -u postgres -s psql -d $db_name -f /tmp/geonature/fr_municipalities.sql &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "Restore $user_pg owner" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_fr_municipalities OWNER TO $user_pg;" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "Insert data in l_areas and li_municipalities tables" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_data.sql  &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "Drop french municipalities temp table" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        sudo -n -u postgres -s psql -d $db_name -c "DROP TABLE ref_geo.temp_fr_municipalities;" &>> /var/log/geonature/install_db.log
    fi

    if $install_default_dem
    then
        echo "Insert default French DEM (IGN 250m BD alti)"
        echo "" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "Insert default French DEM (IGN 250m BD alti)" &>> /var/log/geonature/install_db.log
        echo "--------------------" &>> /var/log/geonature/install_db.log
        echo "" &>> /var/log/geonature/install_db.log
        if [ ! -f '/tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip' ]
        then
            wget --cache=off http://geonature.fr/data/ign/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -P /tmp/geonature
        else
            echo "/tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip already exist"
        fi
	      unzip /tmp/geonature/BDALTIV2_2-0_250M_ASC_LAMB93-IGN69_FRANCE_2017-06-21.zip -d /tmp/geonature
        #gdalwarp -t_srs EPSG:$srid_local /tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc /tmp/geonature/dem.tif &>> /var/log/geonature/install_db.log
        export PGPASSWORD=$user_pg_pass;raster2pgsql -s $srid_local -c -C -I -M -d -t 100x100 /tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc ref_geo.dem|psql -h $db_host -U $user_pg -d $db_name  &>> /var/log/geonature/install_db.log
    	  echo "Vectorisation of dem raster. This may take a few minutes..."
        sudo -n -u postgres -s psql -d $db_name -c "INSERT INTO ref_geo.dem_vector (geom, val) SELECT (ST_DumpAsPolygons(rast)).* FROM ref_geo.dem;" &>> /var/log/geonature/install_db.log
        echo "Refresh dem vector spatial index. This may take a few minutes..."
        sudo -n -u postgres -s psql -d $db_name -c "REINDEX INDEX ref_geo.index_dem_vector_geom;" &>> /var/log/geonature/install_db.log
    fi


    echo "Creating 'medias' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'medias' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/medias.sql  &>> /var/log/geonature/install_db.log


    echo "Creating 'synthese' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'synthese' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    cp data/core/synthese.sql /tmp/geonature/synthese.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/geonature/synthese.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/geonature/synthese.sql  &>> /var/log/geonature/install_db.log


    echo "Creating 'exports' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'exports' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/exports.sql  &>> /var/log/geonature/install_db.log


    echo "Creating 'monitoring' schema..."
    echo "" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "Creating 'monitoring' schema" &>> /var/log/geonature/install_db.log
    echo "--------------------" &>> /var/log/geonature/install_db.log
    echo "" &>> /var/log/geonature/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/monitoring.sql  &>> /var/log/geonature/install_db.log

    # Suppression des fichiers : on ne conserve que les fichiers compressés
    echo "Cleaning files..."
    sudo rm /tmp/geonature/*.sql
    sudo rm /tmp/usershub/*.sql
    sudo rm /tmp/taxhub/*.txt
    sudo rm /tmp/taxhub/*.sql
    sudo rm /tmp/taxhub/*.csv
    
    if $install_default_dem
    then
        sudo rm /tmp/geonature/BDALTIV2_250M_FXX_0098_7150_MNT_LAMB93_IGN69.asc
        sudo rm /tmp/geonature/IGNF_BDALTIr_2-0_ASC_250M_LAMB93_IGN69_FRANCE.html
    fi
fi
