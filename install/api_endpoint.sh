#!/bin/bash

# Ce script permet de gérer automatiquemet les assets du frontend suivant : 
# 
# - le fichier api.config.json qui permet au frontend de connaitre la valeur de API_ENDPOINT
#
# Ce script permet de modifier automatiquement ce fichier dans le frontend (dans les src et les dist)
# Il est appelé au demarrage de l'application
# 
# Cela permet de pouvoir construire (en frontend et backend) une application indépendament de la configuration et de la customisation
# Cette dernière peut être définie au dernier moment, juste avant le lancement de l'application.
#

 set -e

FLASKDIR=$(readlink -e "${0%/*}")/..

################################################
# I ) - test sur les fichiers nécessaires
#
# On teste ici si les fichiers nécessaire sont présents
# et si API_ENDPOINT est bien défini
#
################################################

# test sur les fichiers nécessaires
required_files="config/geonature_config.toml config/settings.ini"
missing_files=""

for f in $(echo ${required_files}); do
    if [ ! -f "${FLASKDIR}/$f" ]; then
        missing_files="$missing_files $f"
    fi
done

if [ ! -z "$missing_files" ]; then
    echo "Veuillez vous assurer de la présence des fichiers suivants : "
    for f in $(echo $missing_files); do 
        echo $f
    done
    exit 1
fi 

API_ENDPOINT=$(cat $FLASKDIR/config/geonature_config.toml | grep API_ENDPOINT | sed -e "s/API_ENDPOINT *=//" -e "s/[ ']//g" ) 

if  [ -z "${API_ENDPOINT}" ]; then 
    echo "La variable API_ENDPOINT n'a pas été trouvée dans le fichier ${FLASKDIR}/config/geonature_config.toml"
fi


################################################
# II ) - api.config
################################################

geonature_config="${FLASKDIR}/config/geonature_config.toml"
api_config_src="${FLASKDIR}/frontend/src/assets/api.config.json"
api_config_dist="${FLASKDIR}/frontend/dist/assets/api.config.json"
if [ ! -f "${api_config_src}" ] || [ ${geonature_config} -nt ${api_config_src} ]; then
    echo "process assets config"
    echo "\"$API_ENDPOINT\"" > "$api_config_src"
    if [ -d ${FLASKDIR}/frontend/dist ]; then
        cp $api_config_src $api_config_dist
    fi
fi
