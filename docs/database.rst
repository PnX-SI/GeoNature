.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
===============
BASE DE DONNEES
===============


* Création de la base de données et chargement des données initiales

    ::
    
        createdb -O cartopnx synthese
        psql -d synthese -c "CREATE EXTENSION postgis;"

* Si besoin l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``
  
  ::

    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/monuser/data_sig_pne_2154.sql 
    exit
    
* Pour PostGIS 2, il peut être nécessaire de passer le script ``legacy.sql`` sur la base
  
  ::

    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/monuser/legacy.sql
