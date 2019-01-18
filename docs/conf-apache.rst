CONFIGURATION APACHE
====================

La présente documentation décrit les configurations Apache des différentes applications, dans le cas où chaque application possède son propre sous-domaine, avec ou sans utilisation de la certification HTTPS. 

Les sous-domaines doivent préalablement être déclarés dans la zone DNS du serveur.


**Configuration de sous-domaines sans https**

Mise à jour des configurations Apache
-------------------------------------

Afin de rendre chaque application disponible sur un sous-domaine qui lui est propre, adapter la configuration Apache des différentes applications comme suit :

Pour TaxHub, modifier le fichier de configuration Apache ``/etc/apache2/sites-available/taxhub.conf`` et remplacer son contenu par :

:: 
	
    # Configuration TaxHub sur sous-domaine
	<VirtualHost *:80>
		ServerName taxhub.mondomaine.fr

		<Location />
			ProxyPass http://127.0.0.1:5000/
			ProxyPassReverse http://127.0.0.1:5000/
		</Location>
	</VirtualHost>
    # Fin de configuration de TaxHub


Pour UsersHub, modifier le fichier de configuration Apache ``/etc/apache2/sites-available/usershub.conf`` et remplacer son contenu par :

::
	
    # Configuration UsersHub sur sous-domaine
	<VirtualHost *:80>
		ServerName usershub.mondomaine.fr
		DocumentRoot /home/geonatureadmin/usershub/web

		<Directory /home/geonatureadmin/usershub/web>
			AllowOverride All
			Require all granted
		</Directory>
	</VirtualHost>
    # Fin de configuration de UsersHub


Pour GeoNature, modifier le fichier de configuration apache ``/etc/apache2/sites-available/geonature.conf`` et remplacer son contenu par : 

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
    # Fin de configuration de GeoNature


Pensez à modifier également ``/etc/apache2/sites-available/geonature_maintenance.conf`` pour le mode maintenance.


Application des nouvelles configurations Apache
-----------------------------------------------

Activer les modules ``ssl``, ``headers`` et ``rewrite`` puis redémarrer Apache :

::

    sudo a2enmod ssl
    sudo a2enmod rewrite
    sudo a2enmod headers
    sudo apachectl restart


Mise à jour de l'application GeoNature
--------------------------------------

Il est également nécessaire de mettre à jour le fichier de configuration ``geonature_config.toml`` situé dans le répertoire ``config``

:: 
	
    URL_APPLICATION = 'http://geonature.mondomaine.fr'
	API_ENDPOINT = 'http://geonature.mondomaine.fr/api'
	API_TAXHUB = 'http://taxhub.mondomaine.fr/api'


Pour que ces modifications soient prises en compte, lancer les commandes suivantes depuis le répertoire ``geonature/backend`` :

::
	
    cd geonature/backend
    source venv/bin/activate
    geonature update_configuration
    deactivate


Les applications sont désormais accessibles sur leurs sous-domaines respectifs !


**Configuration de sous-domaines avec HTTPS**


Pour voir la procédure de certification dans son ensemble, consulter la documentation HTTPS. 


Certifier chaque sous-domaine
-----------------------------

Une fois cerbot installé, il faut produire un certificat pour chacun des sous-domaines créés. Lancer la commande suivante pour générer des certificats et des clés pour l’ensemble des noms de domaines que vous souhaitez mettre en HTTPS.

::
  
    sudo certbot certonly --webroot --webroot-path /var/www/html --domain geonature.mondomaine.fr --email monemail@domaine.fr
    sudo certbot certonly --webroot --webroot-path /var/www/html --domain taxhub.mondomaine.fr --email monemail@domaine.fr
    sudo certbot certonly --webroot --webroot-path /var/www/html --domain usershub.mondomaine.fr --email monemail@domaine.fr


- ``certonly`` : demander la création du certificat uniquement.
- ``--webroot`` : utiliser le plugin webroot qui se contente d’ajouter des fichiers dans le dossier défini via ``--webroot-path``.
- ``--webroot-path`` : le chemin de votre « DocumentRoot » Apache. Certbot placera ses fichiers dans ``$DocumentRoot/.well-known/`` pour les tests et vérifications
- ``--domain`` : le nom de domaine à certifier. Mettre tous les sous-domaines à certifier
- ``--email`` : l’adresse qui recevra les notifications de Let’s Encrypt. Principalement pour rappeler de renouveler le certificat le moment venu.


Les certificats obtenus se trouvent dans les dossiers ``/etc/letsencrypt/live/geonature.mondomaine.fr/``, ``/etc/letsencrypt/live/taxhub.mondomaine.fr/`` et ``/etc/letsencrypt/live/usershub.mondomaine.fr/``.


Mettre à jour les configurations Apache de chaque application
-------------------------------------------------------------

Les fichiers de configuration Apache des différentes applications ainsi que la configuration de l'application GeoNature doivent être mis à jour en conséquence. Dans chaque configuration, le premier VirtualHost (``*:80``) sert à faire la redirection du http vers le https. Le second (``*:443``) est la configuration du https. Pensez à remplacer "mondomaine" et les chemins des fichiers de certification SSLCertificate.  


Modifier le fichier de configuration de GeoNature ``/etc/apache2/sites-available/geonature.conf`` et remplacer son contenu par :

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

Pensez à modifier également le fichier ``/etc/apache2/sites-available/geonature_maintenance.conf``.


Modifier le fichier de configuration de TaxHub ``/etc/apache2/sites-available/taxhub.conf`` et remplacer son contenu par :

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


Modifier le fichier de configuration de UsersHub ``/etc/apache2/sites-available/usershub.conf`` et remplacer son contenu par :

::
	
    #Configuration originale de UsersHub
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
	#FIN configuration UsersHub


Prise en compte des nouvelles configurations Apache
---------------------------------------------------

Activer les modules ``ssl``, ``headers`` et ``rewrite`` puis redémarrer Apache :

::

    sudo a2enmod ssl
    sudo a2enmod rewrite
    sudo a2enmod headers
    sudo apachectl restart

La configuration de l'application GeoNature doit également être mise à jour.


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


Pour que ces modifications soient prises en compte, lancer les commandes suivantes depuis le répertoire ``geonature/backend`` :

::
	
    cd geonature/backend
    source venv/bin/activate
    geonature update_configuration
    deactivate

Les applications sont désormais accessibles sur leurs sous-domaines respectifs, tous certifiés https ! (Il peut être nécessaire de vider le cache du navigateur).
