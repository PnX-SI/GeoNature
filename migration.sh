#!/bin/bash


cp ../geonature_old/config/settings.ini config/settings.ini
cp ../geonature_old/frontend/src/conf/map.config.ts frontend/src/conf/map.config.ts
cp -r ../geonature_old/frontend/src/custom/* frontend/src/custom/

# Création du répertoitre statci et rapattriement des médias
if [ ! -d 'backend/static/' ]
then
  mkdir static
fi

if [ ! -d 'backend/static/medias/' ]
then
  mkdir ./static/medias
fi
cp -r ../geonature_old/backend/static/medias/* backend/static/medias

if [ ! -d 'backend/static/shapefiles/' ]
then
  mkdir backend/static/shapefiles
fi



. config/settings.ini

cd frontend
npm install

cd ../backend

if [ -d 'venv/' ]
then
  sudo rm -rf venv
fi

if [[ $python_path ]]; then
  echo "Installation du virtual env..."
  virtualenv -p $python_path venv
else
  virtualenv venv
fi


source venv/bin/activate
pip install -r requirements.txt

python ../geonature_cmd.py install_command

echo "Update configurations "
geonature update_configuration --build=false
geonature generate_frontend_config --build=false
geonature generate_frontend_modules_route
geonature generate_frontend_tsconfig
geonature update_module_configuration occtax --build=false


echo "Rebuild du frontend"
cd ../frontend
npm run build
cd ../

sudo supervisorctl reload

deactivate
