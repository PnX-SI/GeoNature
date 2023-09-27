#!/usr/bin/env bash

. settings.ini
# export all variable in settings.ini
# -> they are available in python os.environ
export $(grep -i --regexp ^[a-z] settings.ini | cut -d= -f1)
export TABLE_DONNEES_INPN CHAMP_ID_CA CHAMP_ID_JDD DELETE_XML_FILE_AFTER_IMPORT

sudo apt-get install virtualenv

if [ -d 'venv/' ]
then
  echo "Suppression du virtual env existant..."
  sudo rm -rf venv
fi

virtualenv -p /usr/bin/python3 venv
source venv/bin/activate
pip install psycopg2 requests


python3 import_mtd.py 
