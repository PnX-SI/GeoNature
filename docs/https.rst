HTTPS
*****

La procédure décrit une méthode de certification HTTPS de votre domaine, grâce au service `Let's Encrypt <https://letsencrypt.org/>`_. Les manipulations ont été effectuées sur un serveur Debian 9 avec Apache2 installé, et un utilisateur bénéficiant des droits sudo.

Ressources : 

- https://www.memoinfo.fr/tutoriels-linux/configurer-lets-encrypt-apache/
- https://korben.info/securiser-facilement-gratuitement-site-https.html


Installer certbot
-----------------

::
 
    sudo apt-get install python3-certbot-apache


Lancer la commande cerbot
-------------------------

Lancer la commande suivant pour générer des certificats et des clés pour le nom de domaine que vous souhaitez mettre en HTTPS.

::
  
    sudo certbot certonly --webroot --webroot-path /var/www/html --domain mondomaine.fr --email monemail@mondomaine.fr
    

- ``certonly`` : demander la création du certificat uniquement.
- ``--webroot`` : utiliser le plugin webroot qui se contente d’ajouter des fichiers dans le dossier défini via ``--webroot-path``.
- ``--webroot-path`` : le chemin de votre « DocumentRoot » Apache. Certbot placera ses fichiers dans ``$DocumentRoot/.well-known/`` pour les tests et vérifications
- ``--domain`` : le nom de domaine à certifier. Mettre tous les sous-domaines à certifier
- ``--email`` : l’adresse qui recevra les notifications de Let’s Encrypt. Principalement pour rappeler de renouveler le certificat le moment venu.


Les certificats obtenus
-----------------------

Le certificat se trouve dans le répertoire ``/etc/letsencrypt/live/mondomaine.fr/``.

Il est constitué de 4 fichiers :

- ``privkey.pem`` : La clé privée de votre certificat. A garder confidentielle en toutes circonstances et à ne communiquer à personne quel que soit le prétexte. Vous êtes prévenus !
- ``cert.pem`` : Le certificat serveur est à préciser pour les versions d’Apache < 2.4.8. Ce qui est notre cas ici.
- ``chain.pem`` : Les autres certificats, SAUF le certificat serveur. Par exemple les certificats intermédiaires. Là encore pour les versions d’Apache < 2.4.8.
- ``fullchain.pem`` : Logiquement, l’ensemble des certificats. La concaténation du ``cert.pem`` et du ``chain.pem``. A utiliser cette fois-ci pour les versions d’Apache >= 2.4.8.


Automatiser le renouvellement du certificat
-------------------------------------------

Le certificat fourni par Let's Encrypt n’est valable que 3 mois. Il faut donc mettre en place un renouvellement automatique.
Ajouter une tache automatique (Cron) pour renouveler une fois par semaine le certificat :

::

    sudo crontab -e
    1 8 * * Sat certbot renew --renew-hook "service apache2 reload" >> /var/log/certbot.log



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
