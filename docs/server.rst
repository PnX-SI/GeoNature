.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
=======
SERVEUR
=======

Les auteurs  :ref:`Auteurs <auteurs-section>`.


Prérequis
=========

* Ressources minimum serveur :

** 1 Go RAM
** 10 Go disk space

* disposer d'un utilisateur linux nommé 'synthese'. Le répertoire de cet utilisateur 'synthese' doit être dans /home/synthese

    :: 
    
        sudo adduser --home /home/synthese synthese


* récupérer le zip sur le github

    ::
    
        cd /tmp
        wget https://github.com/PnEcrins/FF-synthese/archive/vX.Y.Z.zip
        unzip vX.Y.Z.zip
        mkdir -p /home/synthese/dev/FF-synthese
        cp FF-synthese-X.Y.Z/* /home/synthese/dev/FF-synthese
        cd /home/synthese


Installation et configuration du serveur
========================================

installation pour debian 7.

  ::
  
    su - 
    apt-get install apache2 php5 libapache2-mod-php5 php5-gd libapache2-mod-wsgi php5-pgsql cgi-mapserver sudo gdal-bin
    usermod -g www-data synthese
    usermod -a -G root synthese
    adduser synthese sudo
    exit
    
    Fermer la console et la réouvrir pour que les modifications soient prises en compte
    
* Activer le mod_rewrite et les configurations requises pour symfony et redémarrer apache

  ::  
        
        sudo a2enmod rewrite
        sudo sh -c 'echo "Include /home/synthese/dev/FF-synthese/apache/*.conf" >> /etc/apache2/apache2.conf'
        sudo apache2ctl restart

* Ajouter un alias du serveur de base de données dans le fichier /etc/host

  ::  
        
        sudo sh -c 'echo "127.0.1.1       databases" >> /etc/hosts'
        sudo apache2ctl restart

* Vérifier que le répertoire /tmp existe et que l'utilisateur www-data y ait accès en lecture/écriture

mise en place de la base de données
===================================

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

Cet utilisateur sera le propriétaire de la base synthese et sera utilisé par l'application pour se connecté à la base.
l'application fonctionne avec le pass 'monpassachanger' mais il est conseillé de l'adapter !

    ::
    
        su postgres
        psql
        CREATE ROLE cartopnx WITH LOGIN PASSWORD 'monpassachanger';
        CREATE ROLE cartoadmin WITH SUPERUSER LOGIN PASSWORD 'monpassachanger';
        \q
        
Voir la partie database dans la doc
        
