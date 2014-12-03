.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
===============
BASE DE DONNEES
===============

Pré-requis
----------

* PostgreSQL 9.1, PostGIS 1.5, disposer d'une base ``template postgis``, ici nommée ``templategis``
* Installer PostgreSQL et PostGIS puis créer le template ``templategis``

  ::

    apt-get install postgresql-9.1 postgresql-9.1-postgis 
    sudo -u postgres createdb templategis
    sudo -u postgres createlang -d templategis plpgsql
    sudo -u postgres psql -d templategis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
    sudo -u postgres psql -d templategis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql

Création de l'utilisateur
-------------------------

* Créer un utilisateur de base de données PostgreSQL nommé ``cartopnx``

  Il sera le propriétaire de la base ``synthesepn`` et sera utilisé par l'application pour se connecter à la base. 
    
    L'application fonctionne avec le pass ``monpassachanger`` mais il est conseillé de l'adapter !
    
  ::

    su postgres
    psql
    CREATE ROLE cartopnx WITH LOGIN PASSWORD 'monpassachanger';
    CREATE ROLE cartoadmin WITH SUPERUSER LOGIN PASSWORD 'monpassachanger';
    \q
    exit

Création de la base de données
------------------------------

* Transférer les 2 fichiers SQL sur le serveur

    par exemple dans le répertoire /home/monuser/

* Créer une base postgis nommée synthesepn

    se loguer en ``root`` sur le serveur (pour Debian sinon utiliser sudo sur Ubuntu)

  ::

    su postgres
    createdb -O cartopnx -T templategis synthesepn
    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/monuser/grant.sql
    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/monuser/synthese_2154.sql
    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/monuser/data_synthese_2154.sql

* Si besoin l'exemple des données SIG du Parc national des Ecrins pour les tables du schéma ``layers``
  
  ::

    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/monuser/data_sig_pne_2154.sql 
    exit
    
* Pour PostGIS 2, il peut être nécessaire de passer le script ``legacy.sql`` sur la base
  
  ::

    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/monuser/legacy.sql
