nano install_all.ini

. install_all.ini


# Installation de l'environnement nécessaire à GeoNature2, TaxHub et
echo "Installation de l'environnement logiciel..."
sudo apt-get update
sudo apt-get upgrade
sudo apt-get -y install ntpdate
sudo ntpdate-debian
sudo apt-get install -y curl unzip git
sudo apt-get install -y apache2 libapache2-mod-wsgi
sudo apt-get install -y postgresql postgis postgresql-server-dev-9.4
sudo apt-get install -y python-dev python-pip libpq-dev python-setuptools python-gdal python-virtualenv build-essential
sudo apt-get install -y npm
sudo apt-get install -y python3 python3-dev python3-setuptools

sudo pip install virtualenv


# echo "Configuration de postgreSQL..."
# sudo sed -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" -i /etc/postgresql/*/main/postgresql.conf
# sudo sh -c 'echo "host    all             all             0.0.0.0/0            md5" >> /etc/postgresql/9.4/main/pg_hba.conf'
# sudo /etc/init.d/postgresql restart

echo "Création des utilisateurs postgreSQL..."
sudo -n -u postgres -s psql -c "CREATE ROLE $user_pg WITH LOGIN PASSWORD '$user_pg_pass';"

sudo sh -c 'echo "ServerName localhost" >> /etc/apache2/apache2.conf'
sudo a2enmod rewrite
sudo a2enmod wsgi
sudo apache2ctl restart

# Installation de GeoNature avec l'utilisateur courant
echo "Téléchargement et installation de GeoNature ..."
cd /tmp
wget https://github.com/PnEcrins/GeoNature/archive/$geonature_release.zip
unzip $geonature_release.zip
rm $geonature_release.zip
mv GeoNature-frontend-contact /home/$monuser/geonature/

cd /home/$monuser/geonature

# Configuration des settings de GeoNature
cp config/settings.ini.sample config/settings.ini
echo "Installation de la base de données et configuration de l'application GeoNature ..."
sed -i "s/drop_apps_db=.*$/drop_apps_db=$drop_geonaturedb/g" config/settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" config/settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" config/settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" config/settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" config/settings.ini
sed -i "s/srid_local=.*$/srid_local=$srid_local/g" config/settings.ini
sed -i "s/install_default_dem=.*$/srid_local=$install_default_dem/g" config/settings.ini
sed -i "s/add_sample_data=.*$/add_sample_data=$add_sample_data/g" config/settings.ini
sed -i "s/usershub_release=.*$/usershub_release=$usershub_release/g" config/settings.ini
sed -i "s/taxhub_release=.*$/taxhub_release=$taxhub_release/g" config/settings.ini
sed -i -e "s/\/var\/www/$apache_document_root/g" config/settings.ini



# Installation de la base de données GeoNature en root
sudo ./install_db.sh

# Installation et configuration de l'application GeoNature
./install_app.sh

#configuration apache de Geonature
sudo sh -c 'echo "# Configuration GeoNature 2" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "<Location /geonature/api>" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "ProxyPass  http://127.0.0.1:8000" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "ProxyPassReverse  http://127.0.0.1:8000" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "</Location>" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c '#FIN Configuration GeoNature 2>" >> /etc/apache2/sites-available/000-default.conf'


# Installation de TaxHub avec l'utilisateur courant
echo "Téléchargement et installation de TaxHub ..."
cd /tmp
wget https://github.com/PnX-SI/TaxHub/archive/$taxhub_release.zip
unzip $taxhub_release.zip
rm $taxhub_release.zip
mv TaxHub-$taxhub_release /home/$monuser/taxhub/
cd /home/$monuser/taxhub


# Configuration des settings de TaxHub
echo "Configuration de l'application TaxHub ..."
cp settings.ini.sample settings.ini
sed -i "s/drop_apps_db=.*$/drop_apps_db=false/g" settings.ini
sed -i "s/db_host=.*$/db_host=$pg_host/g" settings.ini
sed -i "s/db_port=.*$/db_port=$pg_port/g" settings.ini
sed -i "s/db_name=.*$/db_name=$geonaturedb_name/g" settings.ini
sed -i "s/user_pg=.*$/user_pg=$user_pg/g" settings.ini
sed -i "s/user_pg_pass=.*$/user_pg_pass=$user_pg_pass/g" settings.ini
sed -i "s/user_schema=.*$/user_schema=local/g" settings.ini
sed -i "s/usershub_host=.*$/usershub_host=$pg_host/g" settings.ini
sed -i "s/usershub_port=.*$/usershub_port=$pg_port/g" settings.ini
sed -i "s/usershub_db=.*$/usershub_db=$usershubdb_name/g" settings.ini
sed -i "s/usershub_user=.*$/usershub_user=$user_pg/g" settings.ini
sed -i "s/usershub_pass=.*$/usershub_pass=$user_pg_pass/g" settings.ini

# Configuration Apache de TaxHub
sudo touch /etc/apache2/sites-available/taxhub.conf
sudo sh -c 'echo "# Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "RewriteEngine  on" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "RewriteRule    \"taxhub$\"  \"taxhub/\"  [R]" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "<Location /taxhub>" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "ProxyPass  http://127.0.0.1:5000/ retry=0" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "ProxyPassReverse  http://127.0.0.1:5000/" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "</Location>" >> /etc/apache2/sites-available/taxhub.conf'
sudo sh -c 'echo "#FIN Configuration TaxHub" >> /etc/apache2/sites-available/taxhub.conf'

sudo sed -i "s/<\/VirtualHost>//g" /etc/apache2/sites-available/000-default.conf
sudo sed -i "s/# vim.*$//g" /etc/apache2/sites-available/000-default.conf
sudo sh -c 'echo "# Configuration TaxHub - ne fonctionne pas dans le 000-default.conf" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "RewriteEngine  on" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "RewriteRule    \"taxhub$\"  \"taxhub/\"  [R]" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "" >> /etc/apache2/sites-available/000-default.conf'
sudo sh -c 'echo "# vim: syntax=apache ts=4 sw=4 sts=4 sr noet" >> /etc/apache2/sites-available/000-default.conf'


sudo a2ensite taxhub
sudo a2enmod proxy
sudo a2enmod proxy_http
# Installation et configuration de l'application TaxHub
./install_app.sh
sudo apache2ctl restart