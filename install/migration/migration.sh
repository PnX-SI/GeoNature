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

sudo systemctl stop usershub
sudo systemctl stop taxhub
sudo systemctl stop geonature
sudo systemctl stop geonature-worker

. $myrootpath/geonature_old/config/settings.ini

cp $myrootpath/geonature_old/config/settings.ini config/settings.ini
cp $myrootpath/geonature_old/config/geonature_config.toml config/geonature_config.toml
sk_len=$(grep -E '^SECRET_KEY' config/geonature_config.toml | tail -n 1 | sed 's/SECRET_KEY = ['\''"]\(.*\)['\''"]/\1/' | wc -c)
if [ $sk_len -lt 20 ]; then
    sed -i "s|^SECRET_KEY = .*$|SECRET_KEY = '`openssl rand -hex 32`'|" config/geonature_config.toml
fi

# Handle frontend custom components
echo "Copie des fichiers existant des composants personnalisables du frontend..."
cp -r $myrootpath/geonature_old/frontend/src/custom/* frontend/src/custom/

if [ ! -f $myrootpath/geonature_old/frontend/src/assets/custom.css ]
then
  cp $myrootpath/geonature_old/frontend/src/custom/custom.scss $myrootpath/geonature/frontend/src/assets/custom.css
else 
  cp $myrootpath/geonature_old/frontend/src/assets/custom.css $myrootpath/geonature/frontend/src/assets/custom.css
fi



echo "Création des fichiers des nouveaux composants personnalisables du frontend..."
custom_component_dir="frontend/src/custom/components/"
for file in $(find "${custom_component_dir}" -type f -name "*.sample"); do
	if [[ ! -f "${file%.sample}" ]]; then
		cp "${file}" "${file%.sample}"
	fi
done

if [ -d "${myrootpath}/geonature_old/backend/static/images" ]
then
  cp -r $myrootpath/geonature_old/backend/static/images/* backend/static/images
fi


if [ -d "${myrootpath}/geonature_old/backend/static/mobile" ]
then
  cp -r $myrootpath/geonature_old/backend/static/mobile/* backend/static/mobile
fi
if [ -d "${myrootpath}/geonature_old/backend/static/exports" ]
then
  cp -r $myrootpath/geonature_old/backend/static/exports/* backend/static/exports
fi
cp $myrootpath/geonature_old/frontend/src/favicon.ico frontend/src/favicon.ico
cp -r $myrootpath/geonature_old/external_modules/* external_modules
# On supprime le lien symbolique qui pointe vers geonature_old/contrib/occtax et validation
rm -r external_modules/occtax
rm -r external_modules/validation
rm -r external_modules/occhab
# Rapatrier le fichier de conf de Occtax et de validation
cp $myrootpath/geonature_old/contrib/occtax/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/occtax/config/conf_gn_module.toml
cp $myrootpath/geonature_old/contrib/gn_module_validation/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/gn_module_validation/config/conf_gn_module.toml
cp $myrootpath/geonature_old/contrib/gn_module_occhab/config/conf_gn_module.toml $myrootpath/$currentdir/contrib/gn_module_occhab/config/conf_gn_module.toml

# On recrée le lien symbolique sur le nouveau répertoire de GeoNature
ln -s $myrootpath/$currentdir/contrib/occtax external_modules/occtax
ln -s $myrootpath/$currentdir/contrib/gn_module_validation external_modules/validation
ln -s $myrootpath/$currentdir/contrib/gn_module_occhab external_modules/occhab

cp -r $myrootpath/geonature_old/frontend/src/external_assets/* $myrootpath/$currentdir/frontend/src/external_assets/

# # On recrée le lien symbolique sur le nouveau répertoire geonature
# ln -s $myrootpath/$currentdir/contrib/occtax/frontend/assets $myrootpath/$currentdir/frontend/src/external_assets/occtax

mkdir $myrootpath/$currentdir/var
mkdir $myrootpath/$currentdir/var/log
cp $myrootpath/geonature_old/var/log/gn_errors.log $myrootpath/$currentdir/var/log/


# Création du répertoitre static et rapatriement des médias
if [ ! -d 'backend/static/' ]
then
  mkdir backend/static
fi

if [ ! -d 'backend/static/medias/' ]
then
  mkdir backend/static/medias
fi

if [ -d "${myrootpath}/geonature_old/backend/static/medias" ]
then
  cp -r $myrootpath/geonature_old/backend/static/medias/* backend/static/medias
fi

if [ ! -d 'backend/static/shapefiles/' ]
then
  mkdir backend/static/shapefiles
fi

cd $myrootpath/$currentdir/frontend

export NVM_DIR="$HOME/.nvm"
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install
nvm use
npm ci --only=prod

# Lien symbolique vers le dossier static du backend (pour le backoffice)
ln -s $myrootpath/$currentdir/frontend/node_modules $myrootpath/$currentdir/backend/static

cd $myrootpath/$currentdir/backend

if [ -d 'venv/' ]
then
  sudo rm -rf venv
fi

echo "Installation du virtual env..."
python3 -m venv venv

source venv/bin/activate
pip install --upgrade "pip>=19.3"  # https://www.python.org/dev/peps/pep-0440/#direct-references
pip install -e .. -r requirements.txt
# Installation des dépendances optionnelles
grep -E "^SENTRY_DSN" "$myrootpath/geonature_old/config/geonature_config.toml" > /dev/null && pip install sentry-sdk[flask]
# Installation des dépendances des modules
# Boucle sur les liens symboliques de external_modules
for D in $(find ../external_modules  -type l | xargs readlink) ; do
    # si le lien symbolique exisite
    if [ -e "$D" ] ; then
        echo "Installation du module $D…"
        cd "${D}"
        if [ -f 'setup.py' ]
        then
            pip install -e .
        else
            cd backend
            if [ -f 'requirements.txt' ]
            then
                pip install -r requirements.txt
            fi
            cd ..
        fi
        cd frontend
        if [ -f 'package-lock.json' ]
        then
          npm ci
        elif [ -f 'package.json' ]
        then
          npm install
        fi
        cd ..
    fi
done

cd $myrootpath/$currentdir/


echo "Upgrade database…"
geonature db autoupgrade -x data-directory=tmp/ -x local-srid=$srid_local

echo "Update configurations"
geonature generate_frontend_config
geonature generate_frontend_tsconfig_app
geonature generate_frontend_tsconfig
for D in $(find external_modules -type l) ; do
    # si le lien symbolique exisite
    module_path=$(readlink $D)
    module_code=$(basename $D)
    if [ -e "$module_path" ] ; then
        geonature update-module-configuration "$module_code"
    fi
done

echo "Mise à jour des scripts systemd"
cd $myrootpath/$currentdir/install
./02_configure_systemd.sh
cd $myrootpath/$currentdir/

if [ -f "/var/log/geonature.log" ]; then
    sudo mv /var/log/geonature.log /var/log/geonature/geonature.log
    sudo chown $USER: /var/log/geonature/geonature.log
fi

sudo systemctl start usershub
sudo systemctl start taxhub
sudo systemctl start geonature
sudo systemctl start geonature-worker

deactivate

echo "Rebuild du frontend…"
cd $myrootpath/$currentdir/frontend
nvm use
npm run build


echo "Migration terminée"
