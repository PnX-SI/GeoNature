===========
APPLICATION
===========

Configuration de la base de données PostgreSQL
==============================================

* mettre à jour le fichier ``config/settings.ini``

    :: nano config/settings.ini

Renseigner le nom de la base de données, les utilisateurs PostgreSQL et les mots de passe. Il est possible mais non conseillé de laisser les valeurs proposées par défaut. 

ATTENTION : Les valeurs renseignées dans ce fichier sont utilisées par le script d'installation de la base de données ``install_db.sh``. Les utilisateurs PostgreSQL doivent être en concordance avec ceux créés lors de la dernière étape de l'installation serveur ``Création de 2 utilisateurs PostgreSQL``. 


Création de la base de données
==============================

* Création de la base de données et chargement des données initiales

    ::
    
        cd /home/synthese/geonature
        sudo ./install_db.sh

* Si besoin, l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``
  
  ::

    export PGPASSWORD=monpassachanger;psql -h geonatdbhost -U geonatuser -d geonaturedb -f pne/data_sig_pne_2154.sql 


Configuration de l'application
==============================

* Se loguer sur le serveur avec l'utilisateur synthese
   

* Installation et configuration de l'application

    ::
    
        cd /home/synthese/geonature
        ./install_app.sh

* Adapter le contenu du fichier web/js/config.js
  ** Changer mon-domaine.fr par votre propre url (wms_uri, host_uri)
  ** Renseigner sa clé ign du géoportail ainsi que l'emprise spatiale de votre territoire

* Pour tester, se connecter à l'application via http://mon-domaine.fr/geonature et les login et pass admin/admin

Mise à jour de l'application
----------------------------

* Suivre les instructions disponibles dans la doc de la release choisie


Clé IGN
=======
Commander une clé IGN de type : Licence géoservices IGN pour usage grand public - gratuite
Avec les couches suivantes : 

* WMTS-Géoportail - Orthophotographies

* WMTS-Géoportail - Parcelles cadastrales

* WMTS-Géoportail - Cartes IGN

Pour cela, il faut que vous disposiez d'un compte IGN pro. (http://professionnels.ign.fr)
Une fois connecté au site: 

* aller dans nouvelle commande

* choisir Géoservices IGN : Pour le web dans la rubrique "LES GÉOSERVICES EN LIGNE"

* cocher l'option "Pour un site internet grand public"

* cocher l'option "Licence géoservices IGN pour usage grand public - gratuite"

* saisir votre url. Attention, l'adresse doit être précédée de http://

* Finisser votre commande en selectionnant les couches d'intéret et en acceptant les différentes licences.


Une fois que votre commande est prète saisissez la valeur de la clé IGN reçue dans le fichier web/js/config.js


