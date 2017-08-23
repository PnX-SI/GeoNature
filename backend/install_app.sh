#!/bin/bash

. ../config/settings.ini

echo "Création du fichier de configuration ..."
if [ ! -f config.py ]; then
  cp config.py.sample config.py
fi

echo "préparation du fichier config.py..."
sed -i "s/SQLALCHEMY_DATABASE_URI = .*$/SQLALCHEMY_DATABASE_URI = \"postgresql:\/\/$user_pg:$user_pg_pass@$db_host:$db_port\/$db_name\"/" config.py

nano config.py

#Installation du virtual env
echo "Installation du virtual env..."
virtualenv venv

if [[ $python_path ]]; then
  virtualenv -p $python_path venv
fi

source venv/bin/activate
pip install -r requirements.txt
deactivate
