#!/bin/bash

sudo mkdir /etc/geonature

sudo cp ./geonature_config.toml /etc/geonature_config.toml

python geonature_cmd.py install_command

geonature install_gn_module /home/$(whoami)/GeoNature/contrib/occtax occtax --build=false








