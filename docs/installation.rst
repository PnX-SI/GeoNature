=============================
INSTALLATION DE L'APPLICATION
=============================

Cette procédure décrit l'installation de l'application GeoNature seule. Il est aussi possible d'installer plus facilement GeoNature et tout son environnement (UsersHub, TaxHub et GeoNature-atlas) avec le script ``install_all`` (voir chapitre INSTALLATION GLOBALE).

Prérequis
=========

* Environnement serveur :

Voir le chapitre sur l'installation du serveur (http://geonature.readthedocs.org/fr/latest/server.html)

* Disposer d'un utilisateur linux nommé par exemple ``synthese``. Dans ce guide, le répertoire de cet utilisateur est dans ``/home/synthese``

* Se loguer sur le serveur avec l'utilisateur ``synthese`` ou tout autre utilisateur linux faisant partie du groupe www-data.

* Récupérer le zip de l’application sur le Github du projet (`X.Y.Z à remplacer par le numéro de version souhaitée <https://github.com/PnEcrins/GeoNature/releases>`_), dézippez le dans le répertoire de l'utilisateur linux du serveur puis copiez le dans le répertoire de l’utilisateur linux :
 
  ::  
  
        cd /home/synthese
        wget https://github.com/PnEcrins/GeoNature/archive/X.Y.Z.zip
        unzip X.Y.Z.zip
        mv GeoNature-X.Y.Z/ geonature/


Configuration Apache
====================
* Adaptation des chemins de l'application pour la configuration Apache

Editer les fichiers de configuration Apache : ``apache/sf.conf``, ``apache/synthese.conf`` et ``apache/wms.conf`` et adapter les chemins à ceux de votre serveur. Pour Apache 2.4 et supérieur, le répertoire de publication web par défaut est ``/var/www/html/geonature`` ; à changer dans ``apache/synthese.conf``.

* Prise en compte de la configuration Apache requises pour Symfony (avant Apache2.4) (debian 7):
 
  ::  
  
	sudo sh -c 'echo "Include /home/synthese/geonature/apache/*.conf" >> /etc/apache2/apache2.conf'
	sudo apache2ctl restart
        
* Prise en compte de la configuration Apache requises pour Symfony Apache 2.4 et supérieur (debian 8 et 9):
 
  ::  
  
	sudo sh -c 'echo "IncludeOptional /home/synthese/geonature/apache/*.conf" >> /etc/apache2/apache2.conf'
	sudo apache2ctl restart
        
* Pour les utilisateurs d'Apache 2.4 (par défaut dans Debian 8 et 9), activiver le module cgi
 
  ::  
  
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

La projection locale peut être modifiée si vous n'êtes pas en métropole. Attention : les couches SIG ainsi que le jeu de données fournis avec l'application sont tous en lambert 93 (2154). Pour ne pas les insérer lors de la création de la base, vous devez mettre les paramètres ``install_sig_layers`` et ``add_sample_data`` à ``false``. 

Si vous êtes en métropole, il est conseillé de laisser la projection officielle en Lambert 93 (2154) et d'insérer au moins les couches SIG fournies.

ATTENTION : Les valeurs renseignées dans ce fichier sont utilisées par le script d'installation de la base de données ``install_db.sh`` ainsi que par le script d'installation de l'application ``install_app.sh``. Les utilisateurs PostgreSQL doivent être en concordance avec ceux créés lors de la dernière étape de l'installation du serveur (Création de 2 utilisateurs PostgreSQL). 


Création de la base de données
==============================

* Création de la base de données et chargement des données initiales
 
  ::  
  
        sudo ./install_db.sh
        
* Vous pouvez consulter le log de cette installation de la base dans ``log/install_db.log`` et vérifier qu'aucune erreur n'est intervenue. **Attention, ce fichier sera supprimé** lors de l'exécution de ``install_app.sh``

