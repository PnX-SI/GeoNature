
currentdir=${PWD##*/}

# faux sudo car sinon la commande "sudo -n -u" ne le demande pas
sudo ls

. ../../config/settings.ini

touch ../../var/log/migration_2.0.1_to_2.1.0.log

# retour a la racine
cd ../../

# Make sure root cannot run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi

mkdir -p /tmp/geonature

echo "Upgrade database schema"
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/migrations/2.0.1to2.1.0.sql &> var/log/migration_2.0.1_to_2.1.0.log

echo "Creating 'gn_sensitivity' schema"
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/sensitivity.sql &>> var/log/migration_2.0.1_to_2.1.0.log
echo "Insert 'gn_sensitivity' data"
wget --cache=off https://geonature.fr/data/inpn/sensitivity/181201_referentiel_donnes_sensibles.csv -P tmp/geonature
sudo -n -u postgres -s psql -d $db_name -f data/core/sensitivity_data.sql &>> var/log/migration_2.0.1_to_2.1.0.log


# si no grid on exit
if [ "$1" = 'no-grid' ];
  then
  exit 1
fi



# insertion des mailles
echo "Insert INPN grids"
echo "" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "--------------------" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "Insert INPN grids" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "--------------------" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "" &>> var/log/migration_2.0.1_to_2.1.0.log
if [ ! -f 'tmp/geonature/inpn_grids.zip' ]
then
    wget  --cache=off https://geonature.fr/data/inpn/layers/2019/inpn_grids.zip -P tmp/geonature
else
    echo "tmp/geonature/inpn_grids.zip already exist"
fi
unzip tmp/geonature/inpn_grids.zip -d tmp/geonature
echo "Insert grid layers... (This may take a few minutes)"
sudo -n -u postgres -s psql -d $db_name -f tmp/geonature/inpn_grids.sql &>> var/log/migration_2.0.1_to_2.1.0.log
echo "" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "Restore $user_pg owner" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "--------------------" &>> var/log/migration_2.0.1_to_2.1.0.log
sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_grids_1 OWNER TO $user_pg;" &>> var/log/migration_2.0.1_to_2.1.0.log
sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_grids_5 OWNER TO $user_pg;" &>> var/log/migration_2.0.1_to_2.1.0.log
sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_grids_10 OWNER TO $user_pg;" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "Insert data in l_areas and li_grids tables" &>> var/log/migration_2.0.1_to_2.1.0.log
echo "--------------------" &>> var/log/migration_2.0.1_to_2.1.0.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/ref_geo_grids.sql  &>> var/log/migration_2.0.1_to_2.1.0.log
