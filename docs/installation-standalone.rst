INSTALLATION AUTONOME
=====================

**Attention** : Ne suivez cette documentation que si vous souhaitez installer GeoNature de manière autonome (sans TaxHub ou UsersHub).
Pour une installation packagée voir cette `documentation <https://github.com/PnX-SI/GeoNature/blob/master/docs/installation-all.rst>`_.

Prérequis
---------

Ressources minimum serveur :

- Un serveur Linux **architecture 64-bits** disposant d’au moins de 4 Go RAM et de 20 Go d’espace disque.

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

    apt-get update
    apt-get upgrade

* Créer un utilisateur linux (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler en ``root`` :

::

    adduser geonatureadmin

* Lui donner ensuite des droits ``sudo`` :

::

    adduser geonatureadmin sudo


* Se reconnecter en SSH au serveur avec le nouvel utilisateur pour ne pas faire l'installation en ``root``. On ne se connectera plus en ``root``. Si besoin d'éxecuter des commandes avec des droits d'administrateur, on les précède de ``sudo``. Il est d'ailleurs possible renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec root. Voir https://docs.ovh.com/fr/vps/conseils-securisation-vps/ pour plus d'informations sur le sécurisation du serveur.


* Lancez les commandes suivantes pour installer les dépendances de GeoNature (Debian 10) :

  ::  
    
    sudo apt-get install wget git
    sudo apt-get install -y postgresql postgis postgresql-server-dev-11
    sudo apt-get install -y postgis-2.5 postgis postgresql-11-postgis-2.5
    sudo apt-get install -y python3 python3-dev python3-setuptools python3-pip libpq-dev libgdal-dev python-gdal build-essential
    sudo apt-get install -y python3-wheel python3-cffi libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info
    python3 -m pip install pip==20.0.2
    pip3 install virtualenv==20.0.1
    sudo apt-get install -y supervisor
    sudo apt-get install -y apache2
    # installation de NVM
    wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    
Sur Ubuntu 18, installez la version 10 de postgresql-server-dev avec la commande ``sudo apt-get install postgresql-server-dev-10``. La version est à adapter sur les autres versions de Debian ou Ubuntu.


Python 3.7 sur Debian 9
^^^^^^^^^^^^^^^^^^^^^^^

A partir la version 2.5.0 de GeoNature, la version Python 3.5 n'est plus supportée. Seules les version 3.7+ le sont.

Si vous êtes encore sur Debian 9 (fourni par défaut avec Python 3.5), veuillez suivre les instructions suivantes pour monter la version de Python sur Debian 9 :

Installer ``pyenv`` (utilitaire pour installer différentes versions de Python)

::

    sudo apt-get update 
    sudo apt-get upgrade

    sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev python-openssl git

    curl https://pyenv.run | bash

    export PATH="$HOME/.pyenv/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"

Installer Python 3.7.9 :

::

    pyenv install 3.7.9
    pyenv global 3.7.9

Editer ensuite le fichier ``config/settings.ini`` pour changer la variable ``python_path`` (remplacer <MON_USER> par votre utilisateur linux courant. 
NB : faire pareil dans TaxHub et UsersHub.

::

    /home/<MON_USER>/.pyenv/shims/python3


Installation de l'application
-----------------------------

* Se placer dans le répertoire de l'utilisateur (``/home/geonatureadmin/`` dans notre cas) 

* Récupérer l'application (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnX-SI/GeoNature/releases>`_). Voir le `tableau de compatibilité <versions-compatibility.rst>`_ des versions de GeoNature avec ses dépendances.

  ::

    wget https://github.com/PnX-SI/GeoNature/archive/X.Y.Z.zip

* Dézipper l'archive de l'application

  ::

    unzip X.Y.Z.zip
    rm X.Y.Z.zip

* Renommer le répertoire de l'application puis placez-vous dedans : 

  ::

    mv GeoNature-X.Y.Z /home/`whoami`/geonature/
    cd geonature

* Copier puis mettre à jour le fichier de configuration (``config/settings.ini``) comportant les informations relatives à votre environnement serveur :

  ::

    cp config/settings.ini.sample config/settings.ini
    nano config/settings.ini

Création de la base de données
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Créer un utilisateur de base de données (cf ``settings.ini``) :

::

    sudo -n -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';"

Pendant l'installation, vous serez invité à fournir le mot de passe ``sudo`` de votre utilisateur linux.

::

    cd install
    ./install_db.sh


Installation de l'application
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Lancer le script d'installation de l'application (depuis le répertoire ``install``):

La commande ``install_app.sh`` comporte deux paramètres optionnels qui doivent être utilisés dans l'ordre :

- ``-s`` ou ``--settings-path`` pour spécifier un autre emplacement pour le fichier ``settings.ini``
- ``-d`` ou ``--dev`` permet d'installer des dépendances python utile pour le développement de GeoNature et de ne pas compiler inutilement le frontend
- ``-h`` ou ``--help`` affiche l'aide pour cette commande ``install_app.sh``

::
    
    touch ../var/log/install_app.log
    ./install_app.sh 2>&1 | tee ../var/log/install_app.log

Pendant l'installation, vous serez invité à fournir le mot de passe ``sudo`` de votre utilisateur linux.

``nvm`` (node version manager) est utilisé pour installer les dernières versions de ``node`` et ``npm``.

Une fois l'installation terminée, lancer cette commande pour ajouter ``nvm`` dans la path de votre serveur :

::

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

Configuration Apache
^^^^^^^^^^^^^^^^^^^^

Créer le fichier de configuration Apache de GeoNature

``sudo nano /etc/apache2/sites-available/geonature.conf``

Puis coller la configuration suivante:

::

    Alias /geonature /home/geonatureadmin/geonature/frontend/dist
    <Directory /home/geonatureadmin/geonature/frontend/dist>
      Require all granted
    </Directory>
    <Location /geonature/api>
     ProxyPass http://127.0.0.1:8000
     ProxyPassReverse  http://127.0.0.1:8000
    </Location>

Activer les modules suivants:

::

    sudo a2enmod rewrite
    sudo a2enmod proxy
    sudo a2enmod proxy_http

Activer la nouvelle configuration:

``sudo a2ensite geonature.conf``

et redémarrer Apache:

``sudo service apache2 restart``

L'application est disponible à l'adresse suivante :

- http://monip.com/geonature

Editez ensuite le fichier de configuration Apache ``/etc/apache2/sites-available/geonature.conf`` en modifiant l'alias :

- Pour ``/`` : ``Alias / /home/test/geonature/frontend/dist``
- Pour ``/saisie``: ``Alias /saisie /home/test/geonature/frontend/dist``

Dépendances
-----------

Lors de l'installation de la BDD (``install_db.sh``) le schéma ``utilisateurs`` de UsersHub et le schéma ``taxonomie`` de TaxHub sont intégrés automatiquement dans la BDD de GeoNature. 

UsersHub n'est pas nécessaire au fonctionnement de GeoNature mais il sera utile pour avoir une interface de gestion des utilisateurs, des groupes et de leurs droits. 

Par contre il est nécessaire d'installer TaxHub (https://github.com/PnX-SI/TaxHub) pour que GeoNature fonctionne. En effet, GeoNature utilise l'API de TaxHub. Une fois GeoNature installé, il vous faut donc installer TaxHub en le connectant à la BDD de GeoNature, vu que son schéma ``taxonomie`` a déjà été installé par le script ``install_db.sh`` de GeoNature. Lors de l'installation de TaxHub, n'installez donc que l'application et pas la BDD.

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
