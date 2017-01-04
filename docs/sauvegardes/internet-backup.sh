#!/bin/bash
#script de backup des scripts applicatifs
#Ce script crée un fichier de backup qui est écrasé chaque jour

BKPDIR="/var/backups/internet/"
TODAY=`date +%d`
DAY=`date +%A |tr 'A-Z' 'a-z'`
MONTH=`date +%B |tr 'A-Z' 'a-z'`
DEBUG="/bin/false" #DEBUG="/bin/echo"

$DEBUG "*** Start internet applications backup ***"
		nice -n 0 tar -czf $BKPDIR/last_internet_script.tar.gz --exclude '.*' --exclude '*/cache/*' --exclude '*/log/*' --exclude '*/logs/*' /home/mylinuxuser
		nice -n 0 ncftpput -u myserver_ovh.eu -p mypass myserver_backupftp_ovh.net /prod/dayly-backup/ $BKPDIR/last_internet_script.tar.gz		
		#le premier du mois on crée un copie qui sera la sauvegarde mensuelle (conservée un an)
		if [ $(date +%d) == "01" ]; then
			nice -n 0 cp $BKPDIR/last_internet_script.tar.gz $BKPDIR/internet_script_$MONTH.tar.gz
			nice -n 0 ncftpput -u myserver_ovh.eu -p mypass myserver_backupftp_ovh.net /prod/month-backup/ $BKPDIR/internet_script_$MONTH.tar.gz
		fi 
		#nice -n 0 rm $BKPDIR/last_internet_script.tar.gz
$DEBUG "*** End internet applications backup *****"


