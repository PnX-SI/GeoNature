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
        
* Vous pouvez consulter le log de cette installation de la base dans ``log/install_db.log`` et vérifier qu'aucune erreur n'est intervenue. Attention, ce fichier sera supprimé lors de l'exécution de ``install_ap.sh``

* Si besoin, l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma layers

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
	- Renseigner votre clé IGN Geoportail ainsi que l'emprise spatiale de votre territoire
	
    
* Adapter le contenu du fichier ``lib/sfGeonatureConfig.php``. Il indique notamment les identifiants de chaque protocoles, lots et sources de données. 


* Pour tester, se connecter à l'application via http://mon-domaine.fr/geonature avec l'utilisateur et mot de passe : ``admin/admin``


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

* Copier les anciens fichiers de configuration et les charger dans le nouveau répertoire de l'application (``version-precedente`` est à modifier par le nom du répertoire où était installé votre application GeoNature).

::

    # Fichiers de configuration
    cp ../version-precedente/config/settings.ini config/settings.ini
    cp ../version-precedente/conf/web/js/config.js web/js/config.js
    cp ../version-precedente/conf/lib/sfGeonatureConfig.php lib/sfGeonatureConfig.php

    # Bandeau de l'application
    cp ../version-precedente/web/images/bandeau_faune.jpg web/images/bandeau_faune.jpg

* Renommer l'ancien répertoire de l'application GeoNature (/geonature_OLD/ par exemple) puis celui de la nouvelle version (/geonature/ par exemple) pour que le serveur pointe sur la nouvelle version.


Clé IGN
=======
Si vous êtes un établissement public, commandez une clé IGN de type : Licence géoservices IGN pour usage grand public - gratuite
Avec les couches suivantes : 

* WMTS-Géoportail - Orthophotographies

* WMTS-Géoportail - Parcelles cadastrales

* WMTS-Géoportail - Cartes IGN

Pour cela, il faut que vous disposiez d'un compte IGN pro. (http://professionnels.ign.fr)
Une fois connecté au site: 

* aller dans "Nouvelle commande"

* choisir "Géoservices IGN : Pour le web" dans la rubrique "LES GÉOSERVICES EN LIGNE"

* cocher l'option "Pour un site internet grand public"

* cocher l'option "Licence géoservices IGN pour usage grand public - gratuite"

* saisir votre url. Attention, l'adresse doit être précédée de ``http://`` (même si il s'agit d'une IP)

* Finir votre commande en selectionnant les couches d'intéret et en acceptant les différentes conditions.


Une fois que votre commande est prête, saisissez la valeur de la clé IGN reçue dans le fichier ``web/js/config.js``.
