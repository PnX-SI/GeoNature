#!/bin/bash
parentdir="$(dirname "$(pwd)")"
currentdir=${PWD##*/} 
myrootpath=`pwd`/..

echo 'You are executing this script FROM '`pwd`' AND your oldgeonature directory is in '$parentdir'/geonature_old'
read -p "Press any key to exit. Press Y or y to continue."  choice
echo 
if [ $choice ] 
then
  if [ $choice != 'y' ] && [ $choice != 'Y' ] && [ $choice ]
  then
    echo "Exit"
    exit
  fi
else
  echo "Exit"
  exit
fi

echo "OK, let's migrate GeoNature version..."

. $myrootpath/geonature_old/config/settings.ini

cp $myrootpath/geonature_old/config/settings.ini config/settings.ini
cp $myrootpath/geonature_old/config/geonature_config.toml config/geonature_config.toml
cp -r $myrootpath/geonature_old/frontend/src/custom/* frontend/src/custom/
cp $myrootpath/geonature_old/frontend/src/favicon.ico frontend/src/favicon.ico
cp -r $myrootpath/geonature_old/external_modules/* external_modules
# On supprime le lien symbolique qui pointe vers geonature_old/contrib/occtax et validation
rm -r external_modules/occtax
rm -r external_modules/validation
# Rapatrier le fichier de conf de Occtax et de validation
cp $myrootpath/geonature_old/contrib/occtax/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/occtax/config/conf_gn_module.toml
cp $myrootpath/geonature_old/contrib/gn_module_validation/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/gn_module_validation/config/conf_gn_module.toml

# on supprime le lien symbolique qui pointe vers geonature_old/contrib/occtax/frontend/assets
rm $myrootpath/$currentdir/frontend/src/external_assets/occtax
rm $myrootpath/$currentdir/frontend/src/external_assets/validation

# on recrée le lien symbolique sur le nouveau répertoire de GeoNature
ln -s $myrootpath/$currentdir/contrib/occtax external_modules/occtax
ln -s $myrootpath/$currentdir/contrib/gn_module_validation external_modules/validation

cp -r $myrootpath/geonature_old/frontend/src/external_assets/* $myrootpath/$currentdir/frontend/src/external_assets/

# # on recrée le lien symbolique sur le nouveau répertoire geonature
# ln -s $myrootpath/$currentdir/contrib/occtax/frontend/assets $myrootpath/$currentdir/frontend/src/external_assets/occtax


mkdir $myrootpath/$currentdir/var
mkdir $myrootpath/$currentdir/var/log

# Création du répertoitre static et rapatriement des médias
if [ ! -d 'backend/static/' ]
then
  mkdir backend/static
fi

if [ ! -d 'backend/static/medias/' ]
then
  mkdir backend/static/medias
fi
cp -r $myrootpath/geonature_old/backend/static/medias/* backend/static/medias

if [ ! -d 'backend/static/shapefiles/' ]
then
  mkdir backend/static/shapefiles
fi


cd $myrootpath/$currentdir/frontend

export NVM_DIR="$HOME/.nvm"
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 10.15.3

npm install --only=prod

# lien symbolique vers le dossier static du backend (pour le backoffice)
ln -s $myrootpath/$currentdir/frontend/node_modules $myrootpath/$currentdir/backend/static


cd $myrootpath/$currentdir/backend

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

echo "Update configurations"
geonature update_configuration --build=false
#geonature generate_frontend_config --build=false
geonature generate_frontend_modules_route
geonature generate_frontend_tsconfig_app
geonature generate_frontend_tsconfig
geonature update_module_configuration occtax --build=false
geonature update_module_configuration validation --build=false

geonature frontend_build

sudo supervisorctl reload

deactivate
