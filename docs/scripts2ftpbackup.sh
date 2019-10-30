# CAUTION : all local and ftp directories and subdirectories destinations have to be created before running this script
BKPDIR="/var/backups/internet"
TODAY=`date +%d`
DAY=`date +%A |tr 'A-Z' 'a-z'`
MONTH=`date +%B |tr 'A-Z' 'a-z'`
DEBUG="/bin/false" #DEBUG="/bin/echo"

$DEBUG "*** Start internet applications backup ***"
	nice -n 0 tar -czf $BKPDIR/taxhub/taxhub_medias.tar.gz /home/geonatadmin/taxhub/static/medias/
	# TaxHub
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/taxhub/ $BKPDIR/taxhub/taxhub_medias.tar.gz
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/taxhub/ /home/geonatadmin/taxhub/config.py
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/taxhub/ /home/geonatadmin/taxhub/settings.ini
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/taxhub/static/app/ /home/geonatadmin/taxhub/static/app/constants.js
	# GeoNature
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/geonature/config/ /home/geonatadmin/geonature/config/settings.ini
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/geonature/config/ /home/geonatadmin/geonature/config/geonature_config.toml
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/geonature/external_modules/occtax/config/ /home/geonatadmin/geonature/external_modules/occtax/config/conf_gn_module.toml
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/geonature/external_modules/dashboard/config/ /home/geonatadmin/geonature/external_modules/dashboard/config/conf_gn_module.toml
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/geonature/external_modules/validation/config/ /home/geonatadmin/geonature/external_modules/validation/config/conf_gn_module.toml
	# Synchronomade GN v1
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/synchronomade/webapi/apk/ /home/geonatadmin/synchronomade/webapi/apk/*.*
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/synchronomade/webapi/datas/ /home/geonatadmin/synchronomade/webapi/datas/*.*
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/synchronomade/webapi/ /home/geonatadmin/synchronomade/webapi/gunicorn_start.sh
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/synchronomade/webapi/main/ /home/geonatadmin/synchronomade/webapi/main/settings_local.py
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/synchronomade/webapi/main/ /home/geonatadmin/synchronomade/webapi/main/settings.py
	# UsersHub
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/usershub/config/ /home/geonatadmin/usershub/config/config.py
	nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/dayly-backup/usershub/config/ /home/geonatadmin/usershub/config/settings.ini

	if [ $(date +%d) == "29" ]; then
		# TaxHub
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/taxhub/ $BKPDIR/taxhub/taxhub_medias.tar.gz
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/taxhub/ /home/geonatadmin/taxhub/config.py
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/taxhub/ /home/geonatadmin/taxhub/settings.ini
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/taxhub/static/app/ /home/geonatadmin/taxhub/static/app/constants.js
		# GeoNature
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/geonature/config/ /home/geonatadmin/geonature/config/settings.ini
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/geonature/config/ /home/geonatadmin/geonature/config/geonature_config.toml
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/geonature/external_modules/occtax/config/ /home/geonatadmin/geonature/external_modules/occtax/config/conf_gn_module.toml
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/geonature/external_modules/dashboard/config/ /home/geonatadmin/geonature/external_modules/dashboard/config/conf_gn_module.toml
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/geonature/external_modules/validation/config/ /home/geonatadmin/geonature/external_modules/validation/config/conf_gn_module.toml
		# Synchronomade GN v1
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/synchronomade/webapi/apk/ /home/geonatadmin/synchronomade/webapi/apk/*.*
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/synchronomade/webapi/datas/ /home/geonatadmin/synchronomade/webapi/datas/*.*
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/synchronomade/webapi/ /home/geonatadmin/synchronomade/webapi/gunicorn_start.sh
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/synchronomade/webapi/main/ /home/geonatadmin/synchronomade/webapi/main/settings_local.py
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/synchronomade/webapi/main/ /home/geonatadmin/synchronomade/webapi/main/settings.py
		# UsersHub
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/usershub/config/ /home/geonatadmin/usershub/config/config.py
		nice -n 0 ncftpput -u myftpuser -p myftppass myftp.url.fr /geonature2/month-backup/usershub/config/ /home/geonatadmin/usershub/config/settings.ini
	fi 
	#rm $BKPDIR/taxhub/taxhub_medias.tar.gz
$DEBUG "*** End internet applications backup *****"
