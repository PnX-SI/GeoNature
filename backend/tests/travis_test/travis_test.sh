#!/bin/bash

sudo mkdir /etc/geonature
sudo mkdir /etc/geonature/mods-enabled
sudo mkdir /etc/geonature/mods-available

mkdir $TRAVIS_BUILD_DIR/frontend/src/external_assets

sudo cp $TRAVIS_BUILD_DIR/backend/tests/travis_test/geonature_config_tests.toml $TRAVIS_BUILD_DIR/config/geonature_config.toml

python ../../../geonature_cmd.py install_command

geonature install_gn_module $TRAVIS_BUILD_DIR/contrib/occtax occtax --build=false








