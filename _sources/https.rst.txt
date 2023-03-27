HTTPS
*****

La procédure décrit une méthode de certification HTTPS de votre domaine, grâce au service `Let's Encrypt <https://letsencrypt.org/>`_. Les manipulations ont été effectuées sur un serveur Debian 9 avec Apache2 installé, et un utilisateur bénéficiant des droits sudo.

Cette documentation est indicative, car elle ne concerne pas GeoNature, mais la mise en place d'un certificat SSL pour une application web servie par Apache.

Ressources : 

- https://www.memoinfo.fr/tutoriels-linux/configurer-lets-encrypt-apache/
- https://korben.info/securiser-facilement-gratuitement-site-https.html


Installer certbot
-----------------

::
 
    sudo apt-get install python3-certbot-apache


Lancer la commande cerbot
-------------------------

Lancer la commande suivante pour générer des certificats et des clés pour le nom de domaine que vous souhaitez mettre en HTTPS.

::
  
    sudo certbot --apache --email monemail@mondomaine.fr
    
Prise en compte des nouvelles configurations Apache
---------------------------------------------------

Activer les modules ``ssl``, ``headers`` et ``rewrite`` puis redémarrer Apache :

::

    sudo a2enmod ssl
    sudo a2enmod rewrite
    sudo a2enmod headers
    sudo apachectl restart

Les fichiers de configuration des sites TaxHub et UsersHub ne sont pas à modifier, ils seront automatiquement associés à la configuration HTTPS. En revanche, la configuration de GeoNature doit être mise à jour.


Configuration de l'application GeoNature
----------------------------------------

Il est nécessaire de mettre à jour le fichier de configuration ``geonature_config.toml`` situé dans le répertoire ``geonature/config`` :

:: 
	
  cd geonature/config
  nano geonature_config.toml


Modifier les éléments suivants : 

:: 
	
  URL_APPLICATION = 'https://mondomaine.fr/geonature'
  API_ENDPOINT = 'https://mondomaine.fr/geonature/api'
  API_TAXHUB = 'https://mondomaine.fr/taxhub/api'

Pour que ces modifications soient prises en compte, exécuter les :ref:`actions à effecture après modification de la configuration <post_config_change>`.

Les applications sont désormais accessibles sur votre domaine sécurisé en HTTPS !
