#/bin/bash

BASE_DIR=$(readlink -e "${0%/*}")

inter="$(dirname "$BASE_DIR")"
geonature_dir="$(dirname "$inter")"

##### Migration SQL #######

. $geonature_dir/config/settings.ini

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f $geonature_dir/data/migrations/2.0.0beta4to2.00beta5.sql  &>> var/log/migration2.0.0beta4_beta5.log

cp $geonature_dir/data/core/synthese.sql /tmp/synthese.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/synthese.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/synthese.sql  &>> var/log/migration2.0.0beta4_beta5.log

cp $geonature_dir/contrib/occtax/data/migration_2.0.0.beta4to2.0.0.beta5.sql /tmp/migration_2.0.0.beta4to2.0.0.beta5.sql
sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/migration_2.0.0.beta4to2.0.0.beta5.sql
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/migration_2.0.0.beta4to2.0.0.beta5.sql  &>> var/log/migration2.0.0beta4_beta5.log


##### Migration arborescence #######


mkdir $geonature_dir/var
mkdir $geonature_dir/var/log


ln -s $geonature_dir/contrib/occtax $geonature_dir/external_modules/occtax

cp /etc/geonature/geonature_config.toml $geonature_dir/config/geonature_config.toml
cp /etc/geonature/mods-enabled/occtax/conf_gn_module.toml $geonature_dir/external_modules/occtax/config/conf_gn_module.toml


sudo rm -r /etc/geonature

sudo cp -r /var/log/geonature $geonature_dir/var/log
sudo chown -R $USER $geonature_dir/var/log/*

cp $geonature_dir/backend/gunicorn_start.sh.sample $geonature_dir/backend/gunicorn_start.sh

rm /tmp/synthese.sql