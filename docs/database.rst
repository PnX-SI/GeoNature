.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
===============
BASE DE DONNEES
===============


* Création de la base de données et chargement des données initiales

    ::
    
        cd /home/synthese/geonature/data/inpn
        tar -xzvf data_inpn_v7.tar.gz 
        
        su postgres
        cd /home/synthese/geonature/data
        createdb -O geonatuser geonaturedb
        psql -d geonaturedb -c "CREATE EXTENSION postgis;"
        psql -d geonaturedb -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';"
        export PGPASSWORD=monpassachanger;psql -h localhost -U geonatadmin -d geonaturedb -f grant.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U geonatuser -d geonaturedb -f 2154/synthese_2154.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U geonatuser -d geonaturedb -f inpn/data_inpn_v7_synthese.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U geonatuser -d geonaturedb -f 2154/data_synthese_2154.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U geonatuser -d geonaturedb -f 2154/data_set_synthese_2154.sql
        exit
        
        rm taxref*

* Si besoin l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``
  
  ::

    export PGPASSWORD=monpassachanger;psql -h localhost -U geonatuser -d geonaturedb -f pne/data_sig_pne_2154.sql 
<<<<<<< HEAD
=======
>>>>>>> master
