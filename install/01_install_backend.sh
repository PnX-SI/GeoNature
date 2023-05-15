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
      "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
      *) set -- "${@}" "${arg}"
    esac
  done

  while getopts "hvxd" option; do
    case "${option}" in
      "h") printScriptUsage ;;
      "v") readonly VERBOSE=true ;;
      "x") readonly DEBUG=true; set -x ;;
      "d") readonly MODE="dev" ;;
      *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
    esac
  done
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "${SCRIPT_DIR}/utils"

parseScriptOptions "${@}"


cd "${BASE_DIR}"

if [ -f config/geonature_config.toml ]; then
  echo "Utilisation du fichier de configuration GeoNature existant"
else
  echo "Création du fichier de configuration GeoNature..."
  cp config/geonature_config.toml.sample config/geonature_config.toml
  echo "Préparation du fichier de configuration..."
  sed -i "s|^SQLALCHEMY_DATABASE_URI = .*$|SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$user_pg:$user_pg_pass@$db_host:$db_port\/$db_name?application_name=geonature\"|" config/geonature_config.toml
  sed -i "s|^URL_APPLICATION = .*$|URL_APPLICATION = '${my_url}geonature'|" config/geonature_config.toml
  sed -i "s|^API_ENDPOINT = .*$|API_ENDPOINT = '${my_url}geonature\/api'|" config/geonature_config.toml
  sed -i "s|^API_TAXHUB = .*$|API_TAXHUB = '${my_url}taxhub\/api'|" config/geonature_config.toml
  sed -i "s|^DEFAULT_LANGUAGE = .*$|DEFAULT_LANGUAGE = '${default_language}'|" config/geonature_config.toml
  sed -i "s|^SECRET_KEY = .*$|SECRET_KEY = '`openssl rand -hex 32`'|" config/geonature_config.toml
fi

cd "${BASE_DIR}"/backend

# Installation du virtual env
if [ ! -d 'venv/' ]; then
  echo "Création du virtual env…"
  python3 -m venv venv
fi

echo "Activation du virtual env..."
source venv/bin/activate


echo "Installation des dépendances Python..."
pip install --upgrade "pip>=19.3"  "wheel"  # https://www.python.org/dev/peps/pep-0440/#direct-references
if [[ "${MODE}" == "dev" ]]; then
  echo "Installation des dépendances Python de l'environnement de DEV..."
  git submodule status | grep -E "^-" >/dev/null
  if [ $? -eq 0 ]; then
      echo "Des sous-modules non initialisés ont été trouvés."
      echo "Avez-vous lancé 'git submodule init && git submodule update' ?"
      exit 1
  fi
  pip install -e "${BASE_DIR}"[tests] -r requirements-dev.txt
else
  pip install -e "${BASE_DIR}" -r requirements.txt
fi

readonly BIN_VENV_DIR="${BASE_DIR}/backend/venv/bin"
readonly ACTIVATE_FILE="${BIN_VENV_DIR}/activate"
readonly COMPLETION_FILE_NAME="geonature_completion"

echo "Génération du fichier d’autocomplétion de la commande Geonature…"
_GEONATURE_COMPLETE=bash_source geonature > "${BIN_VENV_DIR}/${COMPLETION_FILE_NAME}"

echo "Modification du script 'activate' du virtual env pour sourcer le fichier d'autocomplétion de la commande GeoNature..."
if ! grep -q "${COMPLETION_FILE_NAME}" "${ACTIVATE_FILE}" ; then
  cp "${ACTIVATE_FILE}" "${ACTIVATE_FILE}.save-$(date +'%F')"
  cat >> "${ACTIVATE_FILE}" << EOF

# GeoNature command completion
if [[ -f "\${VIRTUAL_ENV}/bin/${COMPLETION_FILE_NAME}" ]]; then
  source "\${VIRTUAL_ENV}/bin/${COMPLETION_FILE_NAME}"
fi
EOF
fi

# QUESTION VINCENT : pourquoi install paquets npm dans script install backend
echo "Installation des paquets npm"
cd "${BASE_DIR}/frontend"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use || exit 1
cd "${BASE_DIR}/backend/static"
npm ci || exit 1
