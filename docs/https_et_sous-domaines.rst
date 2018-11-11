HTTPS & Configuration de sous-domaines
======================================

La présente documentation décrit la procédure de certification HTTPS et la configuration apache des différentes applications, dans le cas où chaque application possède son propre sous-domaine. Les sous-domaines doivent préalablement être déclarés et pointer sur le serveur.


**Mise en place du  HTTPS**

La procédure décrit la certification HTTPS des sous-domaines de chacune des applications de l'install_all, grâce au service `Let's Encrypt <https://letsencrypt.org/>`_. Les manipulations ont été effectuées sur un serveur Debian 9 avec Apache2 installé, et un utilisateur bénéficiant des droits sudo.

Ressources : 

- https://www.memoinfo.fr/tutoriels-linux/configurer-lets-encrypt-apache/
- https://korben.info/securiser-facilement-gratuitement-site-https.html


Installer certbot
-----------------

::
 
    sudo apt-get install python-certbot-apache


Lancer la commande cerbot
-------------------------

Lancer la commande suivant pour générer des certificats et des clés pour l’ensemble des noms de domaines que vous souhaitez mettre en HTTPS.

::
  
    sudo certbot certonly --webroot --webroot-path /var/www/html --domain geonature.mondomaine.fr --email monemail@domaine.fr
	sudo certbot certonly --webroot --webroot-path /var/www/html --domain taxhub.mondomaine.fr --email monemail@domaine.fr
	sudo certbot certonly --webroot --webroot-path /var/www/html --domain usershub.mondomaine.fr --email monemail@domaine.fr


- ``certonly`` : demander la création du certificat uniquement.
- ``--webroot`` : utiliser le plugin webroot qui se contente d’ajouter des fichiers dans le dossier défini via ``--webroot-path``.
- ``--webroot-path`` : le chemin de votre « DocumentRoot » Apache. Certbot placera ses fichiers dans ``$DocumentRoot/.well-known/`` pour les tests et vérifications
- ``--domain`` : le nom de domaine à certifier. Mettre tous les sous-domaines à certifier
- ``--email`` : l’adresse qui recevra les notifications de Let’s Encrypt. Principalement pour rappeler de renouveler le certificat le moment venu.


Les certificats obtenus
-----------------------

Les certificats se trouvent dans les dossiers ``/etc/letsencrypt/live/geonature.mondomaine.fr/``, ``/etc/letsencrypt/live/taxhub.mondomaine.fr/`` et ``/etc/letsencrypt/live/usershub.mondomaine.fr/``.

Pour chaque certificat, 4 fichiers sont générés :

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


**Mise à jour des configuration apache et configuration de l'application GeoNature**

Les fichiers de configuration Apache des différentes applications ainsi que la configuration de GeoNature doivent être mis à jour en conséquence. Dans chaque configuration, le premier VirtualHost (*:80) sert à faire la redirection du http vers le https. Le second (*:443) est la configuration du https. Pensez à remplacer "mondomaine" et les chemins des fichiers de certification de cerbot.  


Configuration apache de GeoNature
---------------------------------

Modifier le fichier de configuration de GeoNature : ``/etc/apache2/sites-available/geonature.conf``

:: 

	# Configuration originale de GeoNature
	#Alias /geonature /home/geonatureadmin/geonature/frontend/dist

	#<Directory /home/geonatureadmin/geonature/frontend/dist>
	#Require all granted
	#</Directory>
	#<Location /geonature/api>
	#ProxyPass http://127.0.0.1:8000
	#ProxyPassReverse  http://127.0.0.1:8000
	#</Location>

	# Configuration de GeoNature avec sous-domaine et https
	<VirtualHost *:80>
	  ServerName geonature.mondomaine.fr

	  RewriteEngine on
	  RewriteCond %{HTTPS} !on
	  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
	</VirtualHost>

	<VirtualHost *:443>
	        ServerName geonature.mondomaine.fr

	        ServerAdmin webmaster@localhost
	        DocumentRoot /home/geonatureadmin/geonature/frontend/dist/

	        <Directory /home/geonatureadmin/geonature/frontend/dist/ >
	                AllowOverride All
	                Options -Indexes
	                Require all granted
	        </Directory>
		<Location /api>
			ProxyPass http://127.0.0.1:8000
			ProxyPassReverse  http://127.0.0.1:8000
		</Location>

	    SSLEngine on
	    SSLCertificateFile /etc/letsencrypt/live/geonature.mondomaine.fr/cert.pem
	    SSLCertificateKeyFile /etc/letsencrypt/live/geonature.mondomaine.fr/privkey.pem
	    SSLCertificateChainFile /etc/letsencrypt/live/geonature.mondomaine.fr/chain.pem
	    SSLProtocol all -SSLv2 -SSLv3
	    SSLHonorCipherOrder on
	    SSLCompression off
	    SSLOptions +StrictRequire
	    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
	    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
	</VirtualHost>

# FIN Configuration GeoNature


Configuration apache de Taxhub
------------------------------

Modifier le fichier de configuration de taxhub : ``/etc/apache2/sites-available/taxhub.conf``

