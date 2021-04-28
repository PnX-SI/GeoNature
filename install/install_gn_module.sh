#
#
# on passe en script la commande qui permet d'installer un module
#
# ARGS : 
#   $1 : chemin vers le dossier du module (absolu)
#   $2 : module_path
#   $3 : bdd|app|, on peut préciser si on installe la bdd, l'applicatif ou les deux

#
#  TODO
#  
#  
#  Version packagés
set -e

FLASKDIR=$(readlink -e "${0%/*}")/..


function printScriptUsage() {
    echo "
Aide pour le script install_gn_module.sh

Liste des options :

--module-directory, -d : chemin absolu vers le module
--module-path, -p : chemin du module dans geonature (par défaut module_code.lower())
--bdd-only, -b : installe le module en base de donnée seulement
--app-only, -a : installe le module en applicatif seulement
--index-only, -i : recrée le fichier external_module seulement
--no-build, -n : ne contruit pas le frontend

exemple

./install_gn_module.sh -d <GN>/contrib/occtax
"
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--app-only") set -- "${@}" "-a" ;;
            "--bdd-only") set -- "${@}" "-b" ;;
            "--module-directory") set -- "${@}" "-d" ;;
            "--index-only") set -- "${@}" "-i" ;;
            "--help") set -- "${@}" "-h" ;;
            "--no-build") set -- "${@}" "-n" ;;
            "--module-path") set -- "${@}" "-p" ;;
            "--"*) echo "ERROR : parameter '${arg}' invalid ! Use -h option to know more."; printScriptUsage; exit 1;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "abd:hip:n" option; do
        case "${option}" in
            "a") app_only=true ;;
            "b") bdd_only=true ;;
            "d") module_directory="${OPTARG}";;
            "h") printScriptUsage ;;
            "i") index_only=true ;;
            "n") no_build=true ;;
            "p") module_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
        esac
    done
}


# # DESC : cree le fichier module.code.config.ts
# function process_frontend_config() {
#     module_code_=$(get_module_code ${module_directory})
#     echo "--- Création du fichier frontend/app/module.code.config.ts"
#     echo "export const MODULE_CODE = '${module_code}';" > ${module_directory}/frontend/app/module.code.config.ts
# }


# DESC : cree le fichier index.ts qui liste les différentes modules externes
function process_module_index() {
    echo "---- Routing external_modules.ts"
    import=""
    modules=""
    index_ts=$FLASKDIR/frontend/src/app/routing/external_modules.ts
    for module in $(ls $FLASKDIR/frontend/node_modules/ | grep gn_module_); do
        module_code_=$(get_module_code $FLASKDIR/frontend/node_modules/$module)
        if [ -z "$module_code_" ]; then
            continue
        fi
        module_code_lower_=$(echo $module_code_ | tr '[:upper:]' '[:lower:]')
        imports="${imports}import { GeonatureModule as ${module_code_} } from '@librairies/${module}/app/gnModule.module';
"
        modules="${modules}
    ${module_code_},"   
    done
    echo "$imports
export const externalModules = {$modules
};
" > $index_ts
}

# DESC : Récupère le code du module
# ARGS: $1 : module_directory
function get_module_code() {
  module_directory_=$1
  manifest="${module_directory_}/manifest.toml"
  init="${module_directory_}/backend/gn_module_*/__init__.py"
  module_code_config=${module_directory_}/app/module.code.config.ts

  if [ -f "${manifest}" ]; then
    cat ${manifest} | grep module_code | sed -e "s/module_code *= *//" -e "s/'//g"
    return 0
  elif ls $init &> /dev/null; then
    cat $init | grep MODULE_CODE | sed -e "s/MODULE_CODE *=//" -e "s/'//g" -e "s/ //g"
    return 0
  elif [ -f ${module_code_config} ]; then
    cat $module_code_config | sed -e "s/export const MODULE_CODE *=//" -e "s/[' ;]//g"
    return 0
  fi
}

################################################
# MAIN
################################################

# Gestion des options
parseScriptOptions "${@}"

cur=$(pwd)

