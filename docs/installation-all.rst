INSTALLATION GLOBALE
====================

Prérequis
---------

- Ressources minimum serveur :

Un serveur Linux (Debian 10 ou Ubuntu 18 **architecture 64-bits**) disposant d’au moins de 4 Go RAM et de 20 Go d’espace disque.

Le script global d'installation de GeoNature va aussi se charger d'installer les dépendances nécessaires : 

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 7, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)

Configuration serveur
---------------------

GeoNature se sert de flux internet externes durant son installation et son fonctionnement. Le serveur hébergeant l'application doit autoriser les flux externes suivants :

- https://pypi.python.org
- http://geonature.fr/
- https://codeload.github.com/
- https://nodejs.org/dist
- https://registry.npmjs.org
- https://www.npmjs.com
- https://raw.githubusercontent.com/
- https://inpn.mnhn.fr/mtd
- https://preprod-inpn.mnhn.fr/mtd
- https://wxs.ign.fr/

Installation de l'application
-----------------------------

Ce document décrit une procédure d'installation packagée de GeoNature.

En lançant le script d'installation ci-dessous, l'application GeoNature ainsi que ses dépendances seront installées sur un seul et même serveur au sein d'une seule base de données.

Les applications suivantes seront installées :

- GeoNature
- `TaxHub <https://github.com/PnX-SI/TaxHub>`_ qui pilote le schéma ``taxonomie``
- `UsersHub <https://github.com/PnEcrins/UsersHub>`_ qui pilote le schéma ``utilisateurs`` (le paramètre ``install_usershub_app`` du fichier de configuration ``install_all.ini`` permet de désactiver l'installation de l'application. Il est cependant recommandé d'installer l'application pour disposer d'une interface pour gérer les utilisateurs dans GeoNature)

Si vous disposez déjà de Taxhub ou de UsersHub sur un autre serveur ou une autre base de données et que vous souhaitez installer simplement GeoNature, veuillez suivre la documentation INSTALLATION AUTONOME.

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur linux ``root``.

* Mettre à jour les sources-list (Debian uniquement) : 

A l'installation de l'OS, les sources-list (liste des sources à partir desquelles sont téléchargés les paquets) ne sont pas toujours adaptés. Pour Debian 10, les sources-list par défaut sont compatibles et il n'est donc pas nécessaire de les compléter.

::
        
        nano /etc/apt/sources.list

Coller la liste des dépôts suivants :

Pour Debian 10 :

::

        deb http://deb.debian.org/debian buster main contrib non-free
        deb-src http://deb.debian.org/debian buster main contrib non-free

        deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
        deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free

        deb http://deb.debian.org/debian buster-updates main contrib non-free
        deb-src http://deb.debian.org/debian buster-updates main contrib non-free


* Mettre à jour de la liste des dépôts Linux :

::

    apt-get update
    apt-get upgrade

* Installer sudo :

::

    apt-get install -y sudo ca-certificates
    
* Créer un utilisateur linux (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler en ``root`` :

::

    adduser geonatureadmin

* Lui donner ensuite des droits ``sudo`` :

::

    adduser geonatureadmin sudo

* L'ajouter aussi aux groupes ``www-data`` (Seulement si version < 2.0.0-rc4 -> plus nécessaire après passage à UsersHub v2) :

::

    usermod -g www-data geonatureadmin


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

Passer alors sur l'utilisateur ``geonatureadmin`` avec la commande ``su geonatureadmin`` et exécuter ensuite ces commandes :

::

    export LC_ALL=fr_FR.UTF-8
    export LANGUAGE=fr_FR.UTF-8
    export LANG=fr_FR.UTF-8


Pour la suite de la documentation et pour l'administration courante de GeoNature, **on n'utilisera plus jamais l'utilisateur** ``root`` (utiliser ``geonatureadmin`` dans l'exemple de la documentation; ``su geonatureadmin`` pour change d'utilisateur). Si besoin d'exécuter des commandes avec des droits d'administrateur, on les précède de ``sudo``.

Il est d'ailleurs possible de renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec l'utilisateur ``root``.

Voir https://docs.ovh.com/fr/vps/conseils-securisation-vps/ pour plus d'informations sur le sécurisation du serveur (port SSH, désactiver root, fail2ban, pare-feu, sauvegarde...).

Il est aussi important de configurer l'accès au serveur en HTTPS plutôt qu'en HTTP pour crypter le contenu des échanges entre le navigateur et le serveur (https://docs.ovh.com/fr/hosting/les-certificats-ssl-sur-les-hebergements-web/).

* Se placer à la racine du ``home`` de l'utilisateur puis récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_). Ces scripts installent les applications GeoNature, TaxHub et UsersHub (en option) ainsi que leurs bases de données (uniquement les schémas du coeur) :
 
::

    cd ~
    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.ini
    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.sh

*Attention* : l'installation globale fonctionne uniquement si les scripts sont placés à la racine du ``home`` de l'utilisateur courant.	
	
* Configurez votre installation en adaptant le fichier ``install_all.ini`` :
 
::
    
    nano install_all.ini

Renseignez à minima votre utilisateur linux, l'URL (ou IP) de votre serveur (avec un ``/`` à la fin) ainsi que l'utilisateur PostgreSQL que vous souhaitez et son mot de passe. Le script se chargera d'installer PostgreSQL et de créer l'utilisateur de base de données que vous avez renseigné.

Pour la définition des numéros de version des dépendances, voir le `tableau de compatibilité <versions-compatibility.rst>`_ des versions de GeoNature avec ses dépendances. Il est déconseillé de modifier ces versions, chaque nouvelle version de GeoNature étant fournie avec les versions adaptées de ses dépendances.

* Lancer l'installation :
 
::

    touch install_all.log
    chmod +x install_all.sh
    ./install_all.sh 2>&1 | tee install_all.log

Une fois l'installation terminée, lancez la commande suivante:

::

    exec bash


Les applications sont disponibles aux adresses suivantes :

- http://monip.com/geonature
- http://monip.com/taxhub/
- http://monip.com/usershub (en option)

Vous pouvez vous connecter avec l'utilisateur intégré par défaut (admin/admin).

:Note:

    Pour en savoir plus TaxHub, sa configuration et son utilisation, reportez-vous à sa documentation : https://taxhub.readthedocs.io. Idem pour UsersHub et sa documentation : https://usershub.readthedocs.io
    
:Note:

    * **GeoNature-atlas** : Comme dans la V1, le script ``install_all.sh`` permettra à terme d'installer automatiquement GeoNature-atlas (en option)
    * Une première version de GeoNature-atlas compatible avec GeoNature V2 est disponible : https://github.com/PnEcrins/GeoNature-atlas
    * Vous pouvez utiliser le schéma ``ref_geo`` de GeoNature pour votre territoire, les communes et les mailles, si vous les avez intégré dans ``ref_geo.l_areas`` au préalable.
    
:Note:

    Une version expérimentale du calcul automatique de la sensibilité est disponible : https://github.com/PnX-SI/GeoNature/issues/284

Si vous rencontrez une erreur, se reporter aux fichiers de logs :

- Logs de l'installation de la base de données : ``/home/<MY_USER>/geonature/var/log/install_db.log``
- Log général de l'installation de l'application : ``/home/<MY_USER>/install_all.log``


Si vous souhaitez que GeoNature soit à la racine du serveur, ou à une autre adresse, editez le fichier de configuration Apache (``/etc/apache2/sites-available/geonature.conf``) en modifiant l'alias :

- Pour ``/``: ``Alias / /home/test/geonature/frontend/dist``
- Pour ``/saisie`` : ``Alias /saisie /home/test/geonature/frontend/dist``

:Note:

    Par défaut la base de données est accessible uniquement localement par la machine où elle est installée. Pour y accéder depuis une autre machine (pour s'y connecter avec QGIS, pgAdmin ou autre), ouvrez-en les connexions. Voir la documentation https://github.com/PnEcrins/GeoNature-atlas/blob/master/docs/installation.rst#acc%C3%A9der-%C3%A0-votre-bdd. Attention si vous redémarrez PostgreSQL (``sudo service postgresql restart``), il faut ensuite redémarrer les API GeoNature et TaxHub (``sudo supervisorctl reload``).


Installation d'un module GeoNature
----------------------------------

L'installation de GeoNature n'est livrée qu'avec les schémas de base de données et les modules du coeur (NB : le module Occurrence de Taxon - Occtax - est fourni par défaut). Pour ajouter un gn_module externe, il est nécessaire de l'installer :

**1.** Téléchargez le module depuis son dépôt Github puis dézippez-le dans le repertoire utilisateur, au même niveau que le dossier ``geonature``.

::

    cd /home/`whoami`

**2.** Renseignez l'éventuel fichier ``config/settings.ini`` du module.

**3.** Installez le module. Rendez-vous dans le répertoire ``backend`` de GeoNature et activez le virtualenv pour rendre disponible les commandes GeoNature :

::

    source venv/bin/activate

Lancez ensuite la commande ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>``

Le premier paramètre est l'emplacement absolu du module sur votre serveur et le deuxième est le chemin derrière lequel on accédera au module dans le navigateur.

Exemple pour un module Import :

::

    geonature install_gn_module /home/`whoami`/gn_module_import import

Le module sera disponible à l'adresse ``http://mon-geonature.fr/geonature/#/import``

L'API du module sera disponible à l'adresse ``http://mon-geonature.fr/api/import``

Cette commande exécute les actions suivantes :

- Vérification de la conformité de la structure du module (présence des fichiers et dossiers obligatoires)
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend
- Re-build du frontend pour une mise en production

**4.** Complétez l'éventuelle configuration du module (``config/conf_gn_module.toml``) à partir des paramètres présents dans ``config/conf_gn_module.toml.example`` dont vous pouvez surcoucher les valeurs par défaut. Puis relancez la mise à jour de la configuration (depuis le répertoire ``geonature/backend`` et une fois dans le venv (``source venv/bin/activate``) : ``geonature update_module_configuration nom_du_module``)
