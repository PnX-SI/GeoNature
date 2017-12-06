#!/bin/bash

. ./config/settings.ini

cd backend

echo "Création du fichier de configuration ..."
if [ ! -f config.py ]; then
  cp config.py.sample config.py
fi

echo "préparation du fichier config.py..."
sed -i "s/SQLALCHEMY_DATABASE_URI = .*$/SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$user_pg:$user_pg_pass@$db_host:$db_port\/$db_name\"/" config.py

nano config.py

#Virtual env Installation
echo "Installation du virtual env..."
virtualenv venv

if [[ $python_path ]]; then
  virtualenv -p $python_path venv
fi

source venv/bin/activate
pip install -r requirements.txt
deactivate

#Frontend installation

#Node instalation
sudo apt-get install npm
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install 6.11.2

cd ../frontend/src/conf
if [ ! -f app.config.ts ]; then
  cp app.config.sample.ts app.config.ts
fi
nano app.config.ts 

echo "instalation des paquets npm"
cd ../..
npm install -g @angular/cli
npm install
