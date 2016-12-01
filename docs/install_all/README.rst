INSTALLATION RAPIDE ET COMPLETE
===============================

Cette documentation permet une installation rapide et simplifiée de GeoNature et de ses applications liées : UsersHub, TaxHub et GeoNature-atlas.
Les scripts proposés installent l'environnement logiciel du serveur, téléchargent les applications sur leur dépots github, les installent et les configurent par défaut.

Pré-requis
----------

- Un serveur Debian 8 (Ubuntu 16.04 LTS devrait fonctionner également - non testé)
- Une clé IGN pour l'API Geoportail valide pour le domaine sur lequel votre serveur répond
- TODO : proposer un sources.list valide et la procédure pour le mettre à jour

Installation
------------

Après installation de l'OS avec OpenSSH server, placez vous dans le home de votre utilisateur et entrez les commandes suivantes :

  ::
    
    su
    apt-get update
    apt-get install -y sudo ca-certificates
    exit
    
Récupérer les scripts d'installation

  ::  
    
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/install_all/install_all.ini
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/install_all/install_all.sh
	chmod +x install_all.sh

Mettez à jour le fichier ``install_all.ini`` avec vos informations. Attention, ne lancez pas les fichiers .sh tant que vous n'avez pas totalement complété ce fichier.
TODO : détailler la procédure pour l'atlas avec : 
    * install avec données exemple 
    * mettre à jour les shapes territoire 
    * relancer le install.db de l'atlas.


:notes:

    Votre utilisateur linux doit disposer des droits administrateur avec sudo. Voir https://www.privateinternetaccess.com/forum/discussion/18063/debian-8-1-0-jessie-sudo-fix-not-installed-by-default


Lancez ensuite l'installation des applications:
 
  ::  
  
	./install_all.sh

Le mot de passe sudo vous sera demandé 2 fois. 
Lors de l'exécution du script, 2 questions seront posée. Répondre ``9`` puis ``3``

Vous devez pouvoir vous connecter à vos applications avec les adresses (adaptez mondomaine.fr à votre nom de domaine ou avec votre adresse IP)
	http://mondomaine.fr/usershub
	http://mondomaine.fr/geonature
	http://mondomaine.fr/taxhub
	http://mondomaine.fr/atlas


Les 3 premières applications demandent une authentification.

L'utilisateur ``admin`` avec le mot de passe ``admin`` est disponible par défaut avec des droits administrateur sur toutes les applications. 
Vous devez utiliser UsersHub pour gérer d'autres utilisateurs.

L'installation des bases de données est loguée dans le répertoire ``log`` des applications : ``log/install_db.log``.

:notes:

    L'application GeoNature-atlas est livrée avec des données exemples. Une fois l'installation de l'atlas terminée, vous devez l'adapter à votre territoire. 
    * remplacez les shapes ``territoire.shp`` et ``communes.shp`` dans ``data/ref`` avec celles de votre territoire.
    * relancer le sript ``install.db``.