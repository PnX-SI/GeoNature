#! /bin/sh
echo "Nom de la base de données entrypoint"
echo $db_name

rm -rf external_modules/occtax

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


echo "SQLALCHEMY_DATABASE_URI = 'postgresql://$user_pg:$user_pg_pass@$db_host:$db_port/$db_name'" > config/geonature_config.toml
echo "URL_APPLICATION = 'http://${HOST_FRONT}'" >> config/geonature_config.toml
echo "API_ENDPOINT = 'http://${HOST}/geonature/api'" >> config/geonature_config.toml
echo "API_TAXHUB = 'http://${HOST}/taxhub/api'" >> config/geonature_config.toml
echo "APPLICATION_ROOT = '/geonature/api'" >> config/geonature_config.toml
echo "DEFAULT_LANGUAGE = '${default_language}'" >> config/geonature_config.toml
echo "LOCAL_SRID = '${srid_local}'" config/geonature_config.toml
echo "SECRET_KEY = '${SECRET_KEY}'" >> config/geonature_config.toml

cat config/geonature_config.toml.docker >> config/geonature_config.toml

#if [[ " ${$MODULE_LIST[*]} " =~ " contrib/gn_monitoring " ]]; then
cp contrib/gn_monitoring/config/conf_gn_module.toml.example contrib/gn_monitoring/config/conf_gn_module.toml
#fi
cd backend

echo "Installation du backend geonature..."
echo $BASE_DIR
echo $PWD
pip install --editable "${BASE_DIR}"  # geonature ne support pas encore autre chose que editable




echo "Création du fichier de log des erreurs GeoNature"
# Cela évite sa création par Supervisor avec des droits root
# Voir : https://github.com/Supervisor/supervisor/issues/123
  touch "${BASE_DIR}/var/log/gn_errors.log"

DIR=$(readlink -e "${0%/*}")

#TODO add back logs with a volume:
# echo "Création de la rotation des logs à l'aide de Logrotate"
#sudo cp "${assets_install_dir}/log_rotate" "/etc/logrotate.d/geonature"
#sudo -s sed -i "s%{{APP_PATH}}%${BASE_DIR}%" "/etc/logrotate.d/geonature"
#sudo -s sed -i "s%{{USER}}%${USER:=$(/usr/bin/id -run)}%" "/etc/logrotate.d/geonature"
#sudo -s sed -i "s%{{GROUP}}%${USER}%" "/etc/logrotate.d/geonature"
#sudo logrotate -f "/etc/logrotate.conf"

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
if [ "$INSTALL_IMPORT" = true ];
  then
    geonature install_gn_module "${BASE_DIR}/contrib/gn_module_import" /import --build=false
fi
  if [ "$INSTALL_EXPORT" = true ];
  then
    geonature install_gn_module "${BASE_DIR}/contrib/gn_module_export" /export --build=false
fi
if [ "$INSTALL_DASHBOARD" = true ];
  then
    geonature install_gn_module "${BASE_DIR}/contrib/gn_module_dashboard" /dashboard --build=false
fi
if [ "$INSTALL_MONITORING" = true ];
  then
    geonature install_gn_module "${BASE_DIR}/contrib/gn_monitoring" /monitorings --build=false
fi
# Préparation du frontend

# Lien symbolique vers le dossier static du backend (pour le backoffice)
ln -sf "${BASE_DIR}/frontend/node_modules" "${BASE_DIR}/backend/static"

cd "${BASE_DIR}/frontend"

# Creation du dossier des assets externes
mkdir -p "src/external_assets"


# Copy the custom components
echo "Création des fichiers de customisation du frontend..."
if [ ! -f src/assets/custom.css ]; then
  cp -n src/assets/custom.sample.css src/assets/custom.css
fi


# Generate the tsconfig.json
geonature generate_frontend_tsconfig
# Generate the src/tsconfig.app.json
geonature generate_frontend_tsconfig_app
# Generate the modules routing file by templating
geonature generate_frontend_modules_route

# Retour à la racine de GeoNature

if [ "$BUILD_FRONT" = true ]; then
  cd /GeoNature/frontend;
  cp src/custom/components/footer/footer.component.html.sample src/custom/components/footer/footer.component.html
  cp src/custom/components/footer/footer.component.ts.sample src/custom/components/footer/footer.component.ts
  cp src/custom/components/introduction/introduction.component.html.sample src/custom/components/introduction/introduction.component.html
  cp src/custom/components/introduction/introduction.component.ts.sample src/custom/components/introduction/introduction.component.ts
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
  cd /GeoNature/
fi

exec gunicorn "geonature:create_app()"  -w 4  -b 0.0.0.0:80 #-n "${app_name}" #https://testdriven.io/blog/dockerizing-flask-with-postgres-gunicorn-and-nginx/

