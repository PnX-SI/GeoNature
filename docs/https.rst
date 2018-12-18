HTTPS
=====

La présente documentation décrit la procédure de certification HTTPS et l'adaptation de la configuration Apache par défaut du serveur, sans utilisation de sous-domaine. Pour la mise en place de sous-domaines, voir la documentation "Configuration Apache".


**Mise en place du  HTTPS**

La procédure décrit la certification HTTPS de votre domaine pour l'ensemble des applications de l'install_all, grâce au service `Let's Encrypt <https://letsencrypt.org/>`_. Les manipulations ont été effectuées sur un serveur Debian 9 avec Apache2 installé, et un utilisateur bénéficiant des droits sudo.

Ressources : 

- https://www.memoinfo.fr/tutoriels-linux/configurer-lets-encrypt-apache/
- https://korben.info/securiser-facilement-gratuitement-site-https.html


Installer certbot
-----------------

::
 
    sudo apt-get install python-certbot-apache


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


**Mise à jour de la configuration apache du serveur**

Afin que Apache prenne en compte la certification (redirection de http vers https), il faut modifier la configuration Apache par défaut du serveur : ``/etc/apache2/sites-available/000-default.conf``


:: 

	# Redirection de http vers https
	<VirtualHost *:80>
	  ServerName mondomaine.fr

	  RewriteEngine on
	  RewriteCond %{HTTPS} !on
	  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}

	</VirtualHost>

	# Configuration par défaut du serveur sur le port 443 (https)
	<VirtualHost *:443>
	        ServerName mondomaine.fr

	        ServerAdmin webmaster@localhost
	        DocumentRoot /var/www/html/

	         ErrorLog ${APACHE_LOG_DIR}/error.log
      		 CustomLog ${APACHE_LOG_DIR}/access.log combined

	    SSLEngine on
	    SSLCertificateFile /etc/letsencrypt/live/mondomaine.fr/cert.pem
	    SSLCertificateKeyFile /etc/letsencrypt/live/mondomaine.fr/privkey.pem
	    SSLCertificateChainFile /etc/letsencrypt/live/mondomaine.fr/chain.pem
	    SSLProtocol all -SSLv2 -SSLv3
	    SSLHonorCipherOrder on
	    SSLCompression off
	    SSLOptions +StrictRequire
	    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
	    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
	</VirtualHost>


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


Pour que ces modifications soient prises en compte, lancer les commandes suivantes depuis le répertoire ``geonature/backend`` :

::
	
  cd geonature/backend
  source venv/bin/activate
  geonature update_configuration
  deactivate

Les applications sont désormais accessibles sur votre domaine sécurisé en HTTPS !
