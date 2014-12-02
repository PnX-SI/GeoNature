.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
===============
BASE DE DONNEES
===============

Pré-requis
----------

* postgres 9.1, postgis 1.5, disposer d'une base template postgis ici nommée 'templategis'
* installer postgres et postgis puis la créer le template 'templategis'

  ::

    apt-get install postgresql-9.1 postgresql-9.1-postgis 
    sudo -u postgres createdb templategis
    sudo -u postgres createlang -d templategis plpgsql
    sudo -u postgres psql -d templategis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
    sudo -u postgres psql -d templategis -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql

Création de l'utilisateur
-------------------------

* créer un utilisateur postgres nommé 'cartopnx'. 
Il sera le propriétaire de la base synthesepn et sera utilisé par l'application pour se connecté à la base.
l'application fonctionne avec le pass 'monpassachanger' mais il est conseillé de l'adapter !
  ::

    su postgres
    psql
    CREATE ROLE cartopnx WITH LOGIN PASSWORD 'monpassachanger';
    CREATE ROLE cartoadmin WITH SUPERUSER LOGIN PASSWORD 'monpassachanger';
    \q
    exit

Création de la base de données
------------------------------

* transférer les 2 fichiers sql sur le serveur 
    par exemple dans le répertoire /home/monuser/

* créer une base postgis nommée synthesepn
    se loguer en root sur le serveur (pour debian sinon utiliser sudo sur ubuntu)
  ::

    su postgres
    createdb -O cartopnx -T templategis synthesepn
    export PGPASSWORD=monpassachanger;psql -h localhost -U cartoadmin -d synthesepn -f /home/cartodev/grant.sql
    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/cartodev/synthese_2154.sql
    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/cartodev/data_synthese_2154.sql

* si besoin l'exemple des données sig du PN Ecrins pour les tables du schéma layers
  ::

    export PGPASSWORD=monpassachanger;psql -h localhost -U cartopnx -d synthesepn -f /home/cartodev/data_sig_pne_2154.sql 
    exit
