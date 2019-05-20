
currentdir=${PWD##*/}

. ../../config/settings.ini

# Make sure root cannot run our script
if [ "$(id -u)" == "0" ]; then
   echo "This script must NOT be run as root" 1>&2
   exit 1
fi

mkdir -p /tmp/geonature

echo "Upgrade database schema"
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f 2.0.1to2.1.0.sql

echo "Creating 'gn_sensitivity' schema"
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ../core/sensitivity.sql
echo "Insert 'gn_sensitivity' data"
wget --cache=off https://geonature.fr/data/inpn/sensitivity/181201_referentiel_donnes_sensibles.csv -P /tmp/geonature
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f ../core/sensitivity_data.sql
