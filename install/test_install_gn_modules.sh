set -e 

FLASKDIR=$(readlink -e "${0%/*}")/..

# reset app
rm -f $FLASKDIR/external_modules/*
rm -f $FLASKDIR/config/occtax_config.toml
rm -f $FLASKDIR/config/occhab_config.toml
rm -f $FLASKDIR/config/validation_config.toml
rm -f $FLASKDIR/config/monitorings_config.toml

rm -f $FLASKDIR/frontend/src/external_assets/*

# reset db
. $FLASKDIR/config/settings.ini
export PGPASSWORD=$user_pg_pass;
psql -h $db_host -U $user_pg -d $db_name -c "
DELETE FROM gn_commons.cor_module_dataset; 
DELETE FROM gn_commons.t_modules WHERE module_code IN ('VALIDATION', 'OCCTAX', 'OCCHAB', 'MONITORINGS');
DROP SCHEMA IF EXISTS pr_occtax CASCADE;
DROP SCHEMA IF EXISTS pr_occhab CASCADE;
"

modules="contrib/occtax contrib/gn_module_occhab contrib/gn_module_validation ../gn_module_monitoring"
# modules="../gn_module_monitoring"


# install app
for module_directory in $(echo "$modules"); do
    $FLASKDIR/install/install_gn_module.sh -d $FLASKDIR/$module_directory --app-only --no-build
done

# install db
for module_directory in $(echo "$modules"); do
    $FLASKDIR/install/install_gn_module.sh -d $FLASKDIR/$module_directory --bdd-only
done

# cd $FLASKDIR/frontend
# npm run build
