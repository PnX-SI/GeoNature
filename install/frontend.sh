# frontend.sh

#
# fonction qui crée le fichier external_modules/index.ts
# TODO trouver un moyen de retrouver module_code depuis le frontend
# le mettre dans les package.json ??
#
function create_external_modules_index() {

    GN_DIR=$1
    if [ -z "${GN_DIR}" ]; then
        echo veuillez spécifier le repertoire de geonature
        exit 1
    fi

    cur=$(pwd)

    module_codes=""

    cd ${GN_DIR}/external_modules

    index_file=./index.ts
    echo "// Liste des modules de geonature" > ${index_file}

    for path in $(ls */frontend/app/gnModule.module.ts); do
        module_code_lower=${path%%/*}
        module_code_upper=$(echo ${module_code_lower} | awk '{print toupper($1);}')
        module_codes="${module_codes} ${module_code_upper}"
        echo "import { GeonatureModule as ${module_code_upper} } from './${path%%.ts}';" >> ${index_file}
    done

    echo "" >> ${index_file}
    echo "export default {" >> ${index_file}
    for module_code in $(echo ${module_codes}); do
        echo "  ${module_code}," >> ${index_file}
    done
    echo "};" >> ${index_file}

    cat "${index_file}"
    cd "$cur"

}

