===========
APPLICATION
===========

Configuration de la base de données PostgreSQL
==============================================

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
    
        cd /home/synthese/geonature
        sudo ./install_db.sh
        
* Vous pouvez consulter le log de cette installation de la base dans ``log/install_db.log`` et vérifier qu'aucune erreur n'est intervenue. Attention, ce fichier sera supprimé lors de l'exécution de ``install_app.sh``

* Vous pouvez intégrer l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``

    ::
    
        export PGPASSWORD=monpassachanger; sudo psql -h geonatdbhost -U geonatuser -d geonaturedb -f data/pne/data_sig_pne_2154.sql



Configuration de l'application
==============================

* Se loguer sur le serveur avec l'utilisateur ``synthese``
   

* Installation et configuration de l'application

    ::
    
        cd /home/synthese/geonature
        ./install_app.sh

* Adapter le contenu du fichier ``web/js/config.js``

	- Changer ``mon-domaine.fr`` par votre propre URL (wms_uri, host_uri)
	- Renseigner votre clé API IGN Geoportail ainsi que l'emprise spatiale de votre territoire
	
* Adapter le contenu du fichier ``lib/sfGeonatureConfig.php``. Il indique notamment les identifiants de chaque protocoles, lots et sources de données. 

* Pour tester, se connecter à l'application via http://mon-domaine.fr/geonature avec l'utilisateur et mot de passe : ``admin / admin``

* Si vous souhaitez ajouter des données provenant d'autres protocoles non fournis avec GeoNature, créez leur chacun un schéma dans la BDD de GeoNature correspondant à la structure des données du protocole et ajouté un trigger qui alimentera le schéma ``synthèse`` existant à chaque fois qu'une donnée y est ajoutée ou modifiée. Pour cela vous pouvez vous appuyer sur les exemples existants dans les protocoles fournis (``contactfaune`` par exemple).

* Si vous souhaitez ajouter des protocoles spécifiques dont les formulaires de saisie sont intégrés à votre GeoNature, référez vous à la discussion https://github.com/PnEcrins/GeoNature/issues/54

* Si vous souhaitez désactiver certains programmes dans le critère de recherche COMMENT de l'application Synthèse, décochez leur champs ``actif`` dans la table ``meta.bib_programmes`` (https://github.com/PnEcrins/GeoNature/issues/67)

* Si vous souhaitez ne pas afficher tous les liens vers les formulaires de saisie des protocoles fournis par défaut avec GeoNature, décochez leur champs ``actif`` dans la table ``synthese.bib_sources`` (https://github.com/PnEcrins/GeoNature/issues/69)


Mise à jour de l'application
============================

Les différentes versions sont disponibles sur le Github du projet (https://github.com/PnEcrins/GeoNature/releases).

* Télécharger et extraire la version souhaitée dans un répertoire séparé (où ``X.Y.Z`` est à remplacer par le numéro de la version que vous installez). 

.. code-block:: bash

    cd /home/synthese/
    wget https://github.com/PnEcrins/GeoNature/archive/vX.Y.Z.zip
    unzip vX.Y.Z.zip
    cd GeoNature-X.Y.Z/


* Lire attentivement les notes de chaque version si il y a des spécificités (https://github.com/PnEcrins/GeoNature/releases). Suivre ces instructions avant de continuer la mise à jour.

* Si besoin, vous pouvez aussi vous inspirer des commandes présentes dans le fichier ``install_app.sh`` et les adapter à votre contexte.

* Assurez vous que le fichier ``/etc/hosts`` comporte une entrée ``geonatdbhost``. Ajoutez la si besoin.

* Copier les anciens fichiers de configuration et les comparer avec les nouveaux. Attention, si de nouveaux paramètres ont été ajoutés, ajoutez les dans ces fichiers.

    ::
    
        cp ../version-precedente/config/settings.ini config/settings.ini
        cp ../version-precedente/web/js/config.js web/js/config.js
        cp ../version-precedente/lib/sfGeonatureConfig.php lib/sfGeonatureConfig.php
        cp ../version-precedente/config/databases.yml config/databases.yml
    
    
* Vérifier que votre configuration de connexion à la base de données est correcte dans le fichier ``wms/wms.map``

* Récupérer votre bandeau de l'application si vous l'avez personnalisé

    ::
    
        cp ../version-precedente/web/images/bandeau_geonature.jpg web/images/bandeau_geonature.jpg


* Renommer l'ancien répertoire de l'application GeoNature (/geonature_OLD/ par exemple) puis celui de la nouvelle version (/geonature/ par exemple) pour que le serveur pointe sur la nouvelle version.

* 1.3.0 vers 1.4.0 : Mettez à jour votre base de données (faite impérativement une sauvegarde de votre base de données si elle comporte des données)

    ::
    
        sudo su postgres
        cd /home/synthese/geonature
        psql -h geonatdbhost -U geonatuser -d geonaturedb -f /home/synthese/geonature/data/update_1.3to1.4.sql &> log/update.log

* Si vous avez ajouté des protocoles spécifiques dans GeoNature (https://github.com/PnEcrins/GeoNature/issues/54), il vous faut les récupérer dans la nouvelle version. 
Commencez par copier les modules Symfony correspondants dans le répertoire de la nouvelle version de GeoNature. 
Il vous faut ensuite reporter les modifications réalisées dans les parties qui ne sont pas génériques 
(module Symfony ``bibs``, le fichier de routing, la description de la BDD dans le fichier ``config/doctrine/schema.yml`` et l'appel des JS et CSS dans ``apps/backend/modules/home/config/view.yml``).


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


Une fois que votre commande est prête, saisissez la valeur de la clé IGN reçue dans le fichier ``web/js/config.js``.
