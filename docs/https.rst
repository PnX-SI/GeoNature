HTTPS
*****

Cette documentation est indicative car non-spécifique à GeoNature. Elle donne des indications sur la mise en place d'un certificat SSL pour une application web servie par Apache.

Utilisation de Cerbot
---------------------

**Source.** `Sécuriser facilement et gratuitement un site avec HTTPS <https://korben.info/securiser-facilement-gratuitement-site-https.html>`_

La procédure décrit une méthode de certification HTTPS de votre domaine, grâce au service `Let's Encrypt <https://letsencrypt.org/>`_. Les manipulations ont été effectuées sur un serveur Debian 9 avec Apache2 installé, et un utilisateur bénéficiant des droits sudo.

Cerbot ne peut pas être utilisé pour la création d'un certificat sur une adresse IP (Exemple d'instances de test sans nom de domaine). Pour celà utiliser OpenSSL présenté rapidement ci-dessous.
Installation :

::
 
    sudo apt-get install python3-certbot-apache

Lancer la commande suivante pour générer des certificats et des clés pour le nom de domaine que vous souhaitez mettre en HTTPS.

::
  
    sudo certbot --apache --email monemail@mondomaine.fr
    
Activer les modules ``ssl``, ``headers`` et ``rewrite`` puis redémarrer Apache :

::

    sudo a2enmod ssl
    sudo a2enmod rewrite
    sudo a2enmod headers
    sudo apachectl restart

Les fichiers de configuration du site UsersHub n'est pas à modifier, il sera automatiquement associé à la configuration HTTPS. En revanche, la configuration de GeoNature doit être mise à jour.

Utilisation de OpenSSL sur un environnement de test
---------------------------------------------------

Cette procédure a été testée sur Debian 12 et Apache2 avec l'utilisation d'un certificat auto-signé. Cela signifie qu'une alerte sera envoyée aux navigateurs indiquant un manque de sécurisation du serveur.
Cette méthode fonctionne avec un serveur sans nom de domaine.

Création d'un nouveau certificat de 365 jours (30 jours par défaut), de type X509 avec l'emplacement des fichiers de certificat et de clé privé.

.. code:: shell

    sudo openssl req -new -x509 -days 365 -nodes -out /etc/ssl/certs/mailserver.crt -keyout /etc/ssl/private/mailserver.key

Sécurisation de la clé

.. code:: shell

    sudo chmod 440 /etc/ssl/private/mailserver.key

Chargement du module ssl dans Apache

.. code:: shell

    sudo a2enmod ssl

Modification de la configuration du VirtualHost en éditant le fichier ``/etc/apache2/sites-available/geonature.conf``

.. code:: apache

    <VirtualHost *:443>
        ServerName x.x.x.x
        […]
        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/mailserver.crt
        SSLCertificateKeyFile /etc/ssl/private/mailserver.key
    </VirtualHost>

::

    sudo apachectl restart

Configuration de l'application GeoNature
----------------------------------------

Il est nécessaire de mettre à jour le fichier de configuration ``geonature_config.toml`` situé dans le répertoire ``geonature/config`` :

:: 
	
  cd geonature/config
  nano geonature_config.toml


Modifier les éléments suivants : 

.. code:: toml
	
  URL_APPLICATION = 'https://mondomaine.fr/geonature'
  API_ENDPOINT = 'https://mondomaine.fr/geonature/api'

Pour que ces modifications soient prises en compte, exécuter les :ref:`actions à effecture après modification de la configuration <post_config_change>`.

Les applications sont désormais accessibles sur votre domaine sécurisé en HTTPS !
