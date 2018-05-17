INSTALLATION GLOBALE
====================

Cette documentation permet une installation rapide et simplifiée de GeoNature et de ses applications liées : `UsersHub <https://github.com/PnEcrins/UsersHub>`_, `TaxHub <https://github.com/PnX-SI/TaxHub>`_ et `GeoNature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_. Pour plus d'informations, référez-vous aux documentations plus détaillées de chaque projet.

Les scripts proposés installent l'environnement logiciel du serveur, téléchargent les applications sur leur dépots github, les installent et les configurent par défaut.

Pré-requis
----------

- Un serveur Debian 9 (Ubuntu 16.04 LTS devrait fonctionner également mais le script ``install_all.sh`` est à adapter pour cet OS)
- Le scripts Debian 8 et sa doc restent disponibles mais ne sont plus testés (docs/install_all/README_debian8.rst)
- Une clé IGN pour l'API Geoportail valide pour le domaine sur lequel votre serveur répond

Installation
------------

:notes:

    Votre utilisateur linux doit disposer des droits administrateur avec sudo. Voir https://www.privateinternetaccess.com/forum/discussion/18063/debian-8-1-0-jessie-sudo-fix-not-installed-by-default

Après installation de l'OS avec OpenSSH server, créer un utilisateur linux (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler avec le super-utilisateur ``root``. Donnez-lui des droits sudo pour qu'il puisse faire les taches d'administration :

::
    
    adduser geonatureadmin sudo

L’ajouter aussi au groupe ``www-data``

::
    
    usermod -g www-data geonatureadmin

Reconnectez-vous au serveur en SSH avec votre utilisateur (``geonatureadmin`` dans notre cas) pour ne pas travailler avec le super-utilisateur ``root``. 

Adapter votre fichier de sources de paquets ``/etc/apt/sources.list``.

Pour cela, modifier le fichier

::
    
    sudo nano /etc/apt/sources.list
    
Il doit contenir à minima les 3 lignes suivantes :

::
    
    deb http://security.debian.org/debian-security stretch/updates main contrib non-free
    deb http://deb.debian.org/debian/ stretch-updates main contrib non-free
    deb http://deb.debian.org/debian stretch main contrib non-free
    
Enregistrer et fermer le fichier puis mettez à jour apt.

::
    
    sudo apt-get update


Placez vous dans le répertoire ``home`` de votre utilisateur

::
    
    cd
    
Récupérer les scripts d'installation (``X.Y.Z`` à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_) :

::  
    
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/X.Y.Z/docs/install_all/install_all.ini
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/X.Y.Z/docs/install_all/install_all.sh
	chmod +x install_all.sh

Mettez à jour le fichier ``install_all.ini`` avec vos informations. Attention, ne lancez pas le fichier ``install_all.sh`` tant que vous n'avez pas totalement complété ce fichier.

Lancez ensuite l'installation des applications :
 
::  
  
	./install_all.sh

Le mot de passe sudo vous sera demandé (il peut être demandé à plusieurs reprises selon la durée de l'installation).

Vous devriez alors pouvoir vous connecter à vos applications avec les adresses (adaptez mondomaine.fr à votre nom de domaine ou avec votre adresse IP) :

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
    - Relancer le script ``install.db`` dans le répertoire de l'atlas.
    
Voir la documentation de GeoNature-atlas pour plus d'informations sur le sujet : https://github.com/PnEcrins/GeoNature-atlas/tree/master/docs.

Le script install_all déploie toutes les applications de manière automatisée et globale. Mais il est important de consulter ensuite les présentations et documentations des différents outils pour comprendre leur fonctionnement et leurs interactions : 

- `UsersHub <https://github.com/PnEcrins/UsersHub>`_
- `TaxHub <https://github.com/PnX-SI/TaxHub>`_ 
- `GeoNature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_

Lisez aussi l'exemple suivant de déploiement global qui apporte de nombreuses informations complémentaires. 
