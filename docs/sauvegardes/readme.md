PRODUCTION DES BACKUPS
======================

Sur le serveur OVH, il faut produire des fichiers de backup des bases postgresql et des répertoires contenant les scripts et les fichiers des applications (médias et configuration notamment). 
Il est recommandé d'exécuter les actions qui suivent avec l'utilisateur ``root``

Postgresql
----------

Les sauvegardes sont faites toutes les nuits et conservées un mois (31 fichiers). Une sauvegarde mensuelle est conservée un an (12 fichiers). Cette politique de sauvegarde peut-être adaptée.

Voir le script ``pgsql-backup.sh`` qui peut être placé dans ``/usr/local/bin/``.

Ce script sauvegarde toutes les bases de données. Dans l'exemple fourni, pour les bases de GeoNature et de UsersHub, il ne sauvegarde la base complete que le premier du mois. Les autres jours, il ne sauvegarde que les schémas "vivants". (option -n). Cette politique de sauvegarde également être adaptée.

Ce script comporte également une copie des fichiers de backup vers le serveur de backup-ftp d'ovh. Pour l'utiliser, votre serveur OVH doit disposer de ce service et il faut installer ncftp. Sinon commenter ou retirer les lignes concernées (ncftpput).

Ce fichier doit être executable : ``chmod +x /usr/local/bin/pgsql-backup.sh``

Attention, l'utilisateur ``postgres`` doit être le propriétaire de ce fichier ou disposer des droits d'exécution sur celui-ci. 
chown postgres /usr/local/bin/pgsql-backup.sh


Scripts et fichiers des applications
------------------------------------

Les sauvegardes sont faites toutes les nuits mais vu la taille potentiellement importante de ce fichier, il est écrasé chaque nuit par la nouvelle sauvegarde. Cette politique de sauvegarde peut-être adaptée.

Voir le script ``internet-backup.sh`` qui peut être également placé dans ``/usr/local/bin/``.

Ce script comporte également une copie des fichiers de backup vers le serveur de backup-ftp d'ovh. Pour l'utiliser votre serveur OVH doit disposer de ce service et il faut installer ncftp. Sinon commenter ou retirer les lignes concernées (ncftpput).

Ce fichier doit être executable : ``chmod +x /usr/local/bin/internet-backup.sh``

Automatisation des sauvegardes sur le serveur OVH
-------------------------------------------------

Ajouter ceci à la fin du crontab de l'utilisateur ``postgres`` (commande = crontab -e)

# sauvegarde des bases de donnees postgres à 3h45 du matin
45 3 * * * /usr/local/bin/pgsql-backup.sh

Ajouter ceci à la fin du crontab de l'utilisateur ``root``

# sauvegarde des applications internet
# vers le ftp ovh à 1h15 du matin
15 1 * * * /usr/local/bin/internet-backup.sh


INSTALLATION et CONFIGURATION de RSYNC
======================================

Mise en place de rsync sur le serveur OVH
-----------------------------------------

Voir le fichier ``rsync_server.rst`` pour la configuration. Il existe également plusieurs ressource en ligne pour configurer rsync coté serveur. Demander à Lilo ;-)


Récupération des backups sur une machine locale
===============================================

Linux
-----

Rsync client doit être présent sur la machine qui récupère les backups. Il y a plusieurs manières de configurer rsync ; de façon incrémentielle ou pas.

Voir un exemple avec le script ``rsync_client.sh``.

Ce script récupère les fichiers des modules rsync ``geonature`` et ``usershub`` configuré sur le deamon rsync (``rsync_server.rst``) du serveur OVH et les place dans des répertoires locaux ; par exemple : ``/home/mylocaluser/svg_geonature/``

Windows
-------

La partie windows n'est utile que pour remonter des backups sur une machine windows locale. 

Le script est fourni à titre d'exemple. Usage ancien, non testé récemment. Fonctionnement non garanti.