:: 

	# Configuration originale de TaxHub
	#<Location /taxhub>
	#ProxyPass  http://127.0.0.1:5000 retry=0
	#ProxyPassReverse  http://127.0.0.1:5000
	#</Location>
	#FIN Configuration TaxHub


	# Configuration de TaxHub avec sous-domaine et https
	<VirtualHost *:80>
	  ServerName taxhub.mondomaine.fr

	  RewriteEngine on
	  RewriteCond %{HTTPS} !on
	  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
	</VirtualHost>

	<VirtualHost *:443>
	        ServerName taxhub.mondomaine.fr

		<Location />
			ProxyPass http://127.0.0.1:5000/
			ProxyPassReverse http://127.0.0.1:5000/
		</Location>

	    SSLEngine on
	    SSLCertificateFile /etc/letsencrypt/live/taxhub.mondomaine.fr/cert.pem
	    SSLCertificateKeyFile /etc/letsencrypt/live/taxhub.mondomaine.fr/privkey.pem
	    SSLCertificateChainFile /etc/letsencrypt/live/taxhub.mondomaine.fr/chain.pem
	    SSLProtocol all -SSLv2 -SSLv3
	    SSLHonorCipherOrder on
	    SSLCompression off
	    SSLOptions +StrictRequire
	    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM$
	    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
	</VirtualHost>

	#FIN Configuration TaxHub


Configuration apache de Usershub
--------------------------------

Modifier le fichier de configuration de usershub : ``/etc/apache2/sites-available/usershub.conf``

::
	#Configuration originale de usershub
	#Alias /usershub /home/geonatureadmin/usershub/web
	#<Directory /home/geonatureadmin/usershub/web>
	#Require all granted
	#</Directory>

	# Configuration UsersHub avec sous-domaine et https

	<VirtualHost *:80>
	  ServerName usershub.mondomaine.fr

	  RewriteEngine on
	  RewriteCond %{HTTPS} !on
	  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}
	</VirtualHost>

	<VirtualHost *:443>
	        ServerName usershub.mondomaine.fr

	        DocumentRoot /home/geonatureadmin/usershub/web/

	        <Directory /home/geonatureadmin/usershub/web/ >
	                AllowOverride All
	                Options -Indexes
					Require all granted
	        </Directory>

	    SSLEngine on
	    SSLCertificateFile /etc/letsencrypt/live/usershub.mondomaine.fr/cert.pem
	    SSLCertificateKeyFile /etc/letsencrypt/live/usershub.mondomaine.fr/privkey.pem
	    SSLCertificateChainFile /etc/letsencrypt/live/usershub.mondomaine.fr/chain.pem
	    SSLProtocol all -SSLv2 -SSLv3
	    SSLHonorCipherOrder on
	    SSLCompression off
	    SSLOptions +StrictRequire
	    SSLCipherSuite ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
	    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

	</VirtualHost>
	#FIN configuration usershub


Prise en compte des nouvelles configurations apache
---------------------------------------------------

Activer les modules ``ssl``, ``headers`` et ``rewrite`` puis redémarrer Apache :

::

    sudo a2enmod ssl
    sudo a2enmod rewrite
    sudo a2enmod headers
    sudo apachectl restart

Les fichiers de configuration des sites TaxHub et UsersHub ne sont pas à modifier, ils seront automatiquement associés à la configuration HTTPS. En revanche, la configuration de geonature doit être mise à jour.


Configuration de l'application GeoNature
----------------------------------------

Il est nécessaire de mettre à jour le fichier de configuration geonature_config.toml situé dans le répertoire ``geonature/config`` :

:: 
	cd geonature/config
	nano geonature_config.toml


Modifier les éléments suivants : 

:: 
	URL_APPLICATION = 'https://geonature.mondomaine.fr'
	API_ENDPOINT = 'https://geonature.mondomaine.fr/api'
	API_TAXHUB = 'https://taxhub.mondomaine.fr/api'


Pour que ces modifications soient prises en compte, lancer les commandes suivantes dans le répertoire ``geonature/backend`` :

::
	cd geonature/backend
	source venv/bin/activate
	geonature update_configuration
	deactivate

Les applications sont désormais accessibles sur leurs sous-domaines respectifs, tous certifiés https. 


Configuration des sous-domaines sans https 
------------------------------------------

Pour disposer de sous-domaines sans certification https, , la procédure est la même mais il faut supprimer la réécriture du virtualhost 80, et supprimer la configuration du *:443. 
La configuration des applications doit, dans ce cas, être directement faite sur le virtualhost *:80. La configuration de GeoNature doit être remise à jour comme expliqué ci-dessus.

Pour taxhub : 

:: 
	# Configuration TaxHub sur sous-domaine
	<VirtualHost *:80>
		ServerName taxhub.mondomaine.fr

		<Location />
			ProxyPass http://127.0.0.1:5000/
			ProxyPassReverse http://127.0.0.1:5000/
		</Location>
	</VirtualHost>


Pour Userhsub : 

::
	# Configuration Usershub sur sous-domaine
	<VirtualHost *:80>
		ServerName usershub.mondomaine.fr
		DocumentRoot /home/geonatureadmin/usershub/web

		<Directory /home/geonatureadmin/usershub/web>
			AllowOverride All
			Require all granted
		</Directory>
	</VirtualHost>


Pour GeoNature (apache): 

::
	#Configuration GeoNature sur sous-domaine
	<VirtualHost *:80>
		ServerName geonature.mondomaine.fr
		DocumentRoot /home/geonatureadmin/geonature/frontend/dist

		<Directory /home/geonatureadmin/geonature/frontend/dist>
			Require all granted
		</Directory>
	
		<Location /api>
			ProxyPass http://127.0.0.1:8000
			ProxyPassReverse  http://127.0.0.1:8000
		</Location>
	</VirtualHost>


Pour geonature (configuration de l'application) :

:: 
	URL_APPLICATION = 'http://geonature.mondomaine.fr'
	API_ENDPOINT = 'http://geonature.mondomaine.fr/api'
	API_TAXHUB = 'http://taxhub.mondomaine.fr/api'
