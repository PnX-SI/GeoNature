INSTALLATION GLOBALE
====================

Cette documentation permet une installation rapide et simplifiée de GeoNature et de ses applications liées : `UsersHub <https://github.com/PnEcrins/UsersHub>`_, `TaxHub <https://github.com/PnX-SI/TaxHub>`_ et `GeoNature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_. Pour plus d'informations, référez-vous aux documentations plus détaillées de chaque projet.

Les scripts proposés installent l'environnement logiciel du serveur, téléchargent les applications sur leur dépots github, les installent et les configurent par défaut.

Pré-requis
----------

- Un serveur Debian 8 (Ubuntu 16.04 LTS devrait fonctionner également - non testé)
- Une clé IGN pour l'API Geoportail valide pour le domaine sur lequel votre serveur répond
- Disposer d'un fichier ``/etc/apt/sources.list`` adapté. Voici un fichier exemple permettant un bon fonctionnement sur debian 8 :

::
    
    deb http://httpredir.debian.org/debian jessie main contrib non-free
    deb-src http://httpredir.debian.org/debian jessie main contrib non-free
    
    deb http://httpredir.debian.org/debian jessie-updates main contrib non-free
    deb-src http://httpredir.debian.org/debian jessie-updates main contrib non-free
    
    deb http://security.debian.org/ jessie/updates main contrib non-free
    deb-src http://security.debian.org/ jessie/updates main contrib non-free
    
    #Backports
    deb http://http.debian.net/debian wheezy-backports main
    

Installation
------------

:notes:

    Votre utilisateur linux doit disposer des droits administrateur avec sudo. Voir https://www.privateinternetaccess.com/forum/discussion/18063/debian-8-1-0-jessie-sudo-fix-not-installed-by-default


Après installation de l'OS avec OpenSSH server, placez vous dans le home de votre utilisateur et entrez les commandes suivantes :

::
    
    su
    apt-get update
    apt-get install -y sudo ca-certificates
    exit
    
Récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_) :

::  
    
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/X.Y.Z/docs/install_all/install_all.ini
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/X.Y.Z/docs/install_all/install_all.sh
	chmod +x install_all.sh

Mettez à jour le fichier ``install_all.ini`` avec vos informations. Attention, ne lancez pas les fichiers .sh tant que vous n'avez pas totalement complété ce fichier.

TODO : détailler la procédure pour l'atlas avec : 

* install avec données exemple 
* mettre à jour les shapes territoire 
* relancer le install.db de l'atlas.

Lancez ensuite l'installation des applications:
 
::  
  
	./install_all.sh

Le mot de passe sudo vous sera peut-être demandé une deuxième fois. 

Vous devez pouvoir vous connecter à vos applications avec les adresses (adaptez mondomaine.fr à votre nom de domaine ou avec votre adresse IP) :

- http://mondomaine.fr/usershub
- http://mondomaine.fr/geonature
- http://mondomaine.fr/taxhub
- http://mondomaine.fr/atlas

Les 3 premières applications demandent une authentification.

L'utilisateur ``admin`` avec le mot de passe ``admin`` est disponible par défaut avec des droits administrateur sur toutes les applications. 
Vous devez utiliser UsersHub pour gérer d'autres utilisateurs.

L'installation des bases de données est loguée dans le répertoire ``log`` des applications : ``log/install_db.log``.

:notes:

    L'application GeoNature-atlas est livrée avec des données exemples. Une fois l'installation de l'atlas terminée, vous devez l'adapter à votre territoire. 
    
    - Remplacez les shapes ``territoire.shp`` et ``communes.shp`` dans ``data/ref`` avec celles de votre territoire.
    - Relancer le sript ``install.db``.
