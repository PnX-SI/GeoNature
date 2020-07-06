====================
MAJ Globale RC3->RC4
====================

Janvier 2019 - Par @DonovanMaillard. Indicatif, se référer aux documentations officielles et notes de version.

**************************
Installation de UsersHub 2
**************************

* Télécharger la version UsersHub 2

::

    cd
    wget https://github.com/PnEcrins/UsersHub/archive/X.Y.Z.zip
    unzip X.Y.Z.zip

* Renommer l'ancien et le nouveau répertoire

::

    mv /home/`whoami`/usershub/ /home/`whoami`/usershub_old/
    mv UsersHub-X.Y.Z /home/`whoami`/usershub/

* Créer et renseigner le fichier de configuration de Usershub2 (ici donnees minimales=true, donnees exemple=false)

::

    cd usershub
    cp config/settings.ini.sample config/settings.ini
    nano config/settings.ini

* Mettre à jour la base de données

::

    psql -U MY_PG_USER -d MY_DB -h localhost -f data/update_1.3.3to2.0.0.sql

* Installer l'application

::

    ./install_app.sh

* Mettre à jour la configuration Apache, en supprimant le DocumentRoot et Directory, et en renseignant :

::

    sudo nano /etc/apache2/sites-available/usershub.conf


::

    <Location /usershub>
        ProxyPass  http://localhost:5001/
        ProxyPassReverse  http://localhost:5001/
    </Location>

* Relancer apache et les applications (supervisor) :

::

    sudo apachectl restart

::

    sudo supervisorctl restart all


*************************************
Ajout de l'extension pg_trgm à la BDD
*************************************


::

    sudo su postgres
    psql -d MYDB
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    \q
    exit


*********************
Mise à jour de TaxHub
*********************

* Télécharger la version TaxHub 1.6.1

::

    cd
    wget https://github.com/PnX-SI/TaxHub/archive/1.6.1.zip
    unzip 1.6.1.zip

* Renommer l'ancien et le nouveau répertoire

::

    mv /home/`whoami`/taxhub/ /home/`whoami`/taxhub_old/
    mv TaxHub-1.6.1 /home/`whoami`/taxhub/

* Mise à jour de la base de données pour la compatibilité avec UsersHub2

* NE PAS JOUER LE SCRIPT ``data/adds_for_usershub.sql``

* Mise à jour de la base de données pour la compatibilité avec TaxHub 1.6.1

::

    psql -U MY_PG_USER -d MY_DB  -h localhost -f data/update1.5.1to1.6.0.sql

* Récupérer les fichiers de configuration suivants depuis la précédente version de taxhub

::

    cp taxhub_old/settings.ini taxhub/settings.ini
    cp taxhub_old/config.py taxhub/config.py
    cp taxhub_old/static/app/constants.js taxhub/static/app/constants.js

* Récupérer les médias uploadés dans la précédente version de taxhub

::

    cp -aR taxhub_old/static/medias/ taxhub/static/

* Lancer la mise à jour de l'application

::

    cd taxhub
    ./install_app.sh


**********************************************
Mise à jour de la base de données de GeoNature
**********************************************

* Télécharger la version GeoNature RC4 (2.0.0-rc.4.1)

::

    cd
    wget https://github.com/PnX-SI/GeoNature/archive/2.0.0-rc.4.1.zip
    unzip 2.0.0-rc.4.1.zip

* Renommer l'ancien et le nouveau répertoire

::

    mv /home/`whoami`/geonature/ /home/`whoami`/geonature_old/
    mv GeoNature-2.0.0-rc.4.1 /home/`whoami`/geonature/

* Mise à jour de la base de données de GeoNature pour la RC4

::

    cd geonature
    psql -U MY_PG_USER -d MY_DB -h localhost -f data/migrations/2.0.0rc3.1-to-2.0.0rc4.sql


**************************************
Mise à jour de l'application GeoNature
**************************************

* Lancement de la migration vers la nouvelle version 

* !! Le répertoire geonature_old doit être à la racine de l'utilisateur pour lancer ce script

::

    ./install/migration/migration.sh

-- Fin de la mise à jour
