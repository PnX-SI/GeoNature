#/bin/bash

BASE_DIR=$(readlink -e "${0%/*}")

inter="$(dirname "$BASE_DIR")"
geonature_dir="$(dirname "$inter")"


mkdir $geonature_dir/external_modules
mkdir $geonature_dir/var
mkdir $geonature_dir/var/log


ln -s $geonature_dir/contrib/occtax $geonature_dir/external_modules/occtax

cp /etc/geonature/geonature_config.toml $geonature_dir/config/geonature_config.toml
cp /etc/geonature/mods-enabled/occtax/conf_gn_module.toml $geonature_dir/external_modules/occtax/conf_gn_module.toml


sudo rm -r /etc/geonature

sudo cp -r /var/log/geonature $geonature_dir/var/log
sudo chown -R $USER $geonature_dir/var/log/*

cp $geonature_dir/backend/gunicorn_start.sh.sample $geonature_dir/backend/gunicorn_start.sh