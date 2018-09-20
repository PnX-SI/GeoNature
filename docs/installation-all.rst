INSTALLATION GLOBALE
====================

Prérequis
---------

- Ressources minimum serveur :

Un serveur Linux disposant d’au moins de 2 Go RAM et de 20 Go d’espace disque.

Le script global d'installation de GeoNature va aussi se charger d'installer les dépendances nécessaires : 

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 4, Angular CLI, NodeJS
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

Configuration de la locale du serveur
""""""""""""""""""""""""""""""""""""""

Certains serveurs sont livrés sans "locale" (langue par défaut). Pour l'installation de GeoNature, il est necessaire de bien configurer la locale.

Depuis l'utilisateur ``root``, exécuter la commande ``dpkg-reconfigure locales``. Une fenêtre s'affiche dans votre console. Dans la liste déroulante, sélectionnez ``fr_FR.UTF-8 UTF-8``, puis cliquez sur OK. Une 2ème fenêtre s'affiche avec une liste de locale activées (``fr_FR.UTF-8`` doit être présent dans la liste), confirmez votre choix, en cliquant sur OK, puis attendez que la locale s'installe.


Installation de l'application
-----------------------------

Ce document décrit une procédure d'installation packagée de GeoNature.

En lançant le script d'installation ci-dessous, l'application GeoNature ainsi que ses dépendances seront installées sur un seul et même serveur au sein d'une seule base de données.

Les applications suivantes seront installées :

- GeoNature
- `TaxHub <https://github.com/PnX-SI/TaxHub>`_ qui pilote le schéma ``taxonomie``
- `UsersHub <https://github.com/PnEcrins/UsersHub>`_ qui pilote le schéma ``utilisateurs`` (le paramètre ``install_usershub_app`` du fichier de configuration ``install_all.ini`` permet de désactiver l'installation de l'application. Il est cependant recommandé d'installer l'application pour disposer d'une interface pour gérer les utilisateurs dans GeoNature)

Si vous disposez déjà de Taxhub ou de UsersHub sur un autre serveur ou une autre base de données et que vous souhaitez installer simplement GeoNature, veuillez suivre cette `documentation <https://github.com/PnX-SI/GeoNature/blob/install_all/docs/installation_standalone.rst>`_

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur linux ``root``.

* Mettre à jour les sources-list : 

A l'installation de l'OS, les sources-list (liste des sources à partir desquelles sont téléchargés les paquets) ne sont pas toujours correctes.

::
        
        nano /etc/apt/sources.list

Coller la liste des dépôts suivants :

Pour Debian 9 :

::

        deb http://security.debian.org/debian-security stretch/updates main contrib non-free
        deb-src http://security.debian.org/debian-security stretch/updates main contrib non-free
        deb http://deb.debian.org/debian/ stretch-updates main contrib non-free
        deb-src http://deb.debian.org/debian/ stretch-updates main contrib non-free
        deb http://deb.debian.org/debian stretch main contrib non-free
        deb-src http://deb.debian.org/debian stretch main contrib non-free

Pour Debian 8 :

::

        deb http://deb.debian.org/debian/ jessie main contrib non-free
        deb http://security.debian.org/ jessie/updates main contrib non-free
        deb http://deb.debian.org/debian/ jessie-updates main contrib non-free

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

* L'ajouter aussi aux groupes ``www-data`` et ``root`` :

::

    usermod -g www-data geonatureadmin


Se reconnecter en SSH au serveur avec le nouvel utilisateur pour ne pas faire l'installation en ``root``.

On ne se connectera plus en ``root``. Si besoin d'exécuter des commandes avec des droits d'administrateur, on les précède de ``sudo``.

Il est d'ailleurs possible de renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec ``root``.

Voir https://docs.ovh.com/fr/vps/conseils-securisation-vps/ pour plus d'informations sur le sécurisation du serveur (port SSH, désactiver root, fail2ban, pare-feu, sauvegarde...).

Il est aussi important de configurer l'accès au serveur en HTTPS plutôt qu'en HTTP pour crypter le contenu des échanges entre le navigateur et le serveur (https://docs.ovh.com/fr/hosting/les-certificats-ssl-sur-les-hebergements-web/).

* Récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_). Ces scripts installent les applications GeoNature, TaxHub et UsersHub (en option) ainsi que leurs bases de données (uniquement les schémas du coeur) :
 
::
    
    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.ini
    wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/install_all/install_all.sh
	
	
* Configurez votre installation en adaptant le fichier ``install_all.ini`` :
 
::
    
    nano install_all.ini

Renseignez à minima votre utilisateur linux, l'URL (ou IP) de votre serveur (avec un ``/`` à la fin) ainsi que l'utilisateur PostgreSQL que vous souhaitez et son mot de passe.

Pour la définition des numéros de version des dépendances, voir le `tableau de compatibilité <versions-compatibility.rst>`_ des versions de GeoNature avec ses dépendances. Il est déconseillé de modifier ces versions, chaque nouvelle version de GeoNature étant fournie avec les versions adaptées de ses dépendances.

* Lancer l'installation :
 
::
    
    chmod +x install_all.sh
    ./install_all.sh

Une fois l'installation terminée, les applications sont disponibles aux adresses suivantes :

- http://monip.com/geonature
- http://monip.com/taxhub/
- http://monip.com/usershub (en option)

Vous pouvez vous connecter avec l'utilisateur intégré par défaut (admin/admin).


Si vous rencontrez une erreur, se reporter aux fichiers de logs :

- Logs de l'installation de la base de données : ``/home/myuser/geonature/var/log/geonature/install_db.log``
- Log général de l'installation de l'application : ``/home/myuser/var/log/geonature/install_app.log``


Si vous souhaitez que GeoNature soit à la racine du serveur, ou à une autre adresse, editez le fichier de configuration Apache (``/etc/apache2/sites-available/geonature.conf``) en modifiant l'alias :

- Pour ``/``: ``Alias / /home/test/geonature/frontend/dist``
- Pour ``/saisie`` : ``Alias /saisie /home/test/geonature/frontend/dist``


Installation d'un module GeoNature
----------------------------------

L'installation de GeoNature n'est livrée qu'avec les schémas de base de données et les modules du coeur (NB : le module Occurrence de Taxon - Occtax - est fourni par défaut). Pour ajouter un gn_module externe, il est nécessaire de l'installer :

Rendez-vous dans le répertoire ``backend`` de GeoNature et activez le virtualenv pour rendre disponible les commandes GeoNature :

::

    source venv/bin/activate

Lancez ensuite la commande ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>``

Le premier paramètre est l'emplacement absolu du module sur votre serveur et le deuxième est le chemin derrière lequel on accédera au module dans le navigateur.

Exemple pour un module de validation :

::

    geonature install_gn_module /home/gn_module_validation validation

Le module sera disponible à l'adresse ``http://mon-geonature.fr/geonature/validation``

L'API du module sera disponible à l'adresse ``http://mon-geonature.fr/api/geonature/validation``

Cette commande éxecute les actions suivantes :

- Vérification de la conformité de la structure du module (présence des fichiers et dossiers obligatoires)
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend
- Re-build du frontend pour une mise en production
