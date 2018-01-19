INSTALLATION DE L'APPLICATION
=============================

Prérequis
---------

- Ressources minimum serveur :

Un serveur Linux disposant d’au moins de 2 Go RAM et de 20 Go d’espace disque.


Le script global d'installation de GeoNature va aussi se charger d'installer les applications nécessaires : 

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

Installation de l'application
-----------------------------

* Se placer dans le répertoire de l'utilisateur (``/home/geonatadmin/`` dans notre cas) 
* Récupérer l'application (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnX-SI/GeoNature/releases>`_). La version 2 de GeoNature est actuellement en cours de developpement. Elle n'est pas encore stable et se trouve sur la branche develop (remplacer ``X.Y.Z`` par ``develop``).

::

    wget https://github.com/PnX-SI/GeoNature/archive/X.Y.Z.zip

* Dézipper l'archive de l'application

::

    unzip GeoNature-X.Y.Z.zip

* Renommez le répertoire de l'application puis placez-vous dedans : 

::

    cd GeoNature

* Copier puis mettre à jour le fichier de configuration (``config/settings.ini``) comportant les informations relatives à votre environnement serveur :

::

    cp config/settings.ini.sample config/settings.ini
    nano config/settings.ini

* Création de la base de données.
Pendant l'installation, vous serez invité à fournir le mot de pass sudo.

::

    ./install_db.sh

* Installation de l'application

La commande ``install_db.sh`` comporte deux paramètres optionnels qui doivent être utilisés dans l'ordre :

* -s ou --settings-path pour spécifier un autre emplacement pour le fichier ``settings.ini``
* -d ou --dev permet d'installer des dépendances python utile pour le développement de GeoNature
* -h ou --help affiche l'aide pour cette commande ``install_app.sh``

::

    ./install_app.sh

Pendant l'installation, vous serez invité à fournir le mot de pass sudo.

Une fois l'installation terminée, lancez :

::

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

L'application est disponible à l'adresse suivante:

- http://monip.com/geonature

Si vous souhaitez que GeoNature soit à racine du serveur, ou à une autre adresse, lancer la commande:

- Pour ``/``: ``npm run build -- --base-href=/``
- Pour ``/saisie`` : ``npm run build -- --base-href=/saisie/``


Editez ensuite le fichier de configuration Apache ``/etc/apache2/sites-available/geonature.conf`` en modifiant "l'alias":

- Pour ``/`` : ``Alias / /home/test/geonature/frontend/dist``
- Pour ``/saisie``: ``Alias /saisie /home/test/geonature/frontend/dist``


Installation d'un module GeoNature
----------------------------------

L'installation de GeoNature n'est livrée qu'avec les schémas de base de données du coeur. Pour ajouter un nouveau module, il est necessaire de l'installer :

* Exemple d'installation en base de données du module OccTax.

::

    data/modules/contact/install_schema.sh

Dépendances
-----------

Lors de l'installation de la BDD (``install_db.sh``) le schéma ``utilisateurs`` de UsersHub et le schéma ``taxonomie`` de TaxHub sont intégrés automatiquement dans la BDD de GeoNature. 

UsersHub n'est pas nécessaire au fonctionnement de GeoNature mais il sera utile pour avoir une interface de gestion des utilisateurs, des groupes et de leurs droits. 

Par contre il est nécessaire d'installer TaxHub (https://github.com/PnX-SI/TaxHub) pour que GeoNature fonctionne. En effet, GeoNature utilise l'API de TaxHub. Une fois GeoNature installé, il vous faut donc installer TaxHub en le connectant à la BDD de GeoNature, vu que son schéma ``taxonomie`` a déjà été installé par le ``install_db.sh`` de GeoNature. Lors de l'installation de TaxHub, n'installer donc que l'application et pas la BDD.

A VENIR : On remettra sur pied le script INSTALL_ALL prochainement pour automatiser et packager tout cela. 
