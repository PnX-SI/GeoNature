.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
===============
BASE DE DONNEES
===============


* Création de la base de données et chargement des données initiales

    ::
    
        cd /home/synthese/dev/FF-synthese/data/inpn
        tar -xzvf data_inpn_v7.tar.gz 
        
        su postgres
        cd /home/synthese/dev/FF-synthese/data
        createdb -O cartopnx synthese
        psql -d synthese -c "CREATE EXTENSION postgis;"
        psql -d synthese -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';"
        export PGPASSWORD=monpassachanger;psql -h localhost -U cartoadmin -d synthese -f grant.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthese -f 2154/synthese_2154.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthese -f inpn/data_inpn_v7_synthese.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthese -f 2154/data_synthese_2154.sql
        export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthese -f 2154/data_set_synthese_2154.sql
        exit
        
        rm taxref*

* Si besoin l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``
  
  ::

    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthese -f pne/data_sig_pne_2154.sql 
