Installation
============

GeoNature repose sur les composants suivants :

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 15, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)


Deux méthodes d’installation existent :

- :ref:`installation-all` : Installation automatisée de GeoNature (incluant TaxHub) et UsersHub.
- :ref:`installation-standalone` : UsersHub n'est pas installé (mais son schéma de BDD est tout de même créé dans la base de données de GeoNature).


Prérequis
*********

- Ressources minimum serveur :

  - Un serveur Debian 11 ou 12, architecture 64-bits
  - 4 Go RAM
  - 20 Go d’espace disque


- GeoNature nécessite d’accéder à des ressources externes durant son installation et son fonctionnement. Si vous utilisez un serveur mandataire, celui-ci doit permettre l’accès aux domaines suivants :

  - https://pypi.python.org
  - https://geonature.fr/
  - https://codeload.github.com/
  - https://nodejs.org/dist
  - https://registry.npmjs.org
  - https://www.npmjs.com
  - https://raw.githubusercontent.com/
  - https://data.geopf.fr/


.. _preparation-server:

Préparation du serveur
**********************

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur linux ``root``.

* Mettre à jour de la liste des dépôts Linux :

  .. code:: shell

    apt update
    apt upgrade

* Configuration de la locale du serveur

  Certains serveurs sont livrés sans "locale" (langue par défaut). Pour l'installation de GeoNature, il est nécessaire de bien configurer la locale. Si la commande ``locale`` renvoie ceci :

  .. code:: console

    LANG=fr_FR.UTF-8
    LANGUAGE=fr_FR.UTF-8
    LC_CTYPE="fr_FR.UTF-8"
    LC_NUMERIC="fr_FR.UTF-8"
    LC_TIME="fr_FR.UTF-8"
    LC_COLLATE="fr_FR.UTF-8"
    LC_MONETARY="fr_FR.UTF-8"
    LC_MESSAGES="fr_FR.UTF-8"
    LC_PAPER="fr_FR.UTF-8"
    LC_NAME="fr_FR.UTF-8"
    LC_ADDRESS="fr_FR.UTF-8"
    LC_TELEPHONE="fr_FR.UTF-8"
    LC_MEASUREMENT="fr_FR.UTF-8"
    LC_IDENTIFICATION="fr_FR.UTF-8"
    LC_ALL=fr_FR.UTF-8

  Vous pouvez alors passer cette étape de configuration des locales.

  Sinon exécuter la commande ``dpkg-reconfigure locales``. Une fenêtre s'affiche dans votre console. Dans la liste déroulante, sélectionnez ``fr_FR.UTF-8 UTF-8`` avec ``Espace``, puis cliquez sur OK. Une 2ème fenêtre s'affiche avec une liste de locale activées (``fr_FR.UTF-8`` doit être présent dans la liste), confirmez votre choix, en cliquant sur OK, puis attendez que la locale s'installe.


* Installer l’utilitaire ``sudo`` :

  .. code:: shell

    apt install sudo

* Créer un utilisateur Linux dédié (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler en ``root`` :

  .. code:: shell

    adduser geonatureadmin

* Lui donner ensuite les droits administrateur en l’ajoutant au groupe ``sudo`` :

  .. code:: shell

    adduser geonatureadmin sudo

.. note::
        Vérifier les droits du répertoire HOME de l'utilisateur
          
        Il doit être en ``7XX`` soit ``drwxr-xr-x``. Si ce n'est pas le cas, exécuter la commande suivante :
        
        .. code:: shell
      
          chmod 755 /home/geonatureadmin
* Pour la suite du processus d’installation, on utilisera l'utilisateur non privilégié nouvellement créé. Si besoin d'éxecuter des commandes avec les droits d'administrateur, on les précèdera de ``sudo``.

  Il est d'ailleurs possible renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec ``root``. Voir https://docs.ovh.com/fr/vps/conseils-securisation-vps/ pour plus d'informations sur le sécurisation du serveur.
  
  Pour passer de l’utilisateur ``root`` à ``geonatureadmin``, vous pouvez aussi utiliser la commande :

  .. code:: shell

    su - geonatureadmin


.. _installation-all:

.. include:: installation-all.rst

.. _installation-standalone:

.. include:: installation-standalone.rst

.. include:: installation-docker.rst

.. include:: https.rst

.. _cron:

Taches planifiées
*****************

Depuis sa version 2.12.0, les taches planifiées gérées par des crons ont été remplacées par des taches lancées automatiquement par Celery Beat, pour être mis en place automatiquement lors de l'installation de GeoNature et être plus facilement administrables.


.. _install-gn-module:

Installation d'un module GeoNature
**********************************

L'installation de GeoNature n'est livrée qu'avec les modules du coeur par défaut : Occtax, Occhab et Validation. Pour ajouter un module GeoNature externe, il est nécessaire de l'installer :

Téléchargement
--------------

Téléchargez le module depuis son dépôt Github puis dézippez-le dans le repertoire utilisateur, au même niveau que le dossier de GeoNature.

.. _install-gn-module-auto:

Installation automatique
------------------------

Installation avec la sous-commande ``install-gn-module`` :

.. code-block:: bash

    source <dossier GeoNature>/backend/venv/bin/activate
    geonature install-gn-module <dossier du module> <code du module>

Exemple pour le module Import :

.. code-block:: bash

    source ~/GeoNature/backend/venv/bin/activate
    geonature install-gn-module ~/gn_module_import/ IMPORT

Puis relancer GeoNature et son worker :

.. code-block:: bash

    sudo systemctl restart geonature
    sudo systemctl restart geonature-worker

Aucune permission n'est définie par défaut lors de l'installation d'un module. En tant qu'administrateur, vous pouvez exécuter une commande ajoutant tous les droits sur tous les modules à un groupe ou utilisateur. Cette commande peut être relancée après l'installation d'un module pour automatiquement attribuer toutes les permissions à un groupe ou utilisateur administrateur :

.. code-block:: bash

    # changer "Grp_Admin" par le nom de votre groupe d'administrateur si vous l'avez changé
    geonature permissions supergrant --group --nom "Grp_admin"

Vous devrez ensuite définir des droits à vos utilisateurs pour le nouveau module installé.

Installation manuelle
---------------------

**Installation du backend**

Installer le module avec ``pip`` en mode éditable après avoir activé le venv de GeoNature, puis relancer GeoNature :

.. code-block:: bash

    source ~/geonature/backend/venv/bin/activate
    pip install --editable <dossier du module>
    sudo systemctl restart geonature

.. _module_install_frontend:

**Installation du frontend**

* Créer un lien symbolique dans le dossier ``frontend/external_modules`` de GeoNature vers le dossier ``frontend`` du module.
  Le lien symbolique doit être nommé suivant le code du module en minuscule :

  .. code-block:: bash

      cd ~/geonature/frontend/external_modules/
      ln -s <dossier du module>/frontend <code du module en minuscule>

  Exemple pour le module Import :

  .. code-block:: bash

      cd ~/geonature/frontend/external_modules/
      ln -s ~/gn_module_import/frontend import

* Re-builder le frontend :

  .. code-block:: bash

      cd ~/geonature/frontend/
      nvm use
      npm run build

**Installation de la base de données**

.. code-block:: bash

    source ~/geonature/backend/venv/bin/activate
    geonature upgrade-modules-db <code du module>

.. _module-config:

Configuration du module
-----------------------

De manière facultative, vous pouvez modifier la configuration du module.
Pour cela, vous pouvez créer un fichier de configuration dans le dossier ``config`` de GeoNature en le nommant ``<code du module en minuscule>_config.toml``.
La plupart des modules fournissent un fichier d’exemple ``<module-code>_config.toml.example`` dans leur dossier racine dont vous pouvez vous inspirer.

Après création de ce fichier, activez le rechargement automatique de GeoNature lors des modifications du fichier en lançant les commandes suivantes :

.. code-block:: bash

    sudo systemctl daemon-reload
    sudo systemctl restart geonature

Avant la version 2.12.0 de GeoNature, après chaque modification de la configuration du module, vous devez recharger GeoNature manuellement :

.. code-block:: bash

    sudo systemctl reload geonature


Mise à jour du module
---------------------

* Déplacer le code de l’ancienne version du module : ``mv gn_module_xxx gn_module_xxx_old``
* Télécharger et désarchiver la nouvelle version du module, et renommer son dossier afin qu’il porte le même nom qu’avant (*e.g.* ``gn_module_xxx``)
* (Optionnel) Si le fichier de configuration du module est encore placé avec celui-ci, le déplacer dans la dossier de configuration centralisée de GeoNature : ``cp gn_module_xxx_old/config/conf_gn_module.toml geonature/config/<mode-code>_config.toml``
* Relancer l’:ref:`installation du module<install-gn-module-auto>` : ``geonature install-gn-module gn_module_xxx XXX && sudo systemctl reload geonature``


Mise à jour de l'application
****************************

.. warning::
    Avant chaque mise à jour de GeoNature, il est important de sauvegarder l'application et sa base de données, ou de faire un snapshot du serveur pour pouvoir revenir à son état antérieure avant mise à jour, en cas de problème.

.. warning::
    Vérifiez préalablement la compatibilité des modules que vous utilisez avant de mettre GeoNature à jour.
    S’il est nécessaire de les mettre à jour, arrêtez vous après le remplacement du dossier par le nouveau code source
    (et la récupération éventuelle de la configuration); le script de migration de GeoNature s’occupera automatiquement
    d’installer la nouvelle version du module.

La mise à jour de GeoNature consiste à télécharger sa nouvelle version dans un nouveau répertoire, récupérer les fichiers de configuration et de surcouche, ainsi que les médias depuis la version actuelle et de relancer l'installation dans le répertoire de la nouvelle version.

La mise à jour doit être réalisée avec votre utilisateur linux courant (``geonatureadmin`` par exemple) et non pas le super-utilisateur ``root``.

* Télécharger la dernière version de GeoNature :

  .. code-block:: bash

      wget https://github.com/PnX-SI/GeoNature/archive/X.Y.Z.zip
      unzip X.Y.Z.zip
      rm X.Y.Z.zip

* Renommer l'ancien repertoire de l'application, ainsi que le nouveau :

  .. code-block:: bash

      mv ~/geonature/ ~/geonature_old/
      mv ~/GeoNature-X.Y.Z ~/geonature/
      cd ~/geonature

* Suivez les éventuelles notes de version spécifiques décrites au niveau de chaque version : https://github.com/PnX-SI/GeoNature/releases.

Sauf mentions contraires dans les notes de version, vous pouvez sauter des versions mais en suivant bien les différentes notes de versions intermédiaires.

* Si vous devez aussi mettre à jour UsersHub, suivez ses notes de version et sa documentation (https://usershub.readthedocs.io).

* Lancez le script de ``migration.sh`` à la racine du dossier ``geonature``:

  .. code-block:: bash

      ./install/migration/migration.sh 2>&1 | tee install/migration/migration.log

Depuis la version 2.12, le script `migration.sh` peut prendre en argument le chemin vers l'ancien dossier d'installation de GeoNature. Il peut s’agir du même dossier que la nouvelle installation de GeoNature. Cela permet d'utiliser ce script si la nouvelle version de GeoNature est dans le même dossier et donc de gérer le cas où GeoNature est installé et mis à jour avec git.

Dans ce cas, les commandes à exécuter sont : 

.. code-block:: bash

    cd ~/GeoNature
    git status # optionnel, pour connaitre l'état et la version ou branche actuellement utilisée
    git fetch
    git checkout X.Y.Z # où X.Y.Z est le numéro du tag de la version vers laquelle faire la mise à jour, ou le nom de la branche à utiliser
    git submodule update # ou "git config submodule.recurse true" lancé une seule fois, pour que la mise à jour des sous-modules soit relancée automatiquement à chaque "git pull"
    ./install/migration/migration.sh .
