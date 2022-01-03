INSTALLATION
============

GeoNature repose sur les composants suivants :

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 7, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)


Deux méthodes d’installation existent :

- :ref:`installation-all` : Installation de GeoNature, TaxHub et UsersHub.
- :ref:`installation-standalone` : TaxHub et UsersHub ne sont pas installé (mais leur schémas sont tous de même créés dans la base de données).


Prérequis
*********

- Ressources minimum serveur :

  - Un serveur Debian 10 ou Debian 11 architecture 64-bits
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
  - https://inpn.mnhn.fr/mtd
  - https://preprod-inpn.mnhn.fr/mtd
  - https://wxs.ign.fr/


.. _preparation-server:

Préparation du serveur
**********************

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur linux ``root``.

* Mettre à jour de la liste des dépôts Linux :

  ::

    # apt update
    # apt upgrade

* Configuration de la locale du serveur

  Certains serveurs sont livrés sans "locale" (langue par défaut). Pour l'installation de GeoNature, il est nécessaire de bien configurer la locale. Si la commande ``locale`` renvoie ceci :

  ::

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

  ::

    # apt install sudo

* Créer un utilisateur Linux dédié (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler en ``root`` :

  ::

    # adduser geonatureadmin

* Lui donner ensuite les droits administrateur en l’ajoutant au groupe ``sudo`` :

  ::

    # adduser geonatureadmin sudo

* Pour la suite du processus d’installation, on utilisera ’utilisateur non privilégié nouvellement créé. Si besoin d'éxecuter des commandes avec les droits d'administrateur, on les précèdera de ``sudo``. Il est d'ailleurs possible renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec ``root``. Voir https://docs.ovh.com/fr/vps/conseils-securisation-vps/ pour plus d'informations sur le sécurisation du serveur. Pour passer de l’utilisateur ``root`` à ``geonatureadmin``, vous pouvez aussi utiliser la commande :

  ::

    # su - geonatureadmin


.. _installation-all:

.. include:: installation-all.rst

.. _installation-standalone:

.. include:: installation-standalone.rst

.. include:: installation-mtes.rst

.. include:: https.rst
