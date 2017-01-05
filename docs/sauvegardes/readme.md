SAUVEGARDES
===========

Sur le serveur, il faut produire des fichiers de backup des bases de données postgreSQL et des répertoires contenant les scripts et les fichiers des applications (médias et configuration notamment). 

Pour cela, 2 scripts SH (``gsql-backup.sh`` et ``internet-backup.sh``) vous sont proposés (à adapter à votre contexte). Ils vont être éxécutés automatiquement et régulièrement grace à des taches cron et vont générés des fichiers ``tar.gz`` contenant les sauvegardes des bases de données et des fichiers des applications.

Ces fichiers sont ensuite copiés en FTP sur la partie dédiée à cela par l'hébergeur (optionnel) grace à ``ncftp``. 

Enfin rsync va permettre de récupérer régulièrement ces fichiers sur un serveur local. 

Il est recommandé d'exécuter les actions qui suivent avec l'utilisateur ``root``.

PostgreSQL
----------

Les sauvegardes sont faites toutes les nuits et conservées un mois (31 fichiers). Une sauvegarde mensuelle est conservée un an (12 fichiers). Cette politique de sauvegarde peut-être adaptée.

Voir le script [pgsql-backup.sh](https://github.com/PnEcrins/GeoNature/blob/master/docs/sauvegardes/pgsql-backup.sh) qui peut être placé dans ``/usr/local/bin/``.

Ce script sauvegarde toutes les bases de données. Dans l'exemple fourni, pour les BDD de GeoNature et de UsersHub, il ne sauvegarde la BDD complete que le premier du mois. Les autres jours, il ne sauvegarde que les schémas "vivants". (option -n). Cette politique de sauvegarde peut également être adaptée.

Ce script comporte aussi une copie des fichiers de backup vers le serveur de backup-ftp de l'hebergeur (OVH dans notre cas). Pour l'utiliser, votre serveur doit disposer de ce service et il faut installer ``ncftp``. Sinon commenter ou retirer les lignes concernées (``ncftpput``).

Ce fichier doit être éxecutable : 

	chmod +x /usr/local/bin/pgsql-backup.sh

Attention, l'utilisateur ``postgres`` doit être le propriétaire de ce fichier ou disposer des droits d'exécution sur celui-ci. 

	chown postgres /usr/local/bin/pgsql-backup.sh


Scripts et fichiers des applications
------------------------------------

Les sauvegardes sont faites toutes les nuits mais vu la taille potentiellement importante de ce fichier, il est écrasé chaque nuit par la nouvelle sauvegarde. Cette politique de sauvegarde peut-être adaptée.

Voir le script [internet-backup.sh](https://github.com/PnEcrins/GeoNature/blob/master/docs/sauvegardes/internet-backup.sh) qui peut être également placé dans ``/usr/local/bin/``.

Ce script comporte également une copie des fichiers de backup vers le serveur de backup-ftp de l'hébergeur. Pour l'utiliser votre serveur doit disposer de ce service et il faut installer ``ncftp``. Sinon commenter ou retirer les lignes concernées (``ncftpput``).

Ce fichier doit être executable : 

	chmod +x /usr/local/bin/internet-backup.sh

Automatisation des sauvegardes sur le serveur
---------------------------------------------

**Ajouter ceci à la fin du crontab de l'utilisateur ``postgres``**
(``crontab -e`` pour éditer le crontab).

``` 
# sauvegarde des bases de donnees postgres à 3h45 du matin
45 3 * * * /usr/local/bin/pgsql-backup.sh

``` 

**Ajouter ceci à la fin du crontab de l'utilisateur ``root``**

``` 
# sauvegarde des applications internet
# vers le ftp ovh à 1h15 du matin
15 1 * * * /usr/local/bin/internet-backup.sh
``` 

Installation et configuration de RSYNC
--------------------------------------

**1. Mise en place de rsync sur le serveur**

Voir la documentation [rsync_server.md](https://github.com/PnEcrins/GeoNature/blob/master/docs/sauvegardes/rsync_server.md) pour la configuration de rsync. 

Il existe également plusieurs ressources en ligne pour configurer rsync coté serveur. Demander à Lilo ;-)

**2. Récupération des backups sur une machine locale**

* Linux

Rsync client doit être présent sur la machine qui récupère les backups. Il y a plusieurs manières de configurer rsync (de façon incrémentielle ou non).

Voir un exemple avec le script [rsync_client.sh](https://github.com/PnEcrins/GeoNature/blob/master/docs/sauvegardes/rsync_client.sh).

Ce script récupère les fichiers des modules rsync ``geonature`` et ``usershub`` configuré sur le daemon rsync (voir documentation [rsync_server.md](https://github.com/PnEcrins/GeoNature/blob/master/docs/sauvegardes/rsync_server.md)) du serveur et les place dans des répertoires locaux, par exemple : ``/home/mylocaluser/svg_geonature/``

* Windows

La partie Windows n'est utile que pour remonter des backups sur une machine Windows locale. 

Le script est fourni à titre d'exemple. Usage ancien, non testé récemment. Fonctionnement non garanti.
