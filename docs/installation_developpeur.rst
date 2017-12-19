===============================
GUIDE D'INSTALLATION DEVELOPPEUR
===============================


Prérequis
=========
Un machine Linux (testé sur Ubuntu 16.04 et Debian 8)

Dépendances
===========
L'application GeoNature utilise les dépendances suivantes:

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Angular 4, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)

L'application GeoNature s'appuye elle même sur des applications connexes pour fonctionner:

- `Taxhub <https://github.com/PnX-SI/TaxHub>`_ pour la gestion de la taxonomie

Des sous modules, également utilisés dans d'autres projets:

- `UsersHub-authentification-module <https://github.com/PnX-SI/UsersHub-authentification-module>`_ pour la gestion des utilisateurs et de l'authentification
- `Nomenclature-api-module <https://github.com/PnX-SI/Nomenclature-api-module>`_ pour la gestion des nomenclatures

Les deux sous-modules sont fournis directement avec GeoNature, il faut en revanche installer Taxhub indépendemment.
pour assuer le bon fonctionnement de l'application

Installations des dépendances
=============================

* Mettre à jour de la liste des dépôts Linux:

  ::  
  
        apt-get update
        apt-get upgrade

* Cloner GeoNature depuis le dépôt GitHub:

  ::  

    git clone https://github.com/PnX-SI/GeoNature.git

Se placer dans le répertoire de GeoNature

* Installer les paquets suivants:

  ::  

    sudo apt-get install -y postgresql postgis postgresql-server-dev-9.4
    sudo apt-get install -y python3 python3-dev python3-setuptools python-pip libpq-dev python-gdal python-virtualenv build-essential
    sudo pip install --upgrade pip virtualenv virtualenvwrapper
    sudo apt-get install -y npm
    sudo apt-get install -y supervisor

Installation la base de données
===============================

Créer un utilisateur PostgreSQL si vous n'en n'avez pas un:

``sudo -n -u postgres -s psql -c "CREATE ROLE <mon_user> WITH LOGIN PASSWORD '<mon_pass'>``

Copier le fichier ``settings.ini.sample `` et le remplir avec ses paramètres

  ::

    cp config/settings.ini.sample config/settings.ini
    nano config/settings.ini

Lancer le script d'installation de la base de données.

Ce script installe l'ensemble des schémas de base de données du "coeur" de GeoNature (utilisateurs, reférentiel géogtraphique, métadonnées, synthèse)

  ::  
  
        sudo ./install_db.sh

Dans GeoNature, chaque module (Occurrence de taxons, Flore Station) dispose de son propre schéma de BDD et de son script d'installation indépendant.
Pour installer le module 'Occurrence de taxons' lancer le script :
 
  ::  
  
	sudo ./data/modules/contact/install_schema.sh

Instalation de l'application
============================
Lancer le script d'installation de l'application:
  ::  
  
        ./install_app.sh


Lors de l'installation, vous êtes invité à remplir le fichier de configuration du backend `config.py`,
et celui du frontend `app.config.ts`.

Exemple de configuration du fichier `config.py`: 

  ::

    URL_APPLICATION = 'http://127.0.0.1:4200' 
    URL_API = 'http://127.0.0.1:8000/api'
    ID_APPLICATION_GEONATURE = 14
    COOKIE_EXPIRATION = 7200


Exemple de configuration du fichier `app.config.ts`: 

  ::

    URL_APPLICATION: 'http://127.0.0.1:4200',
    API_ENDPOINT: 'http://127.0.0.1:8000/',
    API_TAXHUB:  'http://127.0.0.1:5000/api/',
    ID_APPLICATION_GEONATURE: 14


Lancement de l'application
==========================
'nvm' (node version manager) est utilisé pour installer les dernières versions de node et npm 
Lancer cette commande pour ajouter 'nvm' dans la path:

  :: 

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

* Lancer le serveur de développement du frontend grâce à Angular-CLI
  :: 

    cd frontend
    ng serve

**Le serveur de développement du frontend est disponible à l'adresse 127.0.0.1:4200**.
Vous pouvez vous connecter à l'application avec les identifiants 'admin/admin'
A chaque modification du code le navigateur est rafrachit automatiquement.

* Lancer l'API en mode développement

Ouvrir un nouveau terminal

``cd backend``

Stopper d'abbord gunicorn qui est lancé en mode production via le supervisor

    ``make stop``

Puis lancer le backend en mode développement

    ``make develop``

**Le serveur développement est disponible à l'adresse 127.0.0.1:8000**

TODO interroger l'API via Postman


Installation de Taxhub
======================

Sortez de répertoire de GeoNature pour installer Taxhub de manière indépendante.

* Cloner Taxhub depuis le dépôt GitHub:

  ::  

    git clone https://github.com/PnX-SI/TaxHub


* Installer l'application

Copier le fichier ``settings.ini.sample `` et le remplir avec ses paramètres

  ::

    cp settings.ini.sample settings.ini
    nano config/settings.ini

Lancer le script d'installation de l'application:

  ::

    ./install_app.sh

* Lancer l'API de Taxhub en mode développement

Stopper d'abbord gunicorn qui est lancé en mode production via le supervisor

    ``make stop``

Puis lancer le backend en mode développement

    ``make develop``

**Le serveur développement est disponible à l'adresse 127.0.0.1:5000/api**


====================================

Documentation sur l'API, le frontend et la base de données ICI : https://github.com/PnX-SI/GeoNature/blob/frontend-contact/docs/development.rst

Happy hacking ! :metal: :metal:



