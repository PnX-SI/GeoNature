.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
=======
SERVEUR
=======

Installation et configuration du serveur
========================================

installation pour debian 7.

  ::
  
    su -
    apt-get install apache2 php5 libapache2-mod-php5 php5-gd libapache2-mod-wsgi php5-pgsql cgi-mapserver sudo
    exit
    
* activer le mod_rewrite pour symfony et redémarrer apache

  ::  
        
        sudo a2enmod rewrite
        sudo apache2ctl restart

* Vérifier que le répertoire /tmp existe et que l'utilisateur www-data y ait accès en lecture/écriture


mise en place du serveur de bases de données
============================================

* Sur debian 7 configuration des dépots pour avoir les dernières versions de PostgreSQL (9.3) et Postgis (2.1)
(http://foretribe.blogspot.fr/2013/12/the-posgresql-and-postgis-install-on.html)

  ::  
  
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" >> /etc/apt/sources.list'
        sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update

* Installation de PostreSQL/PostGIS 

    ::
    
        sudo apt-get install postgresql-9.3 postgresql-client-9.3
        sudo apt-get install postgresql-9.3-postgis-2.1
        

* Création des utilisateurs postgres

Cet utilisateur sera le propriétaire de la base synthesepn et sera utilisé par l'application pour se connecté à la base.
l'application fonctionne avec le pass 'monpassachanger' mais il est conseillé de l'adapter !

    ::
    
        su postgres
        psql
        CREATE ROLE cartopnx WITH LOGIN PASSWORD 'monpassachanger';
        CREATE ROLE cartoadmin WITH SUPERUSER LOGIN PASSWORD 'monpassachanger';
        \q
        exit
    
        
