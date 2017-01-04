Mise en place de rsync coté serveur applicatif
=


Liens utiles
-

* http://www.delafond.org/traducmanfr/man/man1/rsync.1.html#index
* http://www.journaldunet.com/developpeur/tutoriel/out/060104-rsync-sauvegarde-configuration.shtml
* http://www.brunop.be/rsync-backup-de-windows-vers-linux-50.html


Installation
=

 **Installer rsync** :
 
	sudo apt-get update
	sudo apt-get install rsync


Configuration
=
**Créer le fichier de configuration** ``/etc/rsyncd.conf`` des modules rsync qui pourront être synchronisés. Ici un exemple avec 2 modules : ``geonature`` et ``usershub``  :

	nano /etc/rsyncd.conf

<i class="icon-file"></i> Mettre ce contenu :
```
	uid = rsyncuser  
	gid = www-data  
	use chroot = yes  
	pid file = /var/run/rsyncd.pid  

	[geonature]
  	  path = /home/mylinuxuser/geonature  
  	  comment = fichiers de l’application geonature  
  	  auth users = rsyncuser  
  	  secrets file = /etc/rsyncd.secrets  

	[usershub]
  	  path = /home/mylinuxuser/usershub  
  	  comment = fichiers de l’application usershub  
  	  auth users = rsyncuser  
  	  secrets file = /etc/rsyncd.secrets 
``` 

**Créer un fichier** ``/etc/rsyncd.secrets`` **comportant le mot de passe de l'utilisateur** ``rsyncuser`` ayant accès aux modules du service rsync:

		nano /etc/rsyncd.secrets

<i class="icon-file"></i> Mettre ce contenu (remplacer monmdpass par votre mot de pass) :

	rsyncuser:monmdpass

**Affecter les droits aux fichiers** :

		touch /var/run/rsyncd.pid
		chmod 640 /etc/rsyncd.conf
		chmod 600 /etc/rsyncd.secrets

**Activer rsync** : dans le fichier ``/etc/default/rsync``, passer la valeur de RSYNC_ENABLE à true :

		nano /etc/default/rsync
		
**Lancez le service rsync**  :

	rsync --daemon


**Rebooter la machine** sinon le rsync restart ne fonctionne pas :

		/etc/init.d/rsync restart