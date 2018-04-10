INSTALLATION AUTONOME DE GEONATURE
==================================

*Attention* : Ne suivez cette documentation que si vous souhaitez installer GeoNature de manière autonome (sans TaxHub ou UsersHub).
Pour une installation packagée voir cette `documentation <https://github.com/PnX-SI/GeoNature/blob/install_all/docs/installation-all.rst>`_

Prérequis
---------

Ressources minimum serveur :

- Un serveur Linux disposant d’au moins de 2 Go RAM et de 20 Go d’espace disque.

GeoNature utilise les technologies suivantes:

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 4, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)

Préparation du serveur
----------------------

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

* Se reconnecter en SSH au serveur avec le nouvel utilisateur pour ne pas faire l'installation en root. On ne se connectera plus en root. Si besoin d'éxecuter des commandes avec des droits d'administrateur, on les précède de ``sudo``. Il est d'ailleurs possible renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec root. Voir https://docs.ovh.com/fr/vps/conseils-securisation-vps/ pour plus d'informations sur le sécurisation du serveur.

* Lancez les commandes suivantes pour installer les dépendances de GeoNature :

  ::  

    sudo apt-get install -y postgresql postgis postgresql-server-dev-9.4
    sudo apt-get install -y python3 python3-dev python3-setuptools python-pip libpq-dev python-gdal python-virtualenv build-essential
    sudo pip install --upgrade pip virtualenv virtualenvwrapper
    sudo apt-get install -y npm
    sudo apt-get install -y supervisor

Installation de l'application
-----------------------------

* Se placer dans le répertoire de l'utilisateur (``/home/geonatureadmin/`` dans notre cas) 

* Récupérer l'application (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnX-SI/GeoNature/releases>`_). La version 2 de GeoNature est actuellement en cours de developpement. Elle n'est pas encore stable et se trouve sur la branche geonature2beta (remplacer ``X.Y.Z`` par ``geonature2beta``).

::

    wget https://github.com/PnX-SI/GeoNature/archive/X.Y.Z.zip

* Dézipper l'archive de l'application

::

    unzip GeoNature-X.Y.Z.zip

* Renommer le répertoire de l'application puis placez-vous dedans : 

::

    mv GeoNature-X.Y.Z /home/<mon_user>/geonature/
    cd geonature

* Copier puis mettre à jour le fichier de configuration (``config/settings.ini``) comportant les informations relatives à votre environnement serveur :

::

    cp config/settings.ini.sample config/settings.ini
    nano config/settings.ini

**Création de la base de données**

Créer un utilisateur de base de donnée (cf ``settings.ini``)
::

    sudo -n -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';"

Pendant l'installation, vous serez invité à fournir le mot de passe sudo de votre utilisateur linux.

::

    ./install_db.sh

La commande ``install_db.sh`` comporte deux paramètres optionnels qui doivent être utilisés dans l'ordre :

- -s ou --settings-path pour spécifier un autre emplacement pour le fichier ``settings.ini``
- -d ou --dev permet d'installer des dépendances python utile pour le développement de GeoNature
- -h ou --help affiche l'aide pour cette commande ``install_app.sh``

**Installation de l'application**

Lancer le script d'installation de l'application :

::

    ./install_app.sh

Pendant l'installation, vous serez invité à fournir le mot de passe sudo de votre utilisateur linux.

'nvm' (node version manager) est utilisé pour installer les dernières versions de node et npm.

Une fois l'installation terminée, lancer cette commande pour ajouter 'nvm' dans la path de votre serveur :

::

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

L'application est disponible à l'adresse suivante:

- http://monip.com/geonature

Si vous souhaitez que GeoNature soit à racine du serveur, ou à une autres adresse, placez-vous dans le répertoire ``frontend`` de GeoNature (``cd frontend``) puis lancer la commande :

- Pour ``/``: ``npm run build -- --base-href=/``
- Pour ``/saisie`` : ``npm run build -- --base-href=/saisie/``

Editez ensuite le fichier de configuration Apache ``/etc/apache2/sites-available/geonature.conf`` en modifiant "l'alias" :

- Pour ``/`` : ``Alias / /home/test/geonature/frontend/dist``
- Pour ``/saisie``: ``Alias /saisie /home/test/geonature/frontend/dist``

Dépendances
-----------

Lors de l'installation de la BDD (``install_db.sh``) le schéma ``utilisateurs`` de UsersHub et le schéma ``taxonomie`` de TaxHub sont intégrés automatiquement dans la BDD de GeoNature. 

UsersHub n'est pas nécessaire au fonctionnement de GeoNature mais il sera utile pour avoir une interface de gestion des utilisateurs, des groupes et de leurs droits. 

Par contre il est nécessaire d'installer TaxHub (https://github.com/PnX-SI/TaxHub) pour que GeoNature fonctionne. En effet, GeoNature utilise l'API de TaxHub. Une fois GeoNature installé, il vous faut donc installer TaxHub en le connectant à la BDD de GeoNature, vu que son schéma ``taxonomie`` a déjà été installé par le ``install_db.sh`` de GeoNature. Lors de l'installation de TaxHub, n'installez donc que l'application et pas la BDD.

Voir la doc d'installation de TaxHub: http://taxhub.readthedocs.io/

Voir la doc d'installation de UsersHub: http://usershub.readthedocs.io/

Passer en mode développement
----------------------------

Editez le fichier de configuration de GeoNature ``/etc/geonature/geonature_config.toml`` de la manière suivante:

::
    
    URL_APPLICATION = 'http://127.0.0.1:4200'
    API_ENDPOINT = 'http://127.0.0.1:8000'
    API_TAXHUB =  'http://127.0.0.1:5000/api'
    ID_APPLICATION_GEONATURE = 14

puis le fichier ``/home/<mon_user>/geonature/frontend/src/conf/app.config.ts``:
::

    
    URL_APPLICATION: 'http://127.0.0.1:4200',
    API_ENDPOINT: 'http://127.0.0.1:8000',
    API_TAXHUB:  'http://127.0.0.1:5000/api',
    ID_APPLICATION_GEONATURE: 14

* Lancer le serveur de développement du frontend grâce à Angular-CLI :

::
    
    cd frontend
    npm run start

* Lancer l'API en mode développement

Ouvrir un nouveau terminal:

::
    
    cd backend

Stopper d'abord gunicorn qui est lancé en mode production via le supervisor :

::
    
    sudo supervisorctl stop geonature2

Puis lancer le backend en mode développement :

::
    
    source venv/bin/activate
    geonature dev_back

**Le serveur de développement du backend est disponible à l'adresse 127.0.0.1:8000**

**Le serveur de développement du frontend est disponible à l'adresse 127.0.0.1:4200**.

Vous pouvez vous connecter à l'application avec les identifiants 'admin/admin'.
