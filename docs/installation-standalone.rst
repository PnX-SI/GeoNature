INSTALLATION AUTONOME
=====================

**Attention** : Ne suivez cette documentation que si vous souhaitez installer GeoNature de manière autonome (sans TaxHub ou UsersHub).
Pour une installation packagée voir cette `documentation <https://github.com/PnX-SI/GeoNature/blob/master/docs/installation-all.rst>`_.

Prérequis
---------

Ressources minimum serveur :

- Un serveur Linux architecture 64-bits sous Debian 10 ou Debian 11 disposant d’au moins de 4 Go RAM et de 20 Go d’espace disque.

GeoNature utilise les technologies suivantes:

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 7, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)

Préparation du serveur
----------------------

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur linux ``root``.

* Mettre à jour de la liste des dépôts Linux :

  ::

    # apt update
    # apt upgrade


* Installer les dépendances de GeoNature :

  ::  
    
    # apt install unzip git postgresql postgis python2 python3-pip python3-venv libgdal-dev libpangocairo-1.0-0 apache2

* Créer un utilisateur linux (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler en ``root`` :

  ::

    # adduser geonatureadmin

* Lui donner ensuite des droits administrateur en l’ajoutant au groupe ``sudo`` :

  ::

    # adduser geonatureadmin sudo


* Se reconnecter en SSH au serveur avec l’utilisateur nouvellement créé afin d’effectuer la suite du processus d’installation en tant qu’utilisateur non privilégié. Si besoin d'éxecuter des commandes avec des droits d'administrateur, on les précèdera de ``sudo``. Il est d'ailleurs possible renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec root. Voir https://docs.ovh.com/fr/vps/conseils-securisation-vps/ pour plus d'informations sur le sécurisation du serveur.


Installation de l'application
-----------------------------

* Se placer dans le répertoire de l'utilisateur (``/home/geonatureadmin/`` dans notre cas) 

* Récupérer l'application (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnX-SI/GeoNature/releases>`_). Voir le `tableau de compatibilité <versions-compatibility.rst>`_ des versions de GeoNature avec ses dépendances.

  ::

    $ wget https://github.com/PnX-SI/GeoNature/archive/X.Y.Z.zip

* Dézipper l'archive de l'application

  ::

    $ unzip X.Y.Z.zip
    $ rm X.Y.Z.zip

* Renommer le répertoire de l'application puis placez-vous dedans : 

  ::

    $ mv GeoNature-X.Y.Z /home/`whoami`/geonature/
    $ cd geonature

* Copier puis mettre à jour le fichier de configuration (``config/settings.ini``) comportant les informations relatives à votre environnement serveur :

  ::

    $ cp config/settings.ini.sample config/settings.ini
    $ nano config/settings.ini


Installation de l'application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Rendez vous dans le dossier ``install`` et lancez successivement dans l’ordre les scripts suivant :

* ``01_install_backend.sh`` : Création du virtualenv python, installation des dépendances et du backend GeoNature dans celui-ci, création du service systemd (permettant d’utiliser ``sudo systemctl {start,stop} geonature2``).
* ``02_create_db.sh`` : Création du role postgresql, de la base de données, ajout des extensions nécessaires (postgis, …), création des schémas nécessaires à GeoNature et ajout des données métiers.
* ``03_install_gn_modules.sh`` : Installation des modules OccTax, OccHab et validation (si activé dans le fichier `settings.ini`).
* ``04_install_frontend.sh`` : Création des dossiers et liens symboliques nécessaires, création des fichier custom à partir des fichiers d’exemple, génération des fichiers de configuration grâce à la commande `geonature`, installation de nvm, npm et node ainsi que toutes les dépendances javascript nécessaires puis build du front.

Vous pouvez alors démarrer le backend GeoNature : ``sudo systemctl start geonature2``

Configuration Apache
^^^^^^^^^^^^^^^^^^^^

* Copiez et adaptez le fichier de configuration d’exemple d’Apache de GeoNature :

  ::

    $ sudo cp install/assets/geonature_apache.conf /etc/apache2/sites-available/geonature.conf
    $ sudo nano /etc/apache2/sites-available/geonature.conf

* Activez les modules suivants :

  ::

    $ sudo a2enmod rewrite
    $ sudo a2enmod proxy
    $ sudo a2enmod proxy_http

* Activez la nouvelle configuration:

  ::

    $ sudo a2ensite geonature.conf

* et redémarrez Apache:

  ::

    $ sudo systemctl restart apache2

* L'application est disponible à l'adresse suivante : http://monip.com/geonature


Dépendances
-----------

Lors de l'installation de la BDD (``02_create_db.sh``) le schéma ``utilisateurs`` de UsersHub et le schéma ``taxonomie`` de TaxHub sont intégrés automatiquement dans la BDD de GeoNature. 

UsersHub n'est pas nécessaire au fonctionnement de GeoNature mais il sera utile pour avoir une interface de gestion des utilisateurs, des groupes et de leurs droits. 

Par contre il est nécessaire d'installer TaxHub (https://github.com/PnX-SI/TaxHub) pour que GeoNature fonctionne. En effet, GeoNature utilise l'API de TaxHub. Une fois GeoNature installé, il vous faut donc installer TaxHub en le connectant à la BDD de GeoNature, vu que son schéma ``taxonomie`` a déjà été installé par le script ``02_create_db.sh`` de GeoNature. Lors de l'installation de TaxHub, n'installez donc que l'application et pas la BDD.

Télécharger Taxhub depuis le dépôt github depuis la racine de votre utilisateur:

::

    cd ~
    wget https://github.com/PnX-SI/TaxHub/archive/X.Y.Z.zip
    unzip X.Y.Z.zip
    rm X.Y.Z.zip
    
en mode développeur: 

``https://github.com/PnX-SI/TaxHub.git``

Rendez vous dans le répertoire téléchargé et dézippé, puis "désamplez" le fichier ``settings.ini`` et remplissez la configuration avec les paramètres de connexion à la BDD GeoNature précedemment installée :

::

    cp settings.ini.sample settings.ini
    nano settings.ini

Lancer le script d'installation de l'application :

::

    mkdir var 
    mkdir var/log
    touch var/log/install_app.log
    ./install_app.sh 2>&1 | tee var/log/install_app.log

Suite à l'execution de ce script, l'application Taxhub a été lancé automatiquement par le superviseur et est disponible à l'adresse ``127.0.0.1:5000`` (et l'API, à ``127.0.0.1:5000/api``)

