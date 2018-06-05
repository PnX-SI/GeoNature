#!/bin/bash

cp config/settings.ini ../GeoNature/config/settings.ini
cp frontend/src/conf/map.config.ts ../GeoNature/frontend/src/conf/map.config.ts
cp -r frontend/src/custom/* ../GeoNature/frontend/src/custom/
cp -r frontend/src/custom/* ../GeoNature/frontend/src/custom/
cp -r frontend/src/custom/* ../GeoNature/frontend/src/custom/


mv geonature/ geonature_old
mv GeoNature geonature



. config/settings.ini

cd backend

if [[ $python_path ]]; then
  echo "Installation du virtual env..."
  virtualenv -p $python_path venv
else
  virtualenv venv
fi

source venv/bin/activate

geonature update_configuration
geonature generate_frontend_config --build=false
geonature generate_frontend_modules_route
geonature generate_frontend_tsconfig
geonature update_module_configuration occtax --build=false

pip install -r requirements.txt


cd geonature/frontend
npm install
npm run build
cd ../

sudo supervisorctl reload