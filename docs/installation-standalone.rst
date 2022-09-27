Installation de GeoNature uniquement
************************************

Cette procédure détail l’installation de GeoNature seul, sans TaxHub et UsersHub.
Si vous souhaitez installer GeoNature avec TaxHub et UsersHub, reportez-vous à la section :ref:`installation-all`.

Installation des dépendances
----------------------------

Installer les paquets suivants :

::  
    
  $ sudo apt install unzip git postgresql postgis python3-pip python3-venv python3-dev libpq-dev libgdal-dev libffi-dev libpangocairo-1.0-0 apache2 redis


Note : le paquet ``redis`` n’est pas nécessaire si vous ne souhaitez pas installer le worker celery.


Installation de l'application
-----------------------------

* Se placer dans le répertoire de l'utilisateur (``/home/geonatureadmin/`` dans notre cas) 

* Récupérer l'application (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_). Voir le `tableau de compatibilité <versions-compatibility.rst>`_ des versions de GeoNature avec ses dépendances.

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

* ``01_install_backend.sh`` : Création du virtualenv python, installation des dépendances et du backend GeoNature dans celui-ci.
* ``02_configure_systemd.sh`` : Création des services systemd ``geonature`` et ``geonature-worker``, configuration de ``logrotate``, création des dossiers ``/run/geonature`` et ``/var/log/geonature``.
* ``03_create_db.sh`` : Création du role postgresql, de la base de données, ajout des extensions nécessaires (postgis, …), création des schémas nécessaires à GeoNature et ajout des données métiers.
* ``04_install_gn_modules.sh`` : Installation des modules OccTax, OccHab et validation (si activé dans le fichier `settings.ini`).
* ``05_install_frontend.sh`` : Création des dossiers et liens symboliques nécessaires, création des fichier custom à partir des fichiers d’exemple, génération des fichiers de configuration grâce à la commande `geonature`, installation de nvm, npm et node ainsi que toutes les dépendances javascript nécessaires puis build du front.
* ``06_configure_apache.sh`` : Installation du fichier de configuration Apache ``/etc/apache2/conf-available/geonature.conf`` et activation des modules Apache nécessaires.

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

Télécharger TaxHub depuis son dépôt Github depuis la racine de votre utilisateur :

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

Passer en mode développement
---------------------------------

.. Note::
    Consultez le guide :ref:`mode-dev` de GeoNature.
