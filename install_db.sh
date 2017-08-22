#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config/settings.ini

function database_exists () {
    # /!\ Will return false if psql can't list database. Edit your pg_hba.conf
    # as appropriate.
    if [ -z $1 ]
        then
        # Argument is null
        return 0
    else
        # Grep db name in the list of database
        sudo -n -u postgres -s -- psql -tAl | grep -q "^$1|"
        return $?
    fi
}


if database_exists $db_name
then
        if $drop_apps_db
            then
            echo "Suppression de la base..."
            sudo -n -u postgres -s dropdb $db_name
        else
            echo "La base de données existe et le fichier de settings indique de ne pas la supprimer."
        fi
fi

if [ ! -d "log" ]; then
    mkdir log
fi

if ! database_exists $db_name
then
    echo "Création de la base..."
    echo "--------------------" &> log/install_db.log
    echo "Création de la base" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s createdb -O $user_pg $db_name
    echo "Ajout de postgis à la base..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Ajout de postgis à la base" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';" &>> log/install_db.log


    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "Grant..."
    cp data/grant.sql /tmp/grant.sql
    sudo sed -i "s/MYPGUSER/$user_pg/g" /tmp/grant.sql
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Grant" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -f /tmp/grant.sql &>> log/install_db.log


    echo "Récupération et création du schéma utilisateurs..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création du schéma utilisateurs" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    cd data/utilisateurs
    wget https://raw.githubusercontent.com/PnEcrins/UsersHub/$usershub_release/data/usershub.sql
    cd ../..
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/utilisateurs/usershub.sql  &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/utilisateurs/create_view_utilisateurs.sql  &>> log/install_db.log


    echo "Téléchargement et décompression des fichiers du taxref..."
    cd data/taxonomie/inpn

    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/inpn/data_inpn_v9_taxhub.sql

    array=( TAXREF_INPN_v9.0.zip    ESPECES_REGLEMENTEES_20161103.zip    LR_FRANCE_20160000.zip )
    for i in "${array[@]}"
    do
      if [ ! -f '/tmp/'$i ]
      then
          wget http://geonature.fr/data/inpn/taxonomie/$i -P /tmp
      else
          echo $i exists
      fi
    done
    unzip /tmp/TAXREF_INPN_v9.0.zip -d /tmp
    unzip /tmp/ESPECES_REGLEMENTEES_20161103.zip -d /tmp
    unzip /tmp/LR_FRANCE_20160000.zip -d /tmp
    cd ..

    echo "Récupération des scripts de création du schéma taxonomie..."
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdb.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/taxhubdata_taxon_example.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/vm_hierarchie_taxo.sql
    cd ../..

    echo "Création du schéma taxonomie..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création du schéma taxonomie" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/taxhubdb.sql  &>> log/install_db.log

    echo "Insertion  des données taxonomiques de l'inpn... (cette opération peut être longue)"
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Insertion  des données taxonomiques de l'inpn" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    sudo -n -u postgres -s psql -d $db_name -f data/taxonomie/inpn/data_inpn_v9_taxhub.sql &>> log/install_db.log

    echo "Création des données dictionnaires du schéma taxonomie..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création des données dictionnaires du schéma taxonomie" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/taxhubdata.sql  &>> log/install_db.log

    echo "Insertion d'un jeu de taxons exemples dans le schéma taxonomie..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Insertion d'un jeu de taxons exemples dans le schéma taxonomie" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/taxhubdata_taxon_example.sql  &>> log/install_db.log

    echo "Création de la vue représentant la hierarchie taxonomique..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création de la vue représentant la hierarchie taxonomique" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/taxonomie/vm_hierarchie_taxo.sql  &>> log/install_db.log

    echo "Compléter le schéma taxonomie..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Compléter le schéma taxonomie" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/complements_taxonomie.sql  &>> log/install_db.log


    echo "Création du schéma meta..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création du schéma meta" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/meta.sql  &>> log/install_db.log


    echo "Création du schéma nomenclatures..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création du schéma nomenclatures" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/nomenclatures.sql  &>> log/install_db.log

    echo "Insertion de la nomenclature..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Insertion de la nomenclature" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/data_nomenclatures.sql  &>> log/install_db.log


    echo "Création et insertion du schéma medias..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création et insertion du schéma medias" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/core/medias.sql  &>> log/install_db.log


    echo "Création du schéma synthese..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création du schéma synthese" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    cp data/core/synthese.sql /tmp/synthese.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/synthese.sql
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/synthese.sql  &>> log/install_db.log


    # suppression des fichiers : on ne conserve que les fichiers compressés
    echo "nettoyage..."
    rm /tmp/*.txt
    rm /tmp/*.csv
    rm data/utilisateurs/usershub.sql
    rm data/taxonomie/taxhubdb.sql
    rm data/taxonomie/vm_hierarchie_taxo.sql
    rm data/taxonomie/taxhubdata.sql
    rm data/taxonomie/taxhubdata_taxon_example.sql
    #rm data/taxonomie/inpn/*.zip
    rm data/taxonomie/inpn/data_inpn_v9_taxhub.sql

    echo "Droit sur le répertoire log..."
    chmod -R 777 log
fi
