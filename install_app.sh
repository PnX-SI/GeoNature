#!/bin/bash

. ./config/settings.ini

cd backend

echo "Création du fichier de configuration ..."
if [ ! -f config.py ]; then
  cp config.py.sample config.py
fi


echo "préparation du fichier config.py..."
my_url="${my_url//\//\\/}"
sed -i "s/SQLALCHEMY_DATABASE_URI = .*$/SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$user_pg:$user_pg_pass@$db_host:$db_port\/$db_name\"/" config.py
sed -i "s/URL_APPLICATION = .*$/URL_APPLICATION = '${my_url}geonature' /g" config.py
sed -i "s/API_ENDPOINT = .*$/API_ENDPOINT = '${my_url}geonature\/api'/g" config.py
nano config.py

#Virtual env Installation
echo "Installation du virtual env..."



if [[ $python_path ]]; then
  virtualenv -p $python_path venv
else
  virtualenv venv
fi

source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

#Lancement de l'application
cd ..
BASE_DIR=$(readlink -e "${0%/*}")
cd backend
DIR=$(readlink -e "${0%/*}")
cp gunicorn_start.sh.sample gunicorn_start.sh
sudo -s sed -i "s%APP_PATH%${BASE_DIR}%" gunicorn_start.sh
sudo -s cp geonature-service.conf /etc/supervisor/conf.d/
sudo -s sed -i "s%APP_PATH%${DIR}%" /etc/supervisor/conf.d/geonature-service.conf

sudo -s supervisorctl reread
sudo -s supervisorctl reload


#Frontend installation
#Node and npm instalation
cd ../frontend
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
export NVM_DIR="$HOME/.nvm"
 [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 8.1.1

echo " ############"
echo "instalation des paquets npm"
npm install
echo " ############"
echo "instalation global d'angular cli"
npm install -g @angular/cli@1.6.1
npm rebuild node-sass

if [ ! -f src/conf/app.config.ts ]; then
  cp src/conf/app.config.sample.ts src/conf/app.config.ts
fi

if [ ! -f src/custom/custom.scss ]; then
  cp src/custom/custom.scss.sample src/custom/custom.scss
fi

# copy the custom components 
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


sed -i "s/URL_APPLICATION: .*$/URL_APPLICATION: '${my_url}geonature\/',/g" src/conf/app.config.ts
sed -i "s/API_ENDPOINT: .*$/API_ENDPOINT: '${my_url}geonature\/api\/',/g" src/conf/app.config.ts
sed -i "s/API_TAXHUB: .*$/API_TAXHUB: '${my_url}taxhub\/api\/',/g" src/conf/app.config.ts

nano src/conf/app.config.ts 

ng build --prod --aot=false --base-href=/geonature/
