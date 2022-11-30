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

# Copy the custom components
if [[ ! -f src/assets/custom.css ]]; then
  write_log "Création des fichiers de customisation du frontend..."
  cp -n src/assets/custom.sample.css src/assets/custom.css
fi
custom_component_dir="src/custom/components/"
for file in $(find "${custom_component_dir}" -type f -name "*.sample"); do
  if [[ ! -f "${file%.sample}" ]]; then
    cp "${file}" "${file%.sample}"
  fi
done

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