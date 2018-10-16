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
cp $myrootpath/geonature_old/frontend/src/conf/map.config.ts frontend/src/conf/map.config.ts
cp -r $myrootpath/geonature_old/frontend/src/custom/* frontend/src/custom/
cp -r $myrootpath/geonature_old/external_modules/* external_modules
# On supprime le lien symbolique qui pointe vers geonature_old/contrib/occtax
rm -r external_modules/occtax
# Rapatrier le fichier de conf de Occtax
cp $myrootpath/geonature_old/contrib/occtax/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/occtax/config/conf_gn_module.toml
# on recrée le lien symbolique sur le nouveau répertoire de GeoNature
ln -s $myrootpath/$currentdir/contrib/occtax external_modules/occtax

cp -r $myrootpath/geonature_old/frontend/src/external_assets/* $myrootpath/$currentdir/frontend/src/external_assets/
# on supprime le lien symbolique qui pointe vers geonature_old/contrib/occtax/frontend/assets
rm frontend/src/external_assets/occtax
# on recrée le lien symbolique sur le nouveau répertoire geonature
ln -s $myrootpath/$currentdir/contrib/occtax/frontend/assets $myrootpath/$currentdir/frontend/src/external_assets/occtax


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
npm install

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
geonature generate_frontend_tsconfig
geonature update_module_configuration occtax

sudo supervisorctl reload

deactivate
