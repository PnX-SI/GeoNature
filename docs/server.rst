.. image:: http://geotrek.fr/images/logo-pne.png
    :target: http://www.ecrins-parcnational.fr
    
=======
SERVEUR
=======


Prérequis
=========

* Ressources minimum serveur :

Un serveur disposant d'au moins de 1 Go RAM et de 10 Go d'espace disque.


* Disposer d'un utilisateur linux nommé ``synthese`` (par exemple). Le répertoire de cet utilisateur ``synthese`` doit être dans ``/home/synthese``

    :: 
    
        sudo adduser --home /home/synthese synthese


* Récupérer le zip de l’application sur le Github du projet (`X.Y.Z à remplacer par le numéro de version souhaitée <https://github.com/PnEcrins/GeoNature/releases>`_), dézippez le dans le répertoire ``/tmp`` du serveur puis copiez le dans le répertoire de l’utilisateur linux :

    ::
    
        cd /tmp
        wget https://github.com/PnEcrins/GeoNature/archive/vX.Y.Z.zip
        unzip vX.Y.Z.zip
        mkdir -p /home/synthese/geonature
        cp GeoNature-X.Y.Z/* /home/synthese/geonature
        cd /home/synthese


Installation et configuration du serveur
========================================

Installation pour Debian 7.

:notes:

    Cette documentation concerne une installation sur Debian. Pour tout autre environemment les commandes sont à adapter.

.

:notes:

    Durant toute la procédure d'installation, travailler avec l'utilisateur ``synthese``. Ne changer d'utilisateur que lorsque la documentation le spécifie.

.

  ::
  
    su - 
    apt-get install apache2 php5 libapache2-mod-php5 php5-gd libapache2-mod-wsgi php5-pgsql cgi-mapserver sudo gdal-bin
    usermod -g www-data synthese
    usermod -a -G root synthese
    adduser synthese sudo
    exit
    
* Fermer la console et la réouvrir pour que les modifications soient prises en compte.
    
* Activer le ``mod_rewrite`` et les configurations requises pour Symfony et redémarrer Apache

  ::  
        
        sudo a2enmod rewrite
        sudo sh -c 'echo "Include /home/synthese/geonature/apache/*.conf" >> /etc/apache2/apache2.conf'
        sudo apache2ctl restart

* Ajouter un alias du serveur de base de données dans le fichier ``/etc/hosts``

  ::  
        
        sudo sh -c 'echo "127.0.1.1       geonatdbhost" >> /etc/hosts'
        sudo apache2ctl restart

:notes:

    Cet alias ``geonatdbhost`` permet d'identifier sur quel host l'application doit rechercher la base de données PostgreSQL
    
    Par défaut, PostgreSQL est en localhost (127.0.1.1)
    
    Si votre serveur PostgreSQL est sur un autre host (par exemple sur ``50.50.56.27``), vous devez modifier la chaine de caractères ci-dessus comme ceci ``50.50.56.27   geonatdbhost``

* Vérifier que le répertoire ``/tmp`` existe et que l'utilisateur ``www-data`` y ait accès en lecture/écriture

Installation et configuration de PosgreSQL
==========================================

* Sur Debian 7, configuration des dépots pour avoir les dernières versions de PostgreSQL (9.3) et PostGIS (2.1)
(http://foretribe.blogspot.fr/2013/12/the-posgresql-and-postgis-install-on.html)

  ::  
  
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" >> /etc/apt/sources.list'
        sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update

* Installation de PostreSQL/PostGIS 

    ::
    
        sudo apt-get install postgresql-9.3 postgresql-client-9.3
        sudo apt-get install postgresql-9.3-postgis-2.1
        sudo adduser postgres sudo
        
* Configuration de PostgreSQL - permettre l'écoute de toutes les IP

    ::
    
        sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" -i /etc/postgresql/9.3/main/postgresql.conf
        sudo sed -e "s/# IPv4 local connections:/# IPv4 local connections:\nhost\tall\tall\t0.0.0.0\/32\t md5/g" -i /etc/postgresql/9.3/main/pg_hba.conf
        /etc/init.d/postgresql restart

* Création de 2 utilisateurs PostgreSQL

    ::
    
        sudo su postgres
        psql
        CREATE ROLE geonatuser WITH LOGIN PASSWORD 'monpassachanger';
        CREATE ROLE geonatadmin WITH SUPERUSER LOGIN PASSWORD 'monpassachanger';
        \q
        
L'utilisateur ``geonatuser`` sera le propriétaire de la base de données ``geonaturedb`` et sera utilisé par l'application pour se connecter à celle-ci.

L'utilisateur ``geonatadmin`` est super utilisateur de PostgreSQL.

L'application fonctionne avec le mot de passe ``monpassachanger`` par defaut mais il est conseillé de le modifier !

Ce mot de passe, ainsi que les utilisateurs PostgreSQL créés ci-dessus (``geonatuser`` et ``geonatadmin``) sont des valeurs par défaut utilisées à plusieurs reprises dans l'application. Ils peuvent cependant être changés. S'ils doivent être changés, ils doivent l'être dans plusieurs fichiers de l'application : 

    config/settings.ini
    
    config/databases.yml
    
    wms/wms.map
    
