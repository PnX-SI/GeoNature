=============================
INSTALLATION DE L'APPLICATION
=============================

Prérequis
=========

- Ressources minimum serveur :

Un serveur Linux disposant d’au moins de 2 Go RAM et de 20 Go d’espace disque.

L'installation complète de l'environnement est réalisée automatiquement sur un serveur Debian 9 vierge grace au script ``install_app.sh``.

Celui-ci installe : 

- PostgreSQL / PostGIS
- Python 3 et dépendances Python nécessaires à l'application
- Flask (framework web Python)
- Apache
- Angular 4, Angular CLI, NodeJS
- Librairies javascript (Leaflet, ChartJS)
- Librairies CSS (Bootstrap, Material Design)

Installation de l'application
=============================

/!\ A mettre à jour. Install_all en cours : https://github.com/PnX-SI/GeoNature/tree/frontend-contact/install_all

Commencer la procédure en se connectant au serveur en SSH avec l'utilisateur linux ROOT.

* Mettre à jour de la liste des dépôts Linux
 
  ::  
  
        apt-get update

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

* Récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_) :
 
  ::  
  
        wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install_app.ini
        wget https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install_all.sh

* Changer les droits du fichier d'installation pour pouvoir l'éxecuter
 
  ::  
  
        chmod +x install_all.sh
	
Se reconnecter en SSH au serveur avec le nouvel utilisateur pour ne pas faire l'installation en ROOT.

On ne se connectera plus en ROOT. Si besoin d'executer des commandes avec des droits d'administrateur, on les précède de ``sudo``.

Il est d'ailleurs possible renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec ROOT.

Voir https://docs.ovh.com/pages/releaseview.action?pageId=18121864 pour plus d'informations sur le sécurisation du serveur. 

* Lancer l'installation
 
  ::  
  
        ./install_all.sh

Pendant l'installation, vous serez invité à renseigner le fichier de configuration ``install_app.ini``.

Une fois l'installation terminée, lancez:

  :: 

	sudo ng build --base-href /geonature/

Les applications sont disponibles aux adresses suivantes: 

	- http://monip.com/geonature
	- http://monip.com/taxhub

Configuration de la base de données PostgreSQL
==============================================

* Se positionner dans le répertoire de l'application ; par exemple ``geonature`` :
 
  ::  
  
	cd geonature
        
* Copier et renommer le fichier ``config/settings.ini.sample`` en ``config/settings.ini`` :
 
  ::  
  
        cp config/settings.ini.sample config/settings.ini

* Mettre à jour le fichier ``config/settings.ini`` avec vos paramètres de connexion à la BDD :
 
  ::  
  
	nano config/settings.ini

Renseigner le nom de la base de données, les utilisateurs PostgreSQL et les mots de passe. Il est possible mais non conseillé de laisser les valeurs proposées par défaut. 

La projection locale peut être modifiée si vous n'êtes pas en métropole. Attention : les couches SIG ainsi que le jeu de données fournis avec l'application sont tous en lambert 93 (2154). Pour ne pas les insérer lors de la création de la base, vous devez mettre les paramètres ``install_sig_layers`` et ``add_sample_data`` à ``false``. 

Si vous êtes en métropole, il est conseillé de laisser la projection officielle en Lambert 93 (2154) et d'insérer au moins les couches SIG fournies.

ATTENTION : Les valeurs renseignées dans ce fichier sont utilisées par les scripts d'installation de la base de données ainsi que par le script d'installation de l'application ``install_app.sh``. Les utilisateurs PostgreSQL doivent être en concordance avec ceux créés lors de la dernière étape de l'installation du serveur (Création de 2 utilisateurs PostgreSQL). 


Création de la base de données
==============================

* Création de la partie coeur de la base de données. Ceci installe le schéma ``taxonomie``, le schéma ``utilisateurs``, le schéma ``synthese`` ainsi que toutes les informations nécessaires au bon fonctionnement de GeoNature. Le contenu de Taxref est inséré. Vous pouvez gérer la taxonomie à l'aide des applications TaxHub et les utilisateurs avec l'application UsersHub. Pour installer un module, voir la partie ``Modules" ci-après.
 
  ::  
  
        sudo ./install_db.sh
        
* Vous devez consulter le log de cette installation de la base dans ``log/install_db.log`` et vérifier qu'aucune erreur n'est intervenue. **Attention, ce fichier sera supprimé** lors de l'exécution de ``install_app.sh``

* Vous pouvez intégrer l'exemple des données SIG du Parc national des Ecrins des tables ``layers.l_unites_geo``:
 
  ::  
  
        export PGPASSWORD=monpassachanger; sudo psql -h localhost -U mypguser -d geonature2db -f data/pne/data_sig_pne_2154.sql


Installation d'un module
========================

* Installation du schéma du module dans la base de données. Exemple pour le module contact faune.
 
  ::  
  
	sudo ./data/modules/contact/install_schema.sh


Mise en place du backend et du front end (doc developpeur)
==========================================

* Installation du backend.
 
  ::  
  
        cd
        cd geonature/backend/
        ./install_app.sh


* Installation du sous-module en mode develop. On assume que le sous-module est installé au même niveau que GeoNature, dans le répertoire `home` de l'utilisateur
 
  ::  
  
        cd
        git clone https://github.com/PnX-SI/Nomenclature-api-module.git nomenclature-api-module
        cd nomenclature-api-module/
        source ../geonature/backend/venv/bin/activate
        cp ../geonature/backend/config.py.sample ../geonature/backend/config.py
        python setup.py develop
        cd ../geonature2/backend/
        make develop
        deativate
* Lancer le front end
Depuis le répertoire ``frontend`` lancer la commande: 

  :: 

	npm run start
