#!/bin/bash

# ce script 

# gestion des assets config + custom


 set -e

FLASKDIR=$(readlink -e "${0%/*}")/..


# test pour les worker
file_test="${FLASKDIR}/frontend/assets_test.txt"
if [ ! -f $file_test ]; then
    echo create_file_test
    touch $file_test
fi

last_update_file_test="$(stat -c %Y $file_test)"
now="$(date +%s)"
let diff="${now}-${last_update_file_test}"
if [ "$diff" -lt 5 ]; then
    exit 0
fi

touch $file_test

# test sur les fichiers nécessaires
required_files="config/geonature_config.toml"
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

# config
geonature_config="${FLASKDIR}/config/geonature_config.toml"
api_config_src="${FLASKDIR}/frontend/src/assets/api.config.json"
api_config_dist="${FLASKDIR}/frontend/dist/assets/api.config.json"
if [ ! -f "${api_config_src}" ] || [ ${geonature_config} -nt ${api_config_src} ]; then
    echo "process assets config"
    echo "$API_ENDPOINT" > "$api_config_src"
    if [ -d ${FLASKDIR}/frontend/dist ]; then
        cp $api_config_src $api_config_dist
    fi
fi

# custom
f_last_modif_custom_config=$(find $FLASKDIR/config/custom -type f -printf '%T@ %p\n' 2> /dev/null | sort -n | tail -1 | cut -f2- -d" ")
f_last_modif_custom_src=$(find $FLASKDIR/frontend/src/custom -type f -printf '%T@ %p\n' 2> /dev/null | sort -n | tail -1 | cut -f2- -d" ")
if [ -z "$f_last_modif_custom_src" ] || [ $f_last_modif_custom_config -nt $f_last_modif_custom_src ]; then
    echo "process assets custom"
    mkdir -p $FLASKDIR/frontend/src/custom
    cp -R $FLASKDIR/config/custom/* $FLASKDIR/frontend/src/custom/.
    if [ -d ${FLASKDIR}/frontend/dist ]; then
        rm -Rf $FLASKDIR/frontend/dist/assets/custom
        cp -R $FLASKDIR/frontend/src/custom $FLASKDIR/frontend/dist/assets/custom
    fi
fi

