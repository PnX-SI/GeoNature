INSTALLATION RAPIDE
===================

Cette documentation permet une installation rapide et simplifiée de GeoNature et de son environnement : UsersHub, TaxHub et GeoNature-atlas.
Les scripts proposés installent l'environnement logiciel du serveur, téléchargent les applications sur leur dépots github, les installent et les configurent.

Pré-requis
----------

- Un serveur debian 8 (ubuntu 16.04 LTS devrait fonctionner également - non testé) 
- Une clé IGN pour l'api geoportail valide pour le domaine sur lequel votre serveur répond.
- TODO : proposer un sources.list valide et la procédure pour le mettre à jour.

Installation
------------

Après installation de l'OS avec OpenSSH server, placez vous dans le home de votre utilisateur et entrez les commandes suivantes :
 
  ::  
  
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/init_user.sh
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/install_all.ini
	wget https://raw.githubusercontent.com/PnEcrins/GeoNature/develop/docs/install_all.sh
    chmod +x init_user.sh
    chmod +x install_all.sh

    
lancez ensuite l'installation (le mot de passe de votre utilisateur vous sera demandé par sudo):
 
  ::  
  
	./install_all.sh