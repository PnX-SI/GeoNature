=============================
INSTALLATION DE L'APPLICATION
=============================


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

	* Installation du schéma du module dans la base de données Exemple pour le module contact faune.
 
  ::  
  
        sudo ./data/modules/contact/install_schema.sh
