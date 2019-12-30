. /home/`whoami`/geonature_old/config/settings.ini

mkdir /home/`whoami`/geonature/var/
mkdir /home/`whoami`/geonature/var/log
mkdir /home/`whoami`/geonature/tmp
touch /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log

echo "Download and extract habref file..."
if [ ! -d '/home/`whoami`/geonature/tmp/habref/' ]
then
    mkdir /home/`whoami`/geonature/tmp/habref
fi
if [ ! -f '/home/`whoami`/geonature/tmp/habref/HABREF_50.zip' ]
then
  wget https://geonature.fr/data/inpn/habitats/HABREF_50.zip -P /home/`whoami`/geonature/tmp/habref
else
  echo HABREF_50.zip exists
fi
unzip /home/`whoami`/geonature/tmp/habref/HABREF_50.zip -d /home/`whoami`/geonature/tmp/habref

wget https://raw.githubusercontent.com/PnX-SI/Habref-api-module/0.1.1/src/pypn_habref_api/data/habref.sql -P /home/`whoami`/geonature/tmp/habref
wget https://raw.githubusercontent.com/PnX-SI/Habref-api-module/0.1.1/src/pypn_habref_api/data/data_inpn_habref.sql -P /home/`whoami`/geonature/tmp/habref 

parentdir=/home/`whoami`/geonature
# sed to replace /tmp/taxhub to ~/<geonature_dir>/tmp.taxhub
sed -i 's#'/tmp/habref'#'$parentdir/tmp/habref'#g' /home/`whoami`/geonature/tmp/habref/data_inpn_habref.sql

echo 'Insertion des données habitat (cela peut être long...)'
echo "--------------------" &>/home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
echo 'HABREF' &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
echo "--------------------" &>/home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /home/`whoami`/geonature/tmp/habref/habref.sql &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
sudo -u postgres -s psql -d $db_name  -f /home/`whoami`/geonature/tmp/habref/data_inpn_habref.sql &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
echo 'Ok'


# migration nomenclature
wget https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/develop/data/update1.3.0to1.3.1.sql -P /home/`whoami`/geonature/tmp/
wget https://raw.githubusercontent.com/PnX-SI/Nomenclature-api-module/develop/data/update1.3.1to1.3.2.sql -P /home/`whoami`/geonature/tmp/
echo 'Migration sql nomenclatures...'
echo "--------------------" &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
echo 'NOMENCLATURES' &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
echo '------------------' &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /home/`whoami`/geonature/tmp/update1.3.0to1.3.1.sql  &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /home/`whoami`/geonature/tmp/update1.3.1to1.3.2.sql  &>> /home/`whoami`/geonature/var/log/2.2.1to2.3.0.log
echo 'Ok'
