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
Prévoir environ 100 Go pour une stratégie de sauvegarde plus complète.


* Disposer d'un utilisateur linux (nommé ``synthese`` par exemple). Dans ce guide, le répertoire de cet utilisateur est dans ``/home/synthese``
 
  ::  
  
    sudo adduser --home /home/synthese synthese


Installation et configuration du serveur
========================================

:notes:

    Cette documentation concerne une installation sur Debian. Pour tout autre environemment les commandes sont à adapter.



:notes:

    Durant toute la procédure d'installation, travailler avec l'utilisateur ``synthese``. Ne changer d'utilisateur que lorsque la documentation le spécifie.

Installation pour Debian 8.

::

    su - 
    apt-get install unzip sudo apache2 php5 libapache2-mod-php5 libapache2-mod-perl2 php5-gd php5-pgsql cgi-mapserver gdal-bin
    usermod -g www-data synthese
    usermod -a -G root synthese
    adduser synthese sudo
    exit

Installation pour Debian 9.

Debian 9 est livré avec php7 qui n'est pas compatible avec GeoNature1 (symfony 1.4). Il faut donc installer des paquets permettant un focntionnement avec php 5.6.

::

    sudo apt-get install -y sudo curl unzip apt-transport-https
    # installation des paquets de Ondrej pour php 5.6
    curl https://packages.sury.org/php/apt.gpg | sudo apt-key add -
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php5.list
    sudo apt-get update
    # installation de apache, php, mapserver, gdal, postgresql&postgis
    sudo apt-get install -y apache2 libapache2-mod-php5.6 libapache2-mod-perl2
    sudo apt-get install -y php5.6 php5.6-gd php5.6-pgsql
    sudo apt-get install -y cgi-mapserver gdal-bin
    sudo apt-get install -y postgresql postgis postgresql-server-dev-9.6
    
* Activer le ``mod_rewrite`` et redémarrer Apache

  ::  
        
        sudo a2enmod rewrite
        sudo apache2ctl restart

* Vérifier que le répertoire ``/tmp`` existe et que l'utilisateur ``www-data`` y ait accès en lecture/écriture.


Installation et configuration de PostgreSQL
===========================================

* Sur Debian 8, PostgreSQL est livré en version 9.4 et postGIS en 2.1, vous pouvez sauter l'étape suivante. 
        
* Configuration de PostgreSQL pour Debian 8 - permettre l'écoute de toutes les IP
 
  ::  
  
        sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" -i /etc/postgresql/9.4/main/postgresql.conf
        sudo sed -e "s/# IPv4 local connections:/# IPv4 local connections:\nhost\tall\tall\t0.0.0.0\/0\t md5/g" -i /etc/postgresql/9.4/main/pg_hba.conf
        /etc/init.d/postgresql restart
        
* Configuration de PostgreSQL pour Debian 9 - permettre l'écoute de toutes les IP
 
  ::  
  
        sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" -i /etc/postgresql/9.6/main/postgresql.conf
        sudo sed -e "s/# IPv4 local connections:/# IPv4 local connections:\nhost\tall\tall\t0.0.0.0\/0\t md5/g" -i /etc/postgresql/9.6/main/pg_hba.conf
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
