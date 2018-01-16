=============================
INSTALLATION DE L'APPLICATION
=============================

Prérequis
=========

- Ressources minimum serveur :

Un serveur Linux disposant d’au moins de 2 Go RAM et de 20 Go d’espace disque.


Celui-ci installe :

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 4, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)

Installation de l'application
=============================

/!\ A mettre à jour. Install_all en cours : https://github.com/PnX-SI/GeoNature/tree/frontend-contact/install_all

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur linux ROOT.

* Mettre à jour de la liste des dépôts Linux

::

    apt-get update
    apt-get upgrade

* Installer sudo

::

    apt-get install -y sudo ca-certificates

* Créer un utilisateur linux (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler en ROOT (en lui donnant les droits sudo)

::

    adduser geonatureadmin sudo

* L'ajouter aussi aux groupes www-data et root

::

    usermod -g www-data geonatureadmin
    usermod -a -G root geonatureadmin

* Récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_). Ces scripts installent les applications GeoNature, Taxhub ainsi que leurs bases de données (uniquement les schémas du coeur)


::

    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install_all/install_all.ini
    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install_all/install_all.sh


* Changer les droits du fichier d'installation pour pouvoir l'éxecuter

::

    chmod +x install_all.sh

Se reconnecter en SSH au serveur avec le nouvel utilisateur pour ne pas faire l'installation en ROOT.

On ne se connectera plus en ROOT. Si besoin d'executer des commandes avec des droits d'administrateur, on les précède de ``sudo``.

Il est d'ailleurs possible renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec ROOT.

Voir https://docs.ovh.com/pages/releaseview.action?pageId=18121864 pour plus d'informations sur le sécurisation du serveur.

* Lancer l'installation

::

    ./install_all.sh

Pendant l'installation, vous serez invité à renseigner le fichier de configuration ``install_all.ini``.

Une fois l'installation terminée, lancez:

::

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

Les applications sont disponibles aux adresses suivantes:

	- http://monip.com/geonature
	- http://monip.com/taxhub


Installation d'un module GeoNature
==================================

L'installation de GeoNature n'est livrée qu'avec les schémas de base de données du coeur. Pour ajouter un nouveau module, il est necessaire de l'installer:

* Exemple d'installation en base de données du module OccTax.

::

    sudo ./data/modules/contact/install_schema.sh


Doc développeur
==========================================

Instalation de l'environnement Python
--------------------------------------

Installer pipenv et le virtualenv ainsi que tous les dépendances Python.

::

    pip install pipenv --user
    pipenv install

Lancer ensuite l'application en mode développement

Stopper d'abbord le mode production, puis lancez le mode développement du backend

::

    cd geonature/backend/
    make supervisor-stop
    make develop




* Installation du sous-module en mode develop. On assume que le sous-module est installé au même niveau que GeoNature, dans le répertoire `home` de l'utilisateur

::

    cd
    git clone https://github.com/PnX-SI/Nomenclature-api-module.git nomenclature-api-module
    cd nomenclature-api-module/
    source ../geonature/backend/venv/bin/activate
    cp ../geonature/backend/config.py.sample ../geonature/backend/config.py
    python setup.py develop
    cd ../geonature2/backend/
    make develop
    deativate

* Lancer le front end

Modifier le fichier de configuration du frontend ``frontend/src/conf/app.config.ts`` de la manière suivante:

::

  	URL_APPLICATION: 'http://127.0.0.1:4200',
    API_ENDPOINT: 'http://127.0.0.1:8000/',
    API_TAXHUB : 'http://127.0.0.1:5000/api/',

Depuis le répertoire ``frontend`` lancer la commande:

::

	  npm run start

Lancer son navigateur à l'adresse ``127.0.0.1:4200``
