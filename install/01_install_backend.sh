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
  echo "Utilisation du fichier de configuration GeoNature exisant"
else
  echo "Création du fichier de configuration GeoNature..."
  cp config/geonature_config.toml.sample config/geonature_config.toml
  echo "Préparation du fichier de configuration..."
  sed -i "s|^SQLALCHEMY_DATABASE_URI = .*$|SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$user_pg:$user_pg_pass@$db_host:$db_port\/$db_name\"|" config/geonature_config.toml
  sed -i "s|^URL_APPLICATION = .*$|URL_APPLICATION = '${my_url}geonature'|" config/geonature_config.toml
  sed -i "s|^API_ENDPOINT = .*$|API_ENDPOINT = '${my_url}geonature\/api'|" config/geonature_config.toml
  sed -i "s|^API_TAXHUB = .*$|API_TAXHUB = '${my_url}taxhub\/api'|" config/geonature_config.toml
  sed -i "s|^SECRET_KEY = .*$|SECRET_KEY = '`openssl rand -hex 16`'|" config/geonature_config.toml
  sed -i "s|^LOCAL_SRID = .*$|LOCAL_SRID = '${srid_local}'|" config/geonature_config.toml
  sed -i "s|^DEFAULT_LANGUAGE = .*$|DEFAULT_LANGUAGE = '${default_language}'|" config/geonature_config.toml
fi

cd "${BASE_DIR}"/backend

# Installation du virtual env
# Suppression du venv s'il existe
if [ -d 'venv/' ]; then
  echo "Suppression du virtual env existant..."
  rm -rf venv
fi
echo "Création du virtual env…"
python3 -m venv venv


echo "Ajout de l'autocomplétion de la commande GeoNature au virtual env..."
readonly BIN_VENV_DIR="${BASE_DIR}/backend/venv/bin"
readonly ACTIVATE_FILE="${BIN_VENV_DIR}/activate"
readonly ASSETS_INSTALL_DIR="${BASE_DIR}/install/assets"
readonly SRC_COMPLETION_FILE="${ASSETS_INSTALL_DIR}/geonature_bash_completion.sh"
readonly COMPLETION_FILE_NAME="geonature_completion"
if [ ! -f "${BIN_VENV_DIR}/${COMPLETION_FILE_NAME}" ]; then
  cp "${SRC_COMPLETION_FILE}" "${BIN_VENV_DIR}/${COMPLETION_FILE_NAME}"
fi
if ! grep -q "${COMPLETION_FILE_NAME}" "${ACTIVATE_FILE}" ; then
  cp "${ACTIVATE_FILE}" "${ACTIVATE_FILE}.save-$(date +'%f')"
  cat >> "${ACTIVATE_FILE}" << EOF

# GeoNature command completion
source "\${VIRTUAL_ENV}/bin/${COMPLETION_FILE_NAME}"
EOF
fi


echo "Activation du virtual env..."
source venv/bin/activate


echo "Installation des dépendances Python..."
pip install --upgrade "pip>=19.3"  # https://www.python.org/dev/peps/pep-0440/#direct-references
if [[ "${MODE}" == "dev" ]]; then
  echo "Installation des dépendances Python de l'environnement de DEV..."
  pip install -r requirements-common.txt -r requirements-submodules.txt
else
  pip install -r requirements.txt
fi

echo "Installation du backend geonature..."
pip install --editable "${BASE_DIR}"


echo "Installation du service-file systemd…"
envsubst '${USER} ${BASE_DIR}' < "${BASE_DIR}/install/assets/geonature.service" | sudo tee /etc/systemd/system/geonature.service && sudo systemctl daemon-reload || exit 1
if [[ "${MODE}" != "dev" ]]; then
  echo "Activation de geonature au démarrage…"
  sudo systemctl enable geonature || exit 1
fi

echo "Vous pouvez maintenant démarrer GeoNature avec la commande : sudo systemctl start geonature"