# Si options --index-only ou -i
# On refait le fichier external_modules.ts pour les modules 
if [ ! -z "$index_only" ]; then
    process_module_index
    exit 0
fi


# Test : $module_directory correct ?
if [ ! -d "$module_directory" ]; then
    echo "
- ! Le chemin vers le répertoire du module n'existe pas ($module_path),
--> Veuillez utiliser l'option -d ou --module-directory pour le préciser"
    exit 1
fi

# recuperation de 'module_code'
module_code=$(get_module_code "$module_directory")


# tests
if [ -z "${module_code}" ]; then
    echo "- ! La variable 'module_code' n'a pas été trouvée pour ce module"
    exit 1
fi

module_code_lower=$(echo $module_code | tr '[:upper:]' '[:lower:]')

log_file=$FLASKDIR/var/log/install_gn_module_$module_code_lower.log

if [ -z "$module_path" ]; then 
    module_path=$module_code_lower
fi

echo ""
echo "- Installation du module ${module_code}"

echo "-- Lien symbolique vers external_modules/${module_code_lower}"
ln -nsf ${module_directory} ${FLASKDIR}/external_modules/${module_code_lower}


# Installation du module : Applicatif
if [ -z "$bdd_only" ]; then
    echo "-- APP"

    # install_app.sh
    if [ -f $module_directory/install_app.sh ]; then
        echo "--- install_app.sh"
        $module_directory/install_app.sh $FLASKDIR
    fi

    echo "--- Backend"

    if [ -f ${module_directory}/manifest.toml ]; then

        # - backend
        echo "---- Non-packaged module"

        requirements=${module_directory}/backend/requirements.txt
        if  [ -f ${requirements} ]; then 
            echo "---- requirements.txt"
            source ${FLASKDIR}/backend/venv/bin/activate
            pip install -r ${requirements} &> $log_file
            deactivate
        fi
    elif [ -f ${module_directory}/setup.py ]; then
        echo "---- Packaged module"
        source ${FLASKDIR}/backend/venv/bin/activate
        pip install -e  $module_directory &> $log_file
    fi

    # - frontend

    # - lien symbolique dans external module
    if [ -f ${module_directory}/frontend/assets ]; then 
        ln -nsf ${module_directory}/frontend/assets ${FLASKDIR}/frontend/src/external_assets/${module_code_lower}
    fi
        
    # -- npm install
    if [ -f $module_directory/frontend/package.json ]; then 
        cd ${FLASKDIR}/frontend
        echo "--- Frontend"
        echo "---- npm install"
        # npm install --no-save $module_directory/frontend &> $log_file
        cd $cur
    fi 

    # -- external_modules.ts
    process_module_index

    echo "--- Config ${module_code_lower}_config.toml" 
    # - creation fichier de config
    config_file=$FLASKDIR/config/modules/${module_code_lower}_config.toml
    touch $config_file

    echo "-- APP ok"

fi

# Installation du module : Base de données
if [ -z "$app_only" ]; then
    echo "-- BDD"

    install_db_file=$FLASKDIR/external_modules/$module_code_lower/install_db.sh

    if [ -f $module_directory/setup.py ]; then
        echo "--- alembic"
        source $FLASKDIR/backend/venv/bin/activate
        export FLASK_APP=geonature.app;
        flask db upgrade gn_module_${module_code_lower}@head -d $FLASKDIR/backend/geonature/migrations
        deactivate
        cd $cur
    else 
        echo "--- register module"
        . $FLASKDIR/config/settings.ini
        export PGPASSWORD=$user_pg_pass;
        psql -h $db_host -U $user_pg -d $db_name -c "
        INSERT INTO gn_commons.t_modules(
            module_code, module_label, module_picto, module_desc, module_path, active_frontend, active_backend
        )
        VALUES(
            '${module_code}',
            '${module_code_lower}',
            'fa-puzzle-piece',
            '',
            '${module_path}',
            true,
            true
        )
        " &> $log_file
        if [ -f ${install_db_file} ]; then
            echo "--- install_db.sh"
            ${install_db_file} $FLASKDIR $>$log_file
        fi
    fi
    echo "-- BDD ok"


fi
