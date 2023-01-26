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

# Create external assets directory
cd "${BASE_DIR}/frontend"
mkdir -p "src/external_assets"

# create config.json
if [[ ! -f src/assets/config.json ]]; then
  write_log "Création des fichiers de configuration du frontend"
  cp -n src/assets/config.sample.json src/assets/config.json
fi
api_end_point=$(geonature get-config API_ENDPOINT)
echo "REMPLACE API ENDPOINT"
echo $api_end_point
sed -i 's|"API_ENDPOINT": .*$|"API_ENDPOINT" : "'${api_end_point}'"|' src/assets/config.json
cat src/assets/config.json
# Copy the custom components
if [[ ! -f src/assets/custom.css ]]; then
  write_log "Création des fichiers de customisation du frontend..."
  cp -n src/assets/custom.sample.css src/assets/custom.css

fi

if [[ -z "${CI}" || "${CI}" == false ]] ; then
  echo "Activation du venv..."
  source "${BASE_DIR}/backend/venv/bin/activate"

  echo "Création de la configuration du frontend depuis 'config/geonature_config.toml'..."
  # Generate the app.config.ts
  geonature generate-frontend-config

  echo "Désactivation du venv..."
  deactivate
fi

if [[ "${CI}" == true ]] ; then
  echo "Cypress dans Github action se charge de lancer Npm build et install"
  exit 0
fi

echo "Installation de nvm"
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install

# Frontend installation
echo "Installation des paquets Npm"
cd "${BASE_DIR}/frontend"
nvm use || exit 1
if [[ "${MODE}" == "dev" ]]; then
  npm ci || exit 1
else
  npm ci --omit=dev || exit 1
fi
cd "${BASE_DIR}/backend/static"
npm ci || exit 1

cd "${BASE_DIR}/frontend"


if [[ "${MODE}" != "dev" ]]; then
  echo "Build du frontend..."
  npm run build || exit 1
fi
