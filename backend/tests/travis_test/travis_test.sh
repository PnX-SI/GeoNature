#!/bin/bash

echo 'FROM TRAViS #########################################'
echo $db_name
echo $db_pass

sudo mkdir /etc/geonature
sudo mkdir /etc/geonature/mods-enabled
sudo mkdir /etc/geonature/mods-available

mkdir $TRAVIS_BUILD_DIR/frontend/src/external_assets

sudo cp $TRAVIS_BUILD_DIR/backend/tests/travis_test/geonature_config_tests.toml $TRAVIS_BUILD_DIR/config/geonature_config.toml

export PGPASSWORD=monpassachanger;psql -U geonatuser -h test.ecrins-parcnational.net -d geonaturedb -c "DELETE FROM gn_commons.t_modules WHERE module_name = 'occtax'"

python ../../../geonature_cmd.py install_command

geonature install_gn_module $TRAVIS_BUILD_DIR/contrib/occtax occtax --build=false








