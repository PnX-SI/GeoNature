#!/bin/bash

#settings.ini file path. Default value overwriten by settings-path parameter
cd ../
SETTINGS='config/settings.ini'
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"
case $key in
    -s|--settings-path)
    SETTINGS="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--dev)
    MODE='dev'
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo ""
    echo "Help for install_app.sh command script."
    echo ""
    echo ""
    echo "Option order matters. Give it in this exact order. All options are optional."
    echo ""
    echo "-s OR --settings-path to give the path of the settings file. "
    echo ""
    echo "-d OR --dev to additionnally install python dev requirements."
    echo ""
    exit
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# import settings file
. ${SETTINGS}

BASE_DIR=$(readlink -e "${0%/*}")

if [ ! -d 'tmp/geonature/' ]
then
  mkdir tmp/geonature
  chmod -R 775 tmp/geonature
fi

if [ ! -d 'tmp/taxhub/' ]
then
  mkdir tmp/taxhub
  chmod -R 775 tmp/taxhub
fi

if [ ! -d 'tmp/usershub/' ]
then
  mkdir tmp/usershub
  chmod -R 775 tmp/usershub
fi

if [ ! -d 'var' ]
then
  mkdir var
fi

if [ ! -d 'var/log' ]
then
  mkdir var/log
  chmod -R 775 var/log/
fi


if [ ! -f config/geonature_config.toml ]; then
  echo "Création du fichier de configuration ..."
  sudo cp config/geonature_config.toml.sample config/geonature_config.toml
  echo "préparation du fichier de configuration..."
  echo $my_url
  my_url="${my_url//\//\\/}"
  echo $my_url
  sudo sed -i "s/SQLALCHEMY_DATABASE_URI = .*$/SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$user_pg:$user_pg_pass@$db_host:$db_port\/$db_name\"/" config/geonature_config.toml
  sudo sed -i "s/URL_APPLICATION = .*$/URL_APPLICATION = '${my_url}geonature' /g" config/geonature_config.toml
  sudo sed -i "s/API_ENDPOINT = .*$/API_ENDPOINT = '${my_url}geonature\/api'/g" config/geonature_config.toml
  sudo sed -i "s/API_TAXHUB = .*$/API_TAXHUB = '${my_url}taxhub\/api'/g" config/geonature_config.toml
  sudo sed -i "s/DEFAULT_LANGUAGE = .*$/DEFAULT_LANGUAGE = '${default_language}'/g" config/geonature_config.toml
  sudo sed -i "s/LOCAL_SRID = .*$/LOCAL_SRID = '${srid_local}'/g" config/geonature_config.toml
else
  echo "Le fichier de configuration existe déjà"
fi

cd backend


#Installation du virtual env
# Suppression du venv s'il existe
if [ -d 'venv/' ]
then
  echo "Suppression du virtual env existant..."
  sudo rm -rf venv
fi

if [[ $python_path ]]; then
  echo "Installation du virtual env..."
  virtualenv -p $python_path venv
else
  virtualenv venv
fi

echo "Activation du virtual env..."
source venv/bin/activate
echo "Installation des dépendances python..."
pip install --upgrade pip
pip install -r requirements.txt
if [[ $MODE == "dev" ]]
then
  pip install -r requirements-dev.txt
fi
echo "Création des commandes 'geonature'..."
python ${BASE_DIR}/geonature_cmd.py install_command
echo "Création de la configuration du frontend depuis 'config/geonature_config.toml'..."
geonature generate_frontend_config --conf-file ${BASE_DIR}/config/geonature_config.toml --build=false

#Lancement de l'application
echo "Configuration de l'application api backend dans supervisor..."
DIR=$(readlink -e "${0%/*}")
cp gunicorn_start.sh.sample gunicorn_start.sh
sudo -s sed -i "s%APP_PATH%${BASE_DIR}%" gunicorn_start.sh
sudo -s cp geonature-service.conf /etc/supervisor/conf.d/
sudo -s sed -i "s%APP_PATH%${DIR}%" /etc/supervisor/conf.d/geonature-service.conf

echo "Lancement de l'application api backend..."
sudo -s supervisorctl reread
sudo -s supervisorctl reload


#Frontend installation
#Node and npm instalation
echo "Instalation de npm"
cd ../frontend
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
export NVM_DIR="$HOME/.nvm"
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 8.1.1

echo " ############"
echo "Instalation des paquets npm"
npm install

# creation du dossier des assets externes
mkdir src/external_assets

# creation du map config
if [ ! -f src/conf/map.config.ts ]; then
  cp src/conf/map.config.ts.sample src/conf/map.config.ts
fi

# copy the custom components
echo "Création des fichiers de customisation du frontend..."
if [ ! -f src/custom/custom.scss ]; then
  cp src/custom/custom.scss.sample src/custom/custom.scss
fi

if [ ! -f src/custom/components/footer/footer.component.ts ]; then
  cp src/custom/components/footer/footer.component.ts.sample src/custom/components/footer/footer.component.ts
fi
if [ ! -f src/custom/components/footer/footer.component.html ]; then
  cp src/custom/components/footer/footer.component.html.sample src/custom/components/footer/footer.component.html
fi
if [ ! -f src/custom/components/introduction/introduction.component.ts ]; then
  cp src/custom/components/introduction/introduction.component.ts.sample src/custom/components/introduction/introduction.component.ts
fi
if [ ! -f src/custom/components/introduction/introduction.component.html ]; then
  cp src/custom/components/introduction/introduction.component.html.sample src/custom/components/introduction/introduction.component.html
fi


#generate the tsconfig.json 
geonature generate_frontend_tsconfig
# generate the modules routing file by templating
geonature generate_frontend_modules_route


cd /home/$monuser/geonature
# installation du module occtax
source backend/venv/bin/activate
geonature install_gn_module /home/$monuser/geonature/contrib/occtax occtax --build=false

cd frontend
echo "Build du frontend..."
npm rebuild node-sass --force

npm run build

echo "désactiver le virtual env"
deactivate
