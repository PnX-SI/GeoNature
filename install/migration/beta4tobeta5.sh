#/bin/bash

BASE_DIR=$(readlink -e "${0%/*}")

inter="$(dirname "$BASE_DIR")"
geonature_dir="$(dirname "$inter")"

echo $geonature_dir


cp /etc/geonature/geonature_config.toml $geonature_dir/config/geonature_config.toml
cp /etc/geonature/mods-enabled/occtax/conf_gn_module.toml $geonature_dir/external_modules/occtax/conf_gn_module.toml

cp -r $geonature_dir/contrib/occtax $geonature_dir/external_modules/occtax