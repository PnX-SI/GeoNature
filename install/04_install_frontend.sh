#!/bin/bash

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
  cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -d | --dev: use GeoNature in development mode.
     -c | --ci: install for CI needs.
EOF
  exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
  # Transform long options to short ones
  for arg in "${@}"; do
    shift
    case "${arg}" in
      "--help") set -- "${@}" "-h" ;;
      "--verbose") set -- "${@}" "-v" ;;
      "--debug") set -- "${@}" "-x" ;;
      "--dev") set -- "${@}" "-d" ;;
      "--ci") set -- "${@}" "-c" ;;
      "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
      *) set -- "${@}" "${arg}"
    esac
  done

  while getopts "hvxdc" option; do
    case "${option}" in
      "h") printScriptUsage ;;
      "v") readonly VERBOSE=true ;;
      "x") readonly DEBUG=true; set -x ;;
      "c") readonly CI=true;;
      "d") readonly MODE="dev" ;;
      *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
    esac
  done
}


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"

parseScriptOptions "${@}"




write_log "Préparation du frontend..."

cd "${BASE_DIR}/frontend"

echo "Activation du venv..."
source "${BASE_DIR}/backend/venv/bin/activate"

# Lien symbolique vers le dossier static du backend (pour le backoffice)
ln -sf "${BASE_DIR}/frontend/node_modules" "${BASE_DIR}/backend/static"

# Creation du dossier des assets externes
mkdir -p "src/external_assets"

# Copy the custom components
if [ ! -f src/assets/custom.css ]; then
  write_log "Création des fichiers de customisation du frontend..."
  cp -n src/assets/custom.sample.css src/assets/custom.css
fi
custom_component_dir="src/custom/components/"
for file in $(find "${custom_component_dir}" -type f -name "*.sample"); do
  if [[ ! -f "${file%.sample}" ]]; then
    cp "${file}" "${file%.sample}"
  fi
done


if ! ${CI};then
  echo "Création de la configuration du frontend depuis 'config/geonature_config.toml'..."
  # Generate the app.config.ts
  geonature generate_frontend_config --build=false
  # Generate the tsconfig.json
  geonature generate_frontend_tsconfig
  # Generate the src/tsconfig.app.json
  geonature generate_frontend_tsconfig_app
  # Generate the modules routing file by templating
  geonature generate_frontend_modules_route
fi

# echo "Désactivation du venv..."
# deactivate

# Frontend installation"
 
cd "${BASE_DIR}/frontend"
echo " ############"
echo "Installation des paquets Npm"

# build and npm install is done by cypress github action
if $CI; then
  exit 0
fi

if [[ "${MODE}" == "dev" ]]; then
  npm install --production=false || exit 1
else 
  npm ci --only=prod --legacy-peer-deps || exit 1
fi


if [[ "${MODE}" != "dev" ]]; then
  echo "Build du frontend..."
  npm rebuild node-sass --force || exit 1
  npm run build || exit 1
fi