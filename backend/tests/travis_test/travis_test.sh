#!/bin/bash

sudo mkdir /etc/geonature
sudo mkdir /etc/geonature/mods-enabled
sudo mkdir /etc/geonature/mods-available

sudo cp ~/PnX-SI/GeoNature/backend/tests/travis_test/geonature_config_tests.toml /etc/geonature/geonature_config.toml

python ../../../geonature_cmd.py install_command

geonature install_gn_module /home/travis/PnX-SI/GeoNature/contrib/occtax occtax --build=false








