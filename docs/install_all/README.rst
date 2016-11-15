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
    
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/install_all/init_user.sh
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/install_all/install_all.ini
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/install_all/install_all.sh
	chmod +x init_user.sh
	chmod +x install_all.sh

Mettez à jour le fichier ``install_all.ini`` avec vos informations. Attention, ne lancez pas les fichiers .sh tant que vous n'avez pas totalement complété ce fichier.

Lancez la configuration de l'utilisateur linux (le mot de passe de votre utilisateur vous sera demandé par sudo):
  
  ::  
  
	sudo ./init_user.sh

Lancez ensuite l'installation des applications:
 
  ::  
  
	./install_all.sh

Le mot de passe sudo vous sera demandé. 
Lors de l'exécution du script, une question sera posée. 
Unable to find a suitable version for webcomponentsjs, please choose one by typing one of the numbers below:
    1) webcomponentsjs#~0.5.4 which resolved to 0.5.5 and is required by App States#0.6.9
    2) webcomponentsjs#* which resolved to 0.5.5 and is required by core-component-page#0.5.6
    3) webcomponentsjs#^0.6.0 which resolved to 0.6.3 and is required by polymer#0.5.6
Répondre ``3``

Vous devez pouvoir vous connecter à vos applications avec les adresses (adaptez mondomaine.fr à votre nom de domaine ou avec votre adresse IP)
	http://mondomaine.fr/usershub
	http://mondomaine.fr/geonature
	http://mondomaine.fr/taxhub
	http://mondomaine.fr/atlas


Les 3 premières applications demandent une authentification.

L'utilisateur ``admin`` avec le mot de passe ``admin`` est disponible par défaut avec des droits administrateur sur toutes les applications. 
Vous devez utiliser UsersHub pour gérer d'autres utilisateurs.

L'installation des bases de données est loguée dans le répertoire ``log`` des applications : ``log/install_db.log``.