* Vous pouvez intégrer l'exemple des données SIG du Parc national des Ecrins des tables ``layers.l_unites_geo``, ``layers.l_aireadhesion`` et ``layers.l_secteurs``) :
 
  ::  
  
        export PGPASSWORD=monpassachanger; sudo psql -h localhost -U geonatuser -d geonaturedb -f data/pne/data_sig_pne_2154.sql


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
  - Renseigner le système de coordonnées et la bbox des coordonnées utilisables pour le positionnement du pointage par coordonnées fournies (GPS)
	
* Adapter le contenu du fichier ``lib/sfGeonatureConfig.php``. Il indique notamment les identifiants de chaque protocoles, lots et sources de données. 

* Pour tester, se connecter à l'application via http://mon-domaine.fr/geonature avec l'utilisateur et mot de passe : ``admin / admin``

* Si vous souhaitez ajouter des données provenant d'autres protocoles non fournis avec GeoNature, créez leur chacun un schéma dans la BDD de GeoNature correspondant à la structure des données du protocole et ajoutez un trigger qui alimentera le schéma ``synthese`` existant à chaque fois qu'une donnée y est ajoutée ou modifiée. Pour cela vous pouvez vous appuyer sur les exemples existants dans les protocoles fournis (``contactfaune`` par exemple).

* Si vous souhaitez ajouter des protocoles spécifiques dont les formulaires de saisie sont intégrés à votre GeoNature, référez-vous à la discussion https://github.com/PnEcrins/GeoNature/issues/54

* Si vous souhaitez désactiver certains programmes dans le critère de recherche COMMENT de l'application Synthèse, décochez leur champs ``actif`` dans la table ``meta.bib_programmes`` (https://github.com/PnEcrins/GeoNature/issues/67)

* Si vous souhaitez ne pas afficher tous les liens vers les formulaires de saisie des protocoles fournis par défaut avec GeoNature, décochez leur champs ``actif`` dans la table ``synthese.bib_sources`` (https://github.com/PnEcrins/GeoNature/issues/69)


Clé API IGN Geoportail
======================

L'API IGN Geoportail permet d'afficher les fonds IGN dans GeoNature directement depuis le Geoportail.

Si vous êtes un établissement public, commandez une clé IGN de type : Licence géoservices IGN pour usage grand public - gratuite.

Selectionner les couches suivantes : 

* Alticodage, 
* WMTS-Géoportail - Cartes IGN, 
* WMTS-Géoportail - Limites administratives
* WMTS-Géoportail - Orthophotographies
* WMTS-Géoportail - Parcelles cadastrales

Pour cela, il faut que vous disposiez d'un compte IGN pro (http://professionnels.ign.fr).

Une fois connecté au site : 

* Se rendre sur la Page Géoservices : http://professionnels.ign.fr/geoservices
* Choisir "Services de visualisation" puis cliquer sur "S'abonner"
* Saisir le "Titre du contrat" (ex. : "GeoNature") et choisir "Choix du géoservice" (N°2 ou N°4 si vous n'avez pas encore de domaine)
* Choisir la "Quantité d'usage" (nombre de transactions, gratuit jusqu'à 100000 transactions pour la mission de service public)
* Choisir le "Type de sécurisation" (Referer) et saisir la "Valeur de sécurisation" = URL de l'application (Attention, l’adresse doit être précédée de "http://", même si il s’agit d’une IP)
* Choisir les ressources dans le catalogue parmi ces rubriques : 

  - Ressources d'images tuilées WMTS du Géoportail en WebMercator (non superposables aux ressources en Lambert-93)
  - Ressources altimétriques du Géoportail
  
* Ajouter la commande au panier
* Valider l'ensemble des licences du panier et cliquer sur "Poursuivre la commande", accepter les Conditions Générales de Vente, et Validez la commande

Une fois que votre commande est prête, saisissez la valeur de la clé IGN dans le fichier ``web/js/configmap.js``.