Voir la doc d'installation de TaxHub : http://taxhub.readthedocs.io/

Voir la doc d'installation de UsersHub : http://usershub.readthedocs.io/

Mise à jour de l'application
----------------------------

Attention, avant chaque mise à jour, il est important de sauvegarder l'application et sa base de données, ou de faire un snapshot du serveur pour pouvoir revenir à son état antérieure avant mise à jour en cas de problème.

La mise à jour de GeoNature consiste à télécharger sa nouvelle version dans un nouveau répertoire, récupérer les fichiers de configuration et de surcouche depuis la version actuelle et de relancer l'installation dans le répertoire de la nouvelle version.

La mise à jour doit être réalisée avec votre utilisateur linux courant (``geonatureadmin`` par exemple) et non pas le super-utilisateur ``root``.

* Télécharger la dernière version de GeoNature :

  ::

    wget https://github.com/PnX-SI/GeoNature/archive/X.Y.Z.zip
    unzip X.Y.Z.zip
    rm X.Y.Z.zip

* Renommer l'ancien repertoire de l'application, ainsi que le nouveau :

  ::

    mv /home/`whoami`/geonature/ /home/`whoami`/geonature_old/
    mv GeoNature-X.Y.Z /home/`whoami`/geonature/
    cd geonature

* Suivez les éventuelles notes de version spécifiques décrites au niveau de chaque version : https://github.com/PnX-SI/GeoNature/releases.

⚠️ Si la release inclut des scripts de migration SQL : *lancer ces scripts avec l'utilisateur de BDD courant* (généralement ``geonatadmin``) et non le super-utilisateur ``postgres``.

Sauf mentions contraires dans les notes de version, vous pouvez sauter des versions mais en suivant bien les différentes notes de versions intermédiaires et notamment les scripts de mise à jour de la base de données à exécuter successivement.

* Si vous devez aussi mettre à jour TaxHub et/ou UsersHub, suivez leurs notes de versions mais aussi leur documentation (https://usershub.readthedocs.io et https://taxhub.readthedocs.io).

* Lancez le script de ``migration.sh`` à la racine du dossier ``geonature``:

  ::
    
    ./install/migration/migration.sh


Passer en mode développement
----------------------------

Si vous avez téléchargé GeoNature zippé (via la procédure d'installation globale ``install_all.sh`` ou en suivant la documentation d'installation standalone), il est nécessaire de rattacher votre répertoire au dépôt GitHub afin de pouvoir télécharger les dernières avancées du coeur en ``git pull``. Pour cela, suivez les commandes suivantes en vous placant à la racine du répertoire de GeoNature.

::

    --- Se créer un répertoire .git ---
    mkdir .git
    ---  récupérer l'historique du dépôt --- 
    git clone --depth=2 --bare https://github.com/PnX-SI/GeoNature.git .git
    --- initialiser un dépôt git à partir de l'historique téléchargé --- 
    git init
    --- vérifier que le dépôt distant et le contenu local sont synchronisés --- 
    git pull
    --- Reset sur HEAD pour mettre à jour les status --- 
    git reset HEAD
    -> vous êtes à jour sur la branche master
    --- Cloner les sous-modules pour récupérer les dépendances
    git submodule init
    git submodule update
    --- Installer les dépendances de développement
    cd backend && pip install -r requirements-dev.txt


@TODO : A relire et à basculer dans DOC DEVELOPEMENT ?

Editez le fichier de configuration de GeoNature (``<GEONATURE_DIRECTORY>/config/geonature_config.toml``) de la manière suivante :

::
    
    URL_APPLICATION = 'http://127.0.0.1:4200'
    API_ENDPOINT = 'http://127.0.0.1:8000'
    API_TAXHUB =  'http://127.0.0.1:5000/api'
    ID_APPLICATION_GEONATURE = 3

Puis le fichier ``/home/<mon_user>/geonature/frontend/src/conf/app.config.ts`` :

::
    
    URL_APPLICATION: 'http://127.0.0.1:4200',
    API_ENDPOINT: 'http://127.0.0.1:8000',
    API_TAXHUB:  'http://127.0.0.1:5000/api',
    ID_APPLICATION_GEONATURE: 3

* Lancer le serveur de développement du frontend grâce à Angular-CLI :

  ::
    
    cd frontend
    npm run start

* Lancer l'API en mode développement

Ouvrir un nouveau terminal :

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

Vous pouvez vous connecter à l'application avec l'identifiant ``admin`` et le mot de passe ``admin``.
