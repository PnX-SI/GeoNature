=============================
INSTALLATION DE L'APPLICATION
=============================

Prérequis
=========

* Environnement serveur :

Voir le guide d'installation du serveur (http://geonature.readthedocs.org/fr/latest/server.html)

* Disposer d'un utilisateur linux nommé par exemple ``synthese``. Dans ce guide, le répertoire de cet utilisateur est dans ``/home/synthese``

* Se loguer sur le serveur avec l'utilisateur ``synthese`` ou tout autre utilisateur linux faisant partie du groupe www-data.

* Récupérer le zip de l’application sur le Github du projet (`X.Y.Z à remplacer par le numéro de version souhaitée <https://github.com/PnEcrins/GeoNature/releases>`_), dézippez le dans le répertoire de l'utilisateur linux du serveur puis copiez le dans le répertoire de l’utilisateur linux :
 
  ::  
  
        cd /home/synthese
        wget https://github.com/PnEcrins/GeoNature/archive/vX.Y.Z.zip
        unzip vX.Y.Z.zip
        mv GeoNature-X.Y.Z/ geonature/


Configuration Apache
====================
* Adaptation des chemins de l'application pour la configuration Apache

Editer les fichiers de configuration Apache : ``apache/sf.conf``, ``apache/synthese.conf`` et ``apache/wms.conf`` et adapter les chemins à ceux de votre serveur.

* Prise en compte de la configuration Apache requises pour Symfony :
 
  ::  
  
	sudo sh -c 'echo "Include /home/synthese/geonature/apache/*.conf" >> /etc/apache2/apache2.conf'
	sudo apache2ctl restart
        
* Pour les utilisateurs d'Apache 2.4 (par défaut dans Debian 8), installer perl et cgi
 
  ::  
  
    	sudo apt-get install libapache2-mod-perl2
	sudo a2enmod cgi
	sudo apache2ctl restart
	

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

ATTENTION : Les valeurs renseignées dans ce fichier sont utilisées par le script d'installation de la base de données ``install_db.sh``. Les utilisateurs PostgreSQL doivent être en concordance avec ceux créés lors de la dernière étape de l'installation du serveur (Création de 2 utilisateurs PostgreSQL). 


Création de la base de données
==============================

* Création de la base de données et chargement des données initiales
 
  ::  
  
        sudo ./install_db.sh
        
* Vous pouvez consulter le log de cette installation de la base dans ``log/install_db.log`` et vérifier qu'aucune erreur n'est intervenue. **Attention, ce fichier sera supprimé** lors de l'exécution de ``install_app.sh``

* Vous pouvez intégrer l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``
 
  ::  
  
        export PGPASSWORD=monpassachanger; sudo psql -h geonatdbhost -U geonatuser -d geonaturedb -f data/pne/data_sig_pne_2154.sql


Configuration de l'application
==============================

* Lancer le fichier d'installation et de préparation de la configuration de l'application
 
  ::  
  
        ./install_app.sh

* Adapter le contenu du fichier ``web/js/config.js``

	- Changer ``mon-domaine.fr`` par votre propre URL (wms_uri, host_uri)
    
* Adapter le contenu du fichier ``web/js/configmap.js``

    - Renseigner votre clé API IGN Geoportail, 
    - l'extent max de l'affichage cartographique, le centrage initial, le nombre maximum de niveau de zoom de la carte, la résolution maximale (en lien avec le paramètre précédent et le tableau ``ign_resolutions``)
    - Renseigner le système de coordonnées et la bbox des coordonnées utilisable pour le positionnement du pointage par coordonnées fournies (GPS)
	
* Adapter le contenu du fichier ``lib/sfGeonatureConfig.php``. Il indique notamment les identifiants de chaque protocoles, lots et sources de données. 

* Pour tester, se connecter à l'application via http://mon-domaine.fr/geonature avec l'utilisateur et mot de passe : ``admin / admin``

* Si vous souhaitez ajouter des données provenant d'autres protocoles non fournis avec GeoNature, créez leur chacun un schéma dans la BDD de GeoNature correspondant à la structure des données du protocole et ajouté un trigger qui alimentera le schéma ``synthèse`` existant à chaque fois qu'une donnée y est ajoutée ou modifiée. Pour cela vous pouvez vous appuyer sur les exemples existants dans les protocoles fournis (``contactfaune`` par exemple).

* Si vous souhaitez ajouter des protocoles spécifiques dont les formulaires de saisie sont intégrés à votre GeoNature, référez vous à la discussion https://github.com/PnEcrins/GeoNature/issues/54

* Si vous souhaitez désactiver certains programmes dans le critère de recherche COMMENT de l'application Synthèse, décochez leur champs ``actif`` dans la table ``meta.bib_programmes`` (https://github.com/PnEcrins/GeoNature/issues/67)

* Si vous souhaitez ne pas afficher tous les liens vers les formulaires de saisie des protocoles fournis par défaut avec GeoNature, décochez leur champs ``actif`` dans la table ``synthese.bib_sources`` (https://github.com/PnEcrins/GeoNature/issues/69)


Clé API IGN Geoportail
======================

L'API IGN Geoportail permet d'afficher les fonds IGN dans GeoNature directement depuis le Geoportail.

Si vous êtes un établissement public, commandez une clé IGN de type : Licence géoservices IGN pour usage grand public - gratuite.

Selectionner les couches suivantes : 

* WMTS-Géoportail - Orthophotographies
* WMTS-Géoportail - Parcelles cadastrales
* WMTS-Géoportail - Cartes IGN

Pour cela, il faut que vous disposiez d'un compte IGN pro. (http://professionnels.ign.fr)
Une fois connecté au site: 

* Aller dans "Nouvelle commande"
* Choisir "Géoservices IGN : Pour le web" dans la rubrique "LES GÉOSERVICES EN LIGNE"
* Cocher l'option "Pour un site internet grand public"
* Cocher l'option "Licence géoservices IGN pour usage grand public - gratuite"
* Saisir votre URL. Attention, l'adresse doit être précédée de ``http://`` (même si il s'agit d'une IP)
* Finir votre commande en selectionnant les couches utiles :

    - Alticodage, 
    - WMTS-Géoportail - Cartes IGN, 
    - WMTS-Géoportail - Limites administratives, 
    - WMTS-Géoportail - Orthophotographies
    - WMTS-Géoportail - Parcelles cadastrales

Une fois que votre commande est prête, saisissez la valeur de la clé IGN dans le fichier ``web/js/configmap.js``.
