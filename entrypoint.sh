#!/bin/bash

echo "Nom de la base de données entrypoint"
echo $db_name
my_domain=$(echo $my_url | sed -r 's|^.*\/\/(.*)$|\1|')
my_domain=$(echo $my_domain | sed s'/.$//')

my_url=$my_url
proxy_http=
proxy_https=
BASE_DIR=$PWD

cd $BASE_DIR
#Flask

if [ ! -d 'var' ]
then
  mkdir var
fi

if [ ! -d 'var/log' ]
then
  mkdir var/log
  chmod -R 775 var/log/
fi


echo "Création du fichier de configuration  et préparation du fichier de configuration..."
if [ "$FLASK_ENV" = production ];
then
  sh config/config_from_env.sh
else
  sh config/config_from_env_local.sh
fi

cd backend
echo "Installation du backend geonature..."

pip install --editable "${BASE_DIR}"  # geonature ne support pas encore autre chose que editable


DIR=$(readlink -e "${0%/*}")

##TODO add back logs with a volume:
# echo "Création de la rotation des logs à l'aide de Logrotate"
#cp "/GeoNature/install/assests/log_rotate" "/etc/logrotate.d/geonature"
#sed -i "s%{{APP_PATH}}%${BASE_DIR}%" "/etc/logrotate.d/geonature"
#sed -i "s%{{USER}}%${USER:=$(/usr/bin/id -run)}%" "/etc/logrotate.d/geonature"
#sed -i "s%{{GROUP}}%${USER}%" "/etc/logrotate.d/geonature"
#logrotate -f "/etc/logrotate.conf"

# Get usershub's migrations
wget "https://github.com/PnX-SI/UsersHub/archive/refs/tags/${usershub_release}.zip"
unzip "${usershub_release}.zip"
cp -r "UsersHub-${usershub_release}/app/migrations"  /GeoNature/tmp
rm "${usershub_release}.zip"
rm -r "UsersHub-${usershub_release}"
if [ "$INSTALL_DB" = true ];
then
  cd $BASE_DIR/install/
  chmod +x add_extensions.sh
  ./add_extensions.sh
  cd $BASE_DIR
fi
echo "Migration de la base de donées Alembic"
geonature db upgrade geonature@head -x data-directory=tmp/ -x local-srid=$srid_local
geonature db autoupgrade -x data-directory=tmp/ -x local-srid=$srid_local
if [ "$INSTALL_DB" = true ];
  echo "installing inital data"
    then
    cd $BASE_DIR/install/
    chmod +x install_initial_data.sh
    ./install_initial_data.sh
    sed -i "s/$INSTALL_DB/false/g" $BASE_DIR/.env.local
  fi
cd $BASE_DIR
echo "Lancement de l'application api backend..."
geonature generate_frontend_config --build=false

cd "${BASE_DIR}"

geonature install_packaged_gn_module "${BASE_DIR}/contrib/occtax" OCCTAX --build=false
if [ "$add_sample_data" = true ];
then
    geonature db upgrade occtax-samples@head
fi
if [ "$INSTALL_OCCHAB" = true ];
  then
  geonature install_packaged_gn_module "${BASE_DIR}/contrib/gn_module_occhab" OCCHAB --build=false
    if [ "$add_sample_data" = true ];
    then
        geonature db upgrade occhab-samples@head
    fi
fi
if [ "$INSTALL_VALIDATION" = true ];
  then
    geonature install_packaged_gn_module "${BASE_DIR}/contrib/gn_module_validation" VALIDATION --build=false
fi



# Retour à la racine de GeoNature

if [ "$BUILD_FRONT" = true ]; then
  # Lien symbolique vers le dossier static du backend (pour le backoffice)
  ln -sf "${BASE_DIR}/frontend/node_modules" "${BASE_DIR}/backend/static"

  cd /GeoNature/frontend;

  # Creation du dossier des assets externes
  mkdir -p "src/external_assets"


  # Copy the custom components
  echo "Création des fichiers de customisation du frontend..."
  if [ ! -f src/assets/custom.css ]; then
    cp -n src/assets/custom.sample.css src/assets/custom.css
  fi

  #TODO Remove or do only if necessary
  # Generate the tsconfig.json
  geonature generate_frontend_tsconfig
  # Generate the src/tsconfig.app.json
  geonature generate_frontend_tsconfig_app
  # Generate the modules routing file by templating
  geonature generate_frontend_modules_route
  cd /GeoNature/frontend;

  # Create custom files if not exist
  custom_component_dir="src/custom/components/"
  for file in $(find "${custom_component_dir}" -type f -name "*.sample"); do
    echo $file
    if [ ! -f "${file%.sample}" ]; then
      cp "${file}" "${file%.sample}"
    fi
  done

  #Regenerate config
  cd /GeoNature/external_modules
  for file in *;
  do
    if [ ! -f "${file}/frontend/app/module.config.ts" ]; then
      geonature update_module_configuration $file --build False
    fi
  done
  cd /GeoNature/frontend
  npm install . --legacy-peer-deps
  for module in $MODULE_LIST;
  do
    cd /GeoNature/"${module}";
    cd frontend;
    npm install .;
  done
  cd /GeoNature/frontend
  npm run build
  rm -r build/build-front${PLATEFORM_NAME}
  mv dist/ build/build-front${PLATEFORM_NAME}
  cd /GeoNature/
fi

exec gunicorn "geonature:create_app()"  -w 4  -b 0.0.0.0:80 --log-file /var/log/geonature.log  #-n "${app_name}" #https://testdriven.io/blog/dockerizing-flask-with-postgres-gunicorn-and-nginx/

