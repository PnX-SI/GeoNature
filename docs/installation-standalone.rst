Installation de GeoNature uniquement
************************************

Cette procédure détail l’installation de GeoNature seul, sans TaxHub et UsersHub.
Si vous souhaitez installer GeoNature avec TaxHub et UsersHub, reportez-vous à la section :ref:`installation-all`.

Installation des dépendances
----------------------------

Installer les paquets suivants :

::  
    
  $ sudo apt install unzip git postgresql-postgis postgis python3-pip python3-venv python3-dev libpq-dev libgdal-dev libffi-dev libpangocairo-1.0-0 apache2 redis


Récupération de l'application
-----------------------------

* Se placer dans le répertoire de l'utilisateur (``/home/geonatureadmin/`` dans notre cas) 

* Récupérer l'application (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_).

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
-----------------------------

Rendez vous dans le dossier ``install`` et lancez successivement dans l’ordre les scripts suivants :

* ``01_install_backend.sh`` : Création du virtualenv python, installation des dépendances et du backend de GeoNature dans celui-ci.
* ``02_configure_systemd.sh`` : Création des services systemd ``geonature`` et ``geonature-worker``, configuration de ``logrotate``, création des dossiers ``/run/geonature`` et ``/var/log/geonature``.
* ``03_create_db.sh`` : Création du role PostgreSQL, de la base de données, ajout des extensions nécessaires (PostGIS, …), création des schémas nécessaires à GeoNature et ajout des données métiers.
* ``04_install_gn_modules.sh`` : Installation des modules Occtax, Occhab et Validation (si activé dans le fichier `settings.ini`).
* ``05_install_frontend.sh`` : Création des dossiers et liens symboliques nécessaires, création des fichiers custom à partir des fichiers d’exemple, génération des fichiers de configuration grâce à la commande ``geonature``, installation de nvm, npm et node ainsi que toutes les dépendances javascript nécessaires puis build du frontend.
* ``06_configure_apache.sh`` : Installation du fichier de configuration Apache ``/etc/apache2/conf-available/geonature.conf`` et activation des modules Apache nécessaires.

Vous pouvez alors démarrer le backend de GeoNature : ``sudo systemctl start geonature``

Configuration Apache
--------------------

* Le script ``install/06_configure_apache.sh`` copie le fichier de configuration de référence ``install/assets/geonature_apache.conf``, le place dans ``/etc/apache2/conf-available/geonature.conf`` et remplace ses variables à partir de votre configuration de GeoNature.

  Relancez ce script si vous changez l'URL de votre GeoNature ou les paramètres liés aux chemins et URL des fichiers statiques et des médias.

* Créez la configuration du vhost, incluant la configuration par défaut créée précédemment :

  .. code:: console

    $ sudo cp install/assets/vhost_apache.conf /etc/apache2/sites-available/geonature.conf # Copier le vhost
    $ sudo nano /etc/apache2/sites-available/geonature.conf # Modifier la variable ``${DOMAIN_NAME}``

* Activez la nouvelle configuration :

  .. code:: console

    $ sudo a2ensite geonature.conf

* et redémarrez Apache :

  .. code:: console

    $ sudo systemctl reload apache2

* L'application est disponible à l'adresse suivante : http://monurl.fr/geonature

Une page HTML de maintenance et un vhost dédié sont aussi disponibles. Pour les mettre en place :

  .. code:: console

    $ sudo cp install/assets/vhost_apache_maintenance.conf /etc/apache2/sites-available/geonature_maintenance.conf # Copier le vhost
    $ sudo nano /etc/apache2/sites-available/geonature_maintenance.conf # Modifier la variable ``${DOMAIN_NAME}``
    $ sudo cp install/assets/maintenance.html /var/www/geonature_maintenance/index.html

Pour passer votre GeoNature en maintenance, vous pouvez alors désactiver le vhost de GeoNature et activer celui de la page de maintenance : 

  .. code:: console

    $ sudo a2dissite geonature.conf
    $ sudo a2ensite geonature_maintenance.conf

Dépendances
-----------

Lors de l'installation de la BDD (``02_create_db.sh``), le schéma ``utilisateurs`` de UsersHub et le schéma ``taxonomie`` de TaxHub sont intégrés automatiquement dans la BDD de GeoNature. 

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

    ./install_app.sh 2>&1 | tee install_app.log

Suite à l'execution de ce script, l'application Taxhub a été lancée automatiquement par le superviseur et est disponible à l'adresse ``http://127.0.0.1:5000`` (et l'API, à ``http://127.0.0.1:5000/api``)

Voir la doc d'installation de TaxHub : https://taxhub.readthedocs.io/

Voir la doc d'installation de UsersHub : https://usershub.readthedocs.io/


Passer en mode développement
----------------------------

.. Note::
    Consultez le guide :ref:`mode-dev` de GeoNature.
