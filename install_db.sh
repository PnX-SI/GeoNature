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


    echo "Création du schéma taxonomie..."
    echo "Téléchargement et décompression des fichiers du taxref..."
    cd data/taxonomie/inpn
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/$taxhub_release/data/inpn/data_inpn_v9_taxhub.sql
    wget https://github.com/PnX-SI/TaxHub/raw/$taxhub_release/data/inpn/TAXREF_INPN_v9.0.zip
    wget https://github.com/PnX-SI/TaxHub/raw/$taxhub_release/data/inpn/ESPECES_REGLEMENTEES.zip
    wget https://github.com/PnX-SI/TaxHub/raw/$taxhub_release/data/inpn/LR_FRANCE.zip
    unzip TAXREF_INPN_v9.0.zip -d /tmp
    unzip ESPECES_REGLEMENTEES.zip -d /tmp
    unzip LR_FRANCE.zip -d /tmp
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

    echo "Copie des scripts de création de la base GeoNature dans un répertoire temporaire..."
    cp data/core/synthese.sql /tmp/synthese.sql
    cp data/core/data_synthese.sql /tmp/data_synthese.sql
    cp data/modules/contactfaune.sql /tmp/contactfaune.sql
    cp data/modules/contactflore.sql /tmp/contactflore.sql
    cp data/modules/contactinv.sql /tmp/contactinv.sql
    cp data/modules/florestation.sql /tmp/florestation.sql
    cp data/modules/florepatri.sql /tmp/florepatri.sql
    cp data/modules/bryophytes.sql /tmp/bryophytes.sql

    echo "Application du paramètre de la projection locale..."
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/synthese.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/data_synthese.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/contactfaune.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/contactflore.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/contactinv.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/florestation.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/florepatri.sql
    sudo sed -i "s/MYLOCALSRID/$srid_local/g" /tmp/bryophytes.sql

    echo "Création des schémas du coeur de la base GeoNature..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création des schémas du coeur de la base GeoNature" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/synthese.sql  &>> log/install_db.log

    echo "Insertion des données des tables dictionnaires de la base..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Insertion des données des tables dictionnaires de la base" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/data_synthese.sql  &>> log/install_db.log

    echo "Création des schémas des modules..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création des schémas des modules" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "      ...schéma contact faune..."
    echo "--------------------" &>> log/install_db.log
    echo "Schéma contact faune" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/contactfaune.sql  &>> log/install_db.log

    echo "      ...schéma contact flore..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Schéma contact flore" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/contactflore.sql  &>> log/install_db.log

    echo "      ...schéma contact invertébré..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Schéma contact invertébré" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/contactinv.sql  &>> log/install_db.log

    echo "      ...schéma flore station...."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Schéma flore station" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/florestation.sql  &>> log/install_db.log

    echo "      ...schéma flore patri..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Schéma flore patri..." &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/florepatri.sql  &>> log/install_db.log

    echo "      ...schéma bryophytes..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Schéma bryophytes." &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f /tmp/bryophytes.sql  &>> log/install_db.log

    #TODO : revoir la requête de ce script à partir de la synthese
    echo "Création des éléments nécessaire au fonctionnement des mobiles..."
    echo "" &>> log/install_db.log
    echo "" &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "Création des éléments nécessaire au fonctionnement des mobiles." &>> log/install_db.log
    echo "--------------------" &>> log/install_db.log
    echo "" &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/modules/nomade.sql  &>> log/install_db.log

    echo "Décompression des fichiers des communes de France métropolitaine..."
    cd data/layers
    tar -xzvf communes_metropole.tar.gz
    cd ../..

    if $install_sig_layers
    then
        echo "Insertion  du référentiel géographique : communes métropolitaines... (cette opération peut être longue)"
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Insertion  du référentiel géographique : communes métropolitaines" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name  -f data/layers/communes_metropole.sql &>> log/install_db.log

        echo "Décompression des fichiers du référentiel géographique..."
        cd data/layers
        unzip apb.zip
        unzip bios.zip
        unzip cdl.zip
        unzip cen.zip
        unzip pn.zip
        unzip pnr.zip
        unzip pnm.zip
        unzip ramsar.zip
        unzip rb.zip
        unzip ripn.zip
        unzip rnc.zip
        unzip rncfs.zip
        unzip rnn.zip
        unzip rnr.zip
        unzip sic.zip
        unzip zps.zip
        unzip zico.zip
        unzip znieff1.zip
        unzip znieff2.zip
        unzip znieff1_mer.zip
        unzip znieff2_mer.zip
        mkdir sql
        cd ../..

        echo "Insertion  du référentiel géographique : zones à statut de france métropolitaine..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Insertion  du référentiel géographique : zones à statut de france métropolitaine" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "...Aires de protection de biotope..."
        echo "--------------------" &>> log/install_db.log
        echo "Aires de protection de biotope" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/apb/apb.shp layers.l_zonesstatut > data/layers/sql/apb.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/apb.sql &>> log/install_db.log
        echo "...Réserves de biosphère"
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Réserves de biosphère" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/bios/bios09_2013.shp layers.l_zonesstatut > data/layers/sql/bios.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/bios.sql &>> log/install_db.log
        echo "...Sites du Conservatoire du Littoral..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Sites du Conservatoire du Littoral" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/cdl/cdl2013.shp layers.l_zonesstatut > data/layers/sql/cdl.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/cdl.sql &>> log/install_db.log
        echo "Sites acquis des Conservatoires d'espaces naturels..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Sites acquis des Conservatoires d'espaces naturels" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/cen/cen2013_09.shp layers.l_zonesstatut > data/layers/sql/cen.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/cen.sql &>> log/install_db.log
        echo "...Parcs nationaux..."echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Parcs nationaux" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/pn/pn.shp layers.l_zonesstatut > data/layers/sql/pn.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/pn.sql &>> log/install_db.log
        echo "...Parcs naturels marins..."echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Parcs naturels marins" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/pnm/pnm2014_07.shp layers.l_zonesstatut > data/layers/sql/pnm.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/pnm.sql &>> log/install_db.log
        echo "...Parcs naturels régionaux..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Parcs naturels régionaux" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "UTF8"  data/layers/pnr/pnr2014_10.shp layers.l_zonesstatut > data/layers/sql/pnr.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/pnr.sql &>> log/install_db.log
        echo "...Sites Ramsar..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Sites Ramsar" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/ramsar/ramsar2013.shp layers.l_zonesstatut > data/layers/sql/ramsar.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/ramsar.sql &>> log/install_db.log
        echo "...Réserves biologiques..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Réserves biologiques" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/rb/rb.shp layers.l_zonesstatut > data/layers/sql/rb.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/rb.sql &>> log/install_db.log
        echo "...Réserves intégrales de parc national..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Réserves intégrales de parc national" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/ripn/ripn.shp layers.l_zonesstatut > data/layers/sql/ripn.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/ripn.sql &>> log/install_db.log
        echo "...Réserves naturelles de Corse..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Réserves naturelles de Corse" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/rnc/rnc2010.shp layers.l_zonesstatut > data/layers/sql/rnc.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/rnc.sql &>> log/install_db.log
        echo "...Réserves naturelles de chasse et de faune sauvage..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Réserves naturelles de chasse et de faune sauvage" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/rncfs/rncfs_2010.shp layers.l_zonesstatut > data/layers/sql/rncfs.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/rncfs.sql &>> log/install_db.log
        echo "...Réserves naturelles nationales..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Réserves naturelles nationales" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "UTF8"  data/layers/rnn/rnn.shp layers.l_zonesstatut > data/layers/sql/rnn.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/rnn.sql &>> log/install_db.log
        echo "...Réserves naturelles régionales..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Réserves naturelles régionales" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/rnr/rnr.shp layers.l_zonesstatut > data/layers/sql/rnr.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/rnr.sql &>> log/install_db.log
        echo "...Natura 2000 Sites d'importance communautaire..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Natura 2000 Sites d'importance communautaire" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/sic/sic1409.shp layers.l_zonesstatut > data/layers/sql/sic.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/sic.sql &>> log/install_db.log
        echo "...Natura 2000 Zones de protection spéciales..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Natura 2000 Zones de protection spéciales" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/zps/zps1409.shp layers.l_zonesstatut > data/layers/sql/zps.sql
        echo "...Zone d'importance pour la conservation des oiseaux..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Zone d'importance pour la conservation des oiseaux" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/zico/zico.shp layers.l_zonesstatut > data/layers/sql/zico.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/zico.sql &>> log/install_db.log
        echo "...ZNIEFF 1 continentales..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "ZNIEFF 1 continentales" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/znieff1/znieff1.shp layers.l_zonesstatut > data/layers/sql/znieff1.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/znieff1.sql &>> log/install_db.log
        echo "...ZNIEFF 2 continentales..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "ZNIEFF 2 continentales" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/znieff2/znieff2.shp layers.l_zonesstatut > data/layers/sql/znieff2.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/znieff2.sql &>> log/install_db.log
        echo "...ZNIEFF 1 mer..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "ZNIEFF 1 mer" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/znieff1_mer/znieff1_mer.shp layers.l_zonesstatut > data/layers/sql/znieff1_mer.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/znieff1_mer.sql &>> log/install_db.log
        echo "...ZNIEFF 2 mer..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "ZNIEFF 2 mer" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s shp2pgsql -t 2D -s $srid_local -a -g the_geom -W "LATIN1"  data/layers/znieff2_mer/znieff2_mer.shp layers.l_zonesstatut > data/layers/sql/znieff2_mer.sql
        export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -f data/layers/sql/znieff2_mer.sql &>> log/install_db.log
        #export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name  -f data/layers/zonesstatut.sql &>> log/install_db.log
    fi

    if $add_sample_data
    then
        echo "Insertion d'un jeu de données test dans les schémas contactfaune et contactinv de la base..."
        echo "" &>> log/install_db.log
        echo "" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "Insertion d'un jeu de données test dans les schémas contactfaune et contactinv de la base" &>> log/install_db.log
        echo "--------------------" &>> log/install_db.log
        echo "" &>> log/install_db.log
        sudo -n -u postgres -s psql -d $db_name -f data/core/data_set_synthese.sql  &>> log/install_db.log
    fi

    # suppression des fichiers : on ne conserve que les fichiers compressés
    echo "nettoyage..."
    rm /tmp/*.txt
    rm /tmp/*.csv
    rm data/utilisateurs/usershub.sql
    rm data/taxonomie/taxhubdb.sql
    rm data/taxonomie/vm_hierarchie_taxo.sql
    rm data/taxonomie/taxhubdata.sql
    rm data/taxonomie/taxhubdata_taxon_example.sql
    rm data/taxonomie/inpn/*.zip
    rm data/taxonomie/inpn/data_inpn_v9_taxhub.sql
    # rm data/layers/zonesstatut.sql
    if $install_sig_layers
    then
        rm data/layers/communes_metropole.sql
        rm -R data/layers/apb
        rm -R data/layers/bios
        rm -R data/layers/cdl
        rm -R data/layers/cen
        rm -R data/layers/pn
        rm -R data/layers/pnr
        rm -R data/layers/pnm
        rm -R data/layers/ramsar
        rm -R data/layers/rb
        rm -R data/layers/ripn
        rm -R data/layers/rnc
        rm -R data/layers/rncfs
        rm -R data/layers/rnn
        rm -R data/layers/rnr
        rm -R data/layers/sic
        rm -R data/layers/zps
        rm -R data/layers/zico
        rm -R data/layers/znieff1
        rm -R data/layers/znieff2
        rm -R data/layers/znieff1_mer
        rm -R data/layers/znieff2_mer
        rm -R data/layers/sql
    fi
fi