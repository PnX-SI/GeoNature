.. image:: http://geonature.fr/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr
    
=======
SERVEUR
=======

Cette procédure décrit l'installation de l'application GeoNature seule. Il est aussi possible d'installer plus facilement GeoNature et tout son environnement (UsersHub, TaxHub et GeoNature-atlas) avec le script ``install_all`` (voir chapitre INSTALLATION GLOBALE).

Prérequis
=========

* Ressources minimum serveur :

Un serveur disposant d'au moins de 1 Go RAM et de 20-25 Go d'espace disque (une sauvegarde complète des bases et des données produites écrasée chaque jour).
Prévoir environ 100 Go pour stratégie de sauvegarde plus complète.


* Disposer d'un utilisateur linux nommé ``synthese`` (par exemple). Dans ce guide, le répertoire de cet utilisateur est dans ``/home/synthese``
 
  ::  
  
    sudo adduser --home /home/synthese synthese


Installation et configuration du serveur
========================================

Installation pour Debian 7.

:notes:

    Cette documentation concerne une installation sur Debian. Pour tout autre environemment les commandes sont à adapter.



:notes:

    Durant toute la procédure d'installation, travailler avec l'utilisateur ``synthese``. Ne changer d'utilisateur que lorsque la documentation le spécifie.



::

    su - 
    apt-get install apache2 php5 libapache2-mod-php5 php5-gd libapache2-mod-wsgi php5-pgsql cgi-mapserver sudo gdal-bin
    usermod -g www-data synthese
    usermod -a -G root synthese
    adduser synthese sudo
    exit
    
* Fermer la console et la réouvrir pour que les modifications soient prises en compte.
    
* Activer le ``mod_rewrite`` et redémarrer Apache

  ::  
        
        sudo a2enmod rewrite
        sudo apache2ctl restart

* Vérifier que le répertoire ``/tmp`` existe et que l'utilisateur ``www-data`` y ait accès en lecture/écriture.


Installation et configuration de PostgreSQL
===========================================

* Sur Debian 8, PostgreSQL est livré en version 9.4 et postGIS en 2.1, vous pouvez sauter l'étape suivante. Sur Debian 7, il faut revoir la configuration des dépots pour avoir une version compatible de PostgreSQL (9.3) et PostGIS (2.1). Voir http://foretribe.blogspot.fr/2013/12/the-posgresql-and-postgis-install-on.html.
 
  ::  
  
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" >> /etc/apt/sources.list'
        sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update
 
* Installation de PostreSQL/PostGIS pour Debian 8
 
  ::  
  
        sudo apt-get update
        sudo apt-get install postgresql postgresql-client
        sudo apt-get install postgresql-9.4-postgis-2.1
        sudo adduser postgres sudo

* Installation de PostreSQL/PostGIS pour Debian 7
 
  ::  
  
        sudo apt-get install postgresql-9.3 postgresql-client-9.3
        sudo apt-get install postgresql-9.3-postgis-2.1
        sudo adduser postgres sudo
        
* Configuration de PostgreSQL pour Debian 8 - permettre l'écoute de toutes les IP
 
  ::  
  
        sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" -i /etc/postgresql/9.4/main/postgresql.conf
        sudo sed -e "s/# IPv4 local connections:/# IPv4 local connections:\nhost\tall\tall\t0.0.0.0\/0\t md5/g" -i /etc/postgresql/9.4/main/pg_hba.conf
        /etc/init.d/postgresql restart
        
* Configuration de PostgreSQL pour Debian 7 - permettre l'écoute de toutes les IP
 
  ::  
  
        sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" -i /etc/postgresql/9.3/main/postgresql.conf
        sudo sed -e "s/# IPv4 local connections:/# IPv4 local connections:\nhost\tall\tall\t0.0.0.0\/0\t md5/g" -i /etc/postgresql/9.3/main/pg_hba.conf
        /etc/init.d/postgresql restart

* Création de l'utilisateur PostgreSQL
 
  ::  
  
        sudo su postgres
        psql
        CREATE ROLE geonatuser WITH LOGIN PASSWORD 'monpassachanger';
        \q
        
L'utilisateur ``geonatuser`` sera le propriétaire de la base de données ``geonaturedb`` et sera utilisé par l'application pour se connecter à celle-ci.

L'application fonctionne avec le mot de passe ``monpassachanger`` par defaut mais il est conseillé de le modifier !

Ce mot de passe, ainsi que l'utilisateur PostgreSQL créés ci-dessus (``geonatuser``) sont des valeurs par défaut utilisées à plusieurs reprises dans l'application. Ils peuvent cependant être changés. S'ils doivent être changés, ils doivent l'être dans plusieurs fichiers de l'application : 

- config/settings.ini
- config/databases.yml
- wms/wms.map
