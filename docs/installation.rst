============
INSTALLATION
============
Création de la base de données
===================================

* Création de la base de données et chargement des données initiales

    ::
    
        cd /home/synthese/dev/FF-synthese/data/inpn
        tar -xzvf data_inpn_v7.tar.gz 
        
        su postgres
        cd /home/synthese/dev/FF-synthese/data
        createdb -O cartopnx synthese
        psql -d synthese -c "CREATE EXTENSION postgis;"
        psql -d synthese -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';"
        export PGPASSWORD=monpassachanger;psql -h databases -U cartoadmin -d synthese -f grant.sql
        export PGPASSWORD=monpassachanger;psql -h databases -U cartopnx -d synthese -f 2154/synthese_2154.sql
        export PGPASSWORD=monpassachanger;psql -h databases -U cartoadmin -d synthese -f inpn/data_inpn_v7_synthese.sql
        export PGPASSWORD=monpassachanger;psql -h databases -U cartopnx -d synthese -f 2154/data_synthese_2154.sql
        export PGPASSWORD=monpassachanger;psql -h databases -U cartopnx -d synthese -f 2154/data_set_synthese_2154.sql
        exit
        
        rm taxref*

* Si besoin l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``
  
  ::

    export PGPASSWORD=monpassachanger;psql -h databases -U cartopnx -d synthese -f pne/data_sig_pne_2154.sql 



Installation de l'application
=============================

* Se loguer sur le serveur avec l'utilisateur synthese
   

* Configuration du répertoire web de l'application

    ::
    
        cd /var/www/
        sudo ln -s /home/synthese/dev/FF-synthese/web/ synthese

* Donner les droits nécessaires pour le bon fonctionnement de l'application (adapter les chemins à votre serveur)
    
    ::
        
        chmod -R 777 /home/synthese/dev/FF-synthese/log
        chmod -R 777 /home/synthese/dev/FF-synthese/cache
        chmod -R 775 /home/synthese/dev/FF-synthese/web/exportshape/
        chmod -R 775 /home/synthese/dev/FF-synthese/web/uploads/shapes
        
* Créer les fichiers de configurations
 
    ::
    
        cp /home/synthese/dev/FF-synthese/config/databases.yml.sample /home/synthese/dev/FF-synthese/config/databases.yml
        cp /home/synthese/dev/FF-synthese/web/js/config.js.sample /home/synthese/dev/FF-synthese/web/js/config.js
        cp /home/synthese/dev/FF-synthese/wms/wms.map.sample /home/synthese/dev/FF-synthese/wms/wms.map

        
* Adapter à vos paramètres de connexion aux bases de données. Normalement seul le paramètre password est à changer

 ** /home/synthese/dev/FF-synthese/config/databases.yml
    
    ::
    
        all:
          doctrine:
            class: sfDoctrineDatabase
            param:
              dsn: 'pgsql:host=databases;dbname=synthese'
              username: cartopnx
              password: monpassachanger
              
              
 ** /home/synthese/dev/FF-synthese/wms/wms.map
      
    ::
    
        host=databases dbname=synthesepn user=cartopnx password=monpassachanger
        
  adapter les paramètres de connexion à la base postgis partout ou se trouve cette chaine de caratères.
    

* Adapter le contenu du fichier /home/synthese/dev/FF-synthese/web/js/config.js
  ** Changer mon-domaine.fr par votre propre url (wms_uri, host_uri)
  ** Renseigner sa clé ign du géoportail ainsi que l'emprise spatiale de votre territoire

* Créer le dossier d'export shape

    ::
        
        mkdir /home/synthese/dev/FF-synthese/web/exportshape/
        chmod 775  exportshape/


* Vider le contenu du cache symfony : (attention aux chemins de votre serveur)
  
    ::
    
        cd /home/synthese/dev/FF-synthese/
        php symfony cc

* Pour tester, se connecter à l'application via http://mon-domaine.fr/synthese et les login et pass admin/admin

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


Une fois que votre commande est prète saisissez la valeur de la clé IGN reçut dans le fichier /home/synthese/dev/FF-synthese/web/js/config.